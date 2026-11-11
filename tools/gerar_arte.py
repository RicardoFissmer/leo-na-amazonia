"""Gera a arte em pixel art dos animais (tela de montar a palavra) e dos inimigos novos.

Uso (na pasta do projeto):  py tools/gerar_arte.py
Precisa do Pillow:          py -m pip install pillow

Cada animal é montado com formas simples (elipses, polígonos e "tubos") que recebem
sombreamento com luz vindo de cima/esquerda e contorno escuro automático.
A pasta tools/ tem um arquivo .gdignore, então o Godot não importa nada daqui.
"""
import math
import os
from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 96, 72

LUZ = (-0.5, -0.7, 0.55)
_n = math.sqrt(sum(c * c for c in LUZ))
LUZ = tuple(c / _n for c in LUZ)

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def cor(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def rampa(*hexes):
    return [cor(h) for h in hexes]


def escurecer(c, f):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), 255)


def misturar(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def _tom(r, t, x, y, dither=0.10):
    t += (BAYER[y % 4][x % 4] / 16.0 - 0.5) * dither
    i = int(max(0.0, min(0.999, t)) * len(r))
    return r[i]


# ----------------------------------------------------------------- formas
# Cada forma devolve um dicionário {(x, y): cor}.

def elipse(cx, cy, rx, ry, r, rot=0.0, faixas=None, dither=0.10, brilho=0.0):
    """Elipse sombreada como se fosse uma esfera.
    faixas: lista [(limite, rampa)] ao longo do eixo maior (-1..1) para pintar listras."""
    px = {}
    c, s = math.cos(-rot), math.sin(-rot)
    m = int(max(rx, ry)) + 2
    for y in range(int(cy) - m, int(cy) + m + 1):
        for x in range(int(cx) - m, int(cx) + m + 1):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            ux, uy = dx * c - dy * s, dx * s + dy * c
            nx, ny = ux / rx, uy / ry
            d = nx * nx + ny * ny
            if d > 1.0:
                continue
            nz = math.sqrt(1.0 - d)
            # normal de volta para o espaço da tela
            wx, wy = nx * math.cos(rot) - ny * math.sin(rot), nx * math.sin(rot) + ny * math.cos(rot)
            i = wx * LUZ[0] + wy * LUZ[1] + nz * LUZ[2]
            rr = r
            if faixas:
                for limite, rf in faixas:
                    if ny <= limite:
                        rr = rf
                        break
            px[(x, y)] = _tom(rr, (i + 0.25) / 1.2 + brilho, x, y, dither)
    return px


def poligono(pontos, r, direcao=(0.0, 1.0), dither=0.10, inverter=False):
    """Polígono com degradê: mais claro do lado de onde vem a luz."""
    mask = Image.new("L", (W * 2, H * 2), 0)
    ImageDraw.Draw(mask).polygon([(x, y) for x, y in pontos], fill=255)
    pts = [(x, y) for y in range(H * 2) for x in range(W * 2) if mask.getpixel((x, y))]
    if not pts:
        return {}
    dx, dy = direcao
    proj = [x * dx + y * dy for x, y in pts]
    lo, hi = min(proj), max(proj)
    px = {}
    for (x, y), p in zip(pts, proj):
        t = (p - lo) / (hi - lo + 1e-6)
        if not inverter:
            t = 1.0 - t
        px[(x, y)] = _tom(r, t, x, y, dither)
    return px


def tubo(caminho, raios, r, passos=40):
    """Uma 'mangueira' (cauda, pescoço) seguindo pontos de uma curva de Bezier."""
    px = {}
    n = len(caminho) - 1
    for k in range(passos + 1):
        t = k / passos
        # Bezier genérica (de Casteljau)
        pts = list(caminho)
        while len(pts) > 1:
            pts = [(pts[i][0] + (pts[i + 1][0] - pts[i][0]) * t,
                    pts[i][1] + (pts[i + 1][1] - pts[i][1]) * t) for i in range(len(pts) - 1)]
        raio = raios[0] + (raios[1] - raios[0]) * t
        px.update(elipse(pts[0][0], pts[0][1], raio, raio, r))
    return px


def retangulo(x0, y0, x1, y1, r, direcao=(0.0, 1.0)):
    return poligono([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], r, direcao)


def recortar(px, outra):
    """Mantém só os pixels de px que também estão em `outra`."""
    return {k: v for k, v in px.items() if k in outra}


# ----------------------------------------------------------------- tela

class Tela:
    def __init__(self, w=W, h=H):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    def ok(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def get(self, x, y):
        return self.img.getpixel((x, y)) if self.ok(x, y) else (0, 0, 0, 0)

    def put(self, x, y, c):
        if self.ok(x, y):
            self.img.putpixel((x, y), c)

    def pintar(self, px, contorno=True, cor_contorno=None):
        """Desenha a forma. O contorno é feito com a cor mais escura da própria forma,
        e passa por cima do que estiver atrás (separa as partes do corpo)."""
        if contorno:
            escura = cor_contorno or escurecer(min(px.values(), key=lambda c: sum(c[:3])), 0.45)
            borda = set()
            for (x, y) in px:
                for vx, vy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    v = (x + vx, y + vy)
                    if v not in px:
                        borda.add(v)
            for (x, y) in borda:
                self.put(x, y, escura)
        for (x, y), c in px.items():
            self.put(x, y, c)

    def ponto(self, x, y, c):
        self.put(x, y, cor(c) if isinstance(c, str) else c)

    def linha(self, pontos, c):
        c = cor(c) if isinstance(c, str) else c
        for (x0, y0), (x1, y1) in zip(pontos, pontos[1:]):
            n = max(abs(x1 - x0), abs(y1 - y0), 1)
            for k in range(n + 1):
                self.put(round(x0 + (x1 - x0) * k / n), round(y0 + (y1 - y0) * k / n), c)

    def colar(self, outra, x=0, y=0):
        self.img.alpha_composite(outra.img, (x, y))

    def salvar(self, caminho):
        caminho = os.path.join(RAIZ, caminho)
        self.img.save(caminho)
        print("ok", caminho)


# ----------------------------------------------------------------- cenários

CEU = rampa("#9fd4b0", "#b5e0c2", "#cdeedb", "#e2f7ea")
MATA_LONGE = rampa("#4f8f68", "#5f9f76", "#73b286")
MATA_PERTO = rampa("#2c6a45", "#3a7d52", "#4c9161", "#62a672")
GALHO = rampa("#3f2512", "#5e3a1e", "#7d5229", "#9c6b36")
FOLHA = rampa("#1f5a31", "#2f7a3f", "#43984c", "#66b85c")
GRAMA = rampa("#2a6b2e", "#3a8a3a", "#55a845", "#7cc45a")
TERRA = rampa("#4f2f16", "#6e441f", "#8a5a2b")
AGUA = rampa("#1b5a74", "#23708f", "#2d86a8", "#4ea3c2")


def ceu(t, alto=H):
    for y in range(alto):
        for x in range(W):
            t.put(x, y, _tom(CEU, 1.0 - y / alto, x, y, 0.25))


def mata(t, base, alturas, r, semente=1):
    """Silhuetas de copas de árvores (círculos lado a lado)."""
    import random
    rnd = random.Random(semente)
    x = -6
    while x < W + 6:
        raio = rnd.randint(*alturas)
        t.pintar(elipse(x, base, raio, raio * 0.9, r, dither=0.2), contorno=False)
        x += raio + rnd.randint(2, 6)
    for y in range(base, H):
        for xx in range(W):
            t.put(xx, y, r[0])


def folhas(t, pontos, semente=3):
    import random
    rnd = random.Random(semente)
    for (x, y) in pontos:
        ang = rnd.uniform(-0.8, 0.8)
        t.pintar(elipse(x, y, 5, 2.2, FOLHA, rot=ang), contorno=True)


def galho(t, y0, y1, grossura=6):
    t.pintar(poligono([(-2, y0), (W + 2, y1), (W + 2, y1 + grossura), (-2, y0 + grossura)], GALHO))
    # textura de casca
    for x in range(2, W, 7):
        y = y0 + (y1 - y0) * x / W
        t.linha([(x, int(y + 2)), (x + 3, int(y + 3))], GALHO[0])


def chao_grama(t, y0):
    for y in range(y0, H):
        for x in range(W):
            t.put(x, y, _tom(TERRA if y > y0 + 6 else GRAMA, 1.0 - (y - y0) / 8, x, y, 0.3))
    import random
    rnd = random.Random(7)
    for x in range(0, W, 2):
        h = rnd.randint(1, 4)
        t.linha([(x, y0), (x + rnd.choice((-1, 0, 1)), y0 - h)], GRAMA[rnd.randint(1, 3)])


def agua(t, y0, y1=H):
    for y in range(y0, y1):
        for x in range(W):
            t.put(x, y, _tom(AGUA, 1.0 - (y - y0) / max(1, y1 - y0) * 1.1, x, y, 0.2))
    import random
    rnd = random.Random(11)
    for k in range(14):
        x = rnd.randint(0, W - 8)
        y = rnd.randint(y0 + 2, y1 - 2)
        t.linha([(x, y), (x + rnd.randint(3, 7), y)], AGUA[3])


def moldura(t):
    # borda levemente mais escura para separar a imagem da moldura do jogo
    for y in range(H):
        for x in range(W):
            if x in (0, W - 1) or y in (0, H - 1):
                t.put(x, y, escurecer(t.get(x, y), 0.8))


# ----------------------------------------------------------------- animais

VERMELHO = rampa("#6e0f1c", "#a8162a", "#d9263a", "#ff5a4f")
AMARELO = rampa("#a8740a", "#e0a514", "#ffd02a", "#fff07a")
VERDE_ARARA = rampa("#1d5e2c", "#2c8a3a", "#45b14b", "#7fd66a")
AZUL = rampa("#14306e", "#1f4fa8", "#2f74d9", "#62a6ff")
MARFIM = rampa("#7e7262", "#bdb09a", "#e6dcc6", "#fffaf0")
CINZA_ESC = rampa("#141418", "#24242c", "#383844", "#50505e")
BRANCO = rampa("#b9b2a2", "#ded8c8", "#f4f0e6", "#ffffff")


def arara(fundo=True):
    """fundo=False devolve só o animal, sem cenário (usado na capa)."""
    t = Tela()
    ceu(t)
    mata(t, 26, (8, 13), MATA_LONGE, 2)
    mata(t, 46, (6, 10), MATA_PERTO, 5)
    folhas(t, [(6, 8), (14, 4), (88, 6), (80, 12), (92, 30)])
    galho(t, 58, 52)
    folhas(t, [(10, 60), (84, 52), (90, 57)], 9)

    a = Tela()
    # cauda longa: vermelha que termina em azul
    cauda = poligono([(37, 42), (46, 48), (26, 72), (17, 72)], VERMELHO, (1, 0))
    for (x, y) in list(cauda):
        if y > 62:
            cauda[(x, y)] = _tom(AZUL, 1.0 - (x - 17) / 20, x, y)
    a.pintar(cauda)
    a.linha([(41, 46), (23, 71)], VERMELHO[0])
    # corpo
    corpo = elipse(50, 36, 10.5, 17, VERMELHO, rot=-0.35)
    a.pintar(corpo)
    # asa com faixas amarela / verde / azul
    asa = elipse(45, 39, 8, 15, VERMELHO, rot=-0.42,
                 faixas=[(-0.45, AMARELO), (-0.05, VERDE_ARARA), (2.0, AZUL)])
    a.pintar(asa)
    for k, (x0, y0) in enumerate([(40, 40), (42, 44), (44, 48)]):
        a.linha([(x0, y0), (x0 + 6, y0 - 3)], AZUL[0] if k else VERDE_ARARA[0])
    # cabeça
    a.pintar(elipse(57, 19, 9, 8, VERMELHO))
    # bico de cima (gancho marfim) e de baixo (escuro)
    a.pintar(poligono([(64, 22), (66, 26), (70, 29), (68, 25), (65, 22)], CINZA_ESC))
    a.pintar(poligono([(64, 12), (70, 12), (75, 16), (76, 22), (74, 28), (72, 24), (68, 22), (64, 21)],
                      MARFIM, (0.4, 1)))
    a.linha([(66, 21), (71, 22)], MARFIM[0])
    # máscara branca do rosto com riscos
    rosto = elipse(61, 20, 4.5, 4, BRANCO, dither=0)
    a.pintar(rosto, contorno=False)
    for x, y in [(59, 22), (60, 23), (62, 23)]:
        a.ponto(x, y, "#d98a8a")
    # olho
    a.ponto(60, 18, "#f2e6b0"); a.ponto(61, 18, "#f2e6b0")
    a.ponto(60, 19, "#f2e6b0"); a.ponto(61, 19, "#151515")
    a.ponto(60, 17, "#ffffff")
    # pés no galho
    for x in (49, 54):
        a.pintar(elipse(x, 53, 2.2, 1.6, CINZA_ESC))
    if not fundo:
        return a
    t.colar(a)
    moldura(t)
    return t


PRETO = rampa("#09090d", "#16161e", "#262633", "#3c3c52")
LARANJA = rampa("#a8400a", "#e06a0e", "#ff951c", "#ffc24a")


def tucano(fundo=True):
    """fundo=False devolve só o animal, sem cenário (usado na capa)."""
    t = Tela()
    ceu(t)
    mata(t, 28, (8, 14), MATA_LONGE, 4)
    mata(t, 48, (5, 9), MATA_PERTO, 8)
    folhas(t, [(4, 10), (12, 6), (90, 40), (86, 46)])
    galho(t, 56, 60)
    folhas(t, [(6, 58), (70, 58)], 12)

    a = Tela()
    a.pintar(poligono([(34, 44), (42, 50), (36, 72), (26, 72)], PRETO, (1, 0)))
    a.pintar(elipse(42, 37, 12, 17, PRETO, rot=-0.18))
    # peito branco-amarelado
    peito = elipse(50, 30, 7, 9, rampa("#c2ad6e", "#eadba4", "#fff5cc", "#ffffff"), rot=-0.2)
    a.pintar(peito)
    # penas vermelhas embaixo da cauda
    a.pintar(elipse(43, 52, 4, 2.5, VERMELHO))
    # asa
    a.pintar(elipse(39, 39, 7, 13, PRETO, rot=-0.25, brilho=-0.1))
    a.linha([(36, 44), (40, 50)], PRETO[2])
    # cabeça
    a.pintar(elipse(50, 18, 9, 8, PRETO))
    # bico enorme
    bico = poligono([(56, 11), (66, 8), (80, 9), (90, 13), (95, 19), (92, 22), (80, 22), (66, 24), (57, 24)],
                    LARANJA, (0.2, 1))
    for (x, y) in list(bico):
        if x >= 88 or (x - 88) > (y - 22) * 2:
            bico[(x, y)] = _tom(PRETO, 0.6, x, y)
        elif x <= 58:
            bico[(x, y)] = _tom(PRETO, 0.5, x, y)
    a.pintar(bico)
    a.linha([(59, 19), (72, 19), (88, 18)], "#c4350a")
    a.linha([(66, 10), (80, 11)], LARANJA[3])
    # olho: pele laranja, anel azul, pupila
    a.pintar(elipse(53, 17, 3.2, 2.8, LARANJA, dither=0), contorno=False)
    a.ponto(53, 16, "#2f8fe8"); a.ponto(54, 16, "#2f8fe8"); a.ponto(53, 17, "#2f8fe8")
    a.ponto(54, 17, "#0b0b0b"); a.ponto(53, 16, "#ffffff")
    for x in (45, 49):
        a.pintar(elipse(x, 55, 2, 1.5, rampa("#1e3f80", "#3462b8", "#5b8ce0")))
    if not fundo:
        return a
    t.colar(a)
    moldura(t)
    return t


OURO = rampa("#844a10", "#c2761c", "#e8a038", "#f8c86e")
CREME = rampa("#b99a70", "#dcc49c", "#f4e6c8", "#fff6e4")
ROSETA = cor("#2e1a06")


def onca(fundo=True):
    """fundo=False devolve só o animal, sem cenário (usado na capa)."""
    t = Tela()
    ceu(t)
    mata(t, 24, (8, 13), MATA_LONGE, 6)
    mata(t, 42, (6, 11), MATA_PERTO, 3)
    chao_grama(t, 60)

    a = Tela()
    # cauda curvando para cima
    cauda = tubo([(24, 38), (12, 46), (6, 40), (8, 30)], (3.0, 2.2), OURO)
    a.pintar(cauda)
    for (x, y) in [(15, 44), (9, 43), (6, 37), (7, 32)]:
        a.ponto(x, y, ROSETA); a.ponto(x + 1, y, ROSETA)
    a.pintar(elipse(8, 30.5, 2.0, 2.2, rampa("#1c1006", "#2e1a06", "#4a2c10")))
    # pernas de trás (a de longe mais escura)
    perna_longe = rampa("#6a3a0c", "#9a5e16", "#bb7f2a")
    a.pintar(tubo([(32, 42), (34, 52), (32, 59)], (5.0, 2.6), perna_longe))
    a.pintar(elipse(33, 59.5, 3.6, 1.8, perna_longe))
    a.pintar(tubo([(57, 44), (58, 52), (58, 59)], (3.6, 2.6), perna_longe))
    a.pintar(elipse(59, 59.5, 3.6, 1.8, perna_longe))
    # corpo
    corpo = elipse(42, 40, 21, 11, OURO)
    barriga = recortar(elipse(44, 48, 17, 6, CREME), corpo)
    a.pintar(corpo)
    a.pintar(barriga, contorno=False)
    # rosetas: anéis escuros com miolo mais escuro
    for (x, y) in [(28, 35), (35, 32), (43, 31), (51, 33), (31, 41), (39, 38), (47, 38), (55, 40),
                   (25, 42), (36, 45), (52, 45)]:
        if (x, y) not in corpo or (x, y) in barriga:
            continue
        for vx, vy in [(-1, -1), (0, -2), (1, -1), (2, 0), (1, 1), (0, 2), (-1, 1), (-2, 0)]:
            if (x + vx, y + vy) in corpo:
                a.ponto(x + vx, y + vy, ROSETA)
        a.ponto(x, y, OURO[0])
        a.ponto(x, y - 1, OURO[0])
    # pernas da frente (perto)
    # coxa de trás + pernas da perto
    a.pintar(elipse(27, 42, 8, 9, OURO, rot=0.3))
    a.pintar(tubo([(27, 47), (24, 54), (26, 59)], (4.0, 2.8), OURO))
    a.pintar(tubo([(52, 44), (51, 52), (52, 59)], (4.2, 3.0), OURO))
    for x0 in (27, 53):
        a.pintar(elipse(x0, 60, 4.2, 2.0, CREME))
    for (x, y) in [(28, 40), (25, 44), (51, 50), (53, 47), (24, 52)]:
        a.ponto(x, y, ROSETA)
    # cabeça
    cabeca = elipse(67, 29, 10, 9, OURO)
    a.pintar(elipse(61, 21, 2.6, 2.4, OURO))
    a.pintar(elipse(69, 20, 2.6, 2.4, OURO))
    a.ponto(61, 21, "#2e1a06"); a.ponto(69, 20, "#2e1a06")
    a.pintar(cabeca)
    a.pintar(elipse(73, 34, 6, 4.5, CREME), contorno=False)
    a.pintar(elipse(77, 31, 2, 1.4, rampa("#5c2a2a", "#8e4446", "#b8646a")), contorno=False)
    a.linha([(77, 33), (77, 35), (74, 36)], "#5a2a18")
    # olho verde-amarelado
    a.ponto(70, 26, "#c8d84a"); a.ponto(71, 26, "#c8d84a"); a.ponto(71, 27, "#111111")
    a.ponto(70, 27, "#9cae2a"); a.ponto(69, 25, ROSETA); a.ponto(70, 25, ROSETA)
    # pintinhas na cabeça
    for (x, y) in [(62, 26), (64, 23), (66, 31), (63, 30), (60, 28)]:
        a.ponto(x, y, ROSETA)
    if not fundo:
        return a
    t.colar(a)
    moldura(t)
    return t


ROSA = rampa("#9a4566", "#cf7092", "#ef9ab4", "#ffc8d6")


def boto(fundo=True):
    """fundo=False devolve só o animal, sem cenário (usado na capa)."""
    t = Tela()
    ceu(t, 44)
    mata(t, 26, (7, 12), MATA_LONGE, 9)
    mata(t, 40, (5, 9), MATA_PERTO, 13)
    agua(t, 44)

    a = Tela()
    # nadadeiras da cauda saindo da água
    a.pintar(poligono([(26, 44), (16, 40), (19, 47), (24, 49)], ROSA, (1, -1)))
    a.pintar(poligono([(26, 46), (20, 54), (27, 52), (30, 48)], ROSA, (1, -1)))
    # corpo arqueado
    corpo = elipse(46, 33, 23, 8.5, ROSA, rot=-0.42)
    a.pintar(corpo)
    barriga = recortar(elipse(50, 39, 17, 4, rampa("#e9a8bc", "#ffd3df", "#fff0f4"), rot=-0.42), corpo)
    a.pintar(barriga, contorno=False)
    # testa arredondada (melão) e bico comprido
    a.pintar(poligono([(64, 20), (84, 9), (86, 11), (68, 26)], ROSA, (0.3, 1)))
    a.pintar(elipse(63, 23, 7, 6.5, ROSA, rot=-0.42))
    a.linha([(70, 22), (84, 11)], ROSA[0])
    a.ponto(64, 24, "#2a1420"); a.ponto(63, 23, "#ffffff")
    # nadadeira de cima e do lado
    a.pintar(poligono([(42, 26), (47, 21), (49, 27)], ROSA, (1, 1)))
    a.pintar(elipse(54, 37, 4, 2, ROSA, rot=0.6, brilho=-0.15))
    if not fundo:
        return a
    t.colar(a)
    # respingos e anel de água onde ele saiu
    for (x, y) in [(14, 36), (18, 33), (31, 40), (35, 37), (12, 42), (33, 43), (22, 38)]:
        t.ponto(x, y, "#e8f8ff")
        t.ponto(x + 1, y, "#9fd8ef")
    t.linha([(12, 46), (16, 45), (24, 45), (34, 46), (38, 47)], "#e8f8ff")
    t.linha([(8, 50), (14, 49), (36, 50), (42, 51)], "#9fd8ef")
    moldura(t)
    return t


CAPI = rampa("#3e2618", "#6a432a", "#93653f", "#b88654")
CAPI_ESC = rampa("#2c1a10", "#4a2e1c", "#6a432a")


def capivara(fundo=True):
    """fundo=False devolve só o animal, sem cenário (usado na capa)."""
    t = Tela()
    ceu(t)
    mata(t, 24, (8, 13), MATA_LONGE, 15)
    mata(t, 40, (6, 10), MATA_PERTO, 16)
    agua(t, 44, 54)
    chao_grama(t, 56)

    a = Tela()
    # pernas de trás e da frente (curtas)
    for x0 in (28, 56):
        a.pintar(tubo([(x0, 46), (x0 + 1, 54), (x0, 59)], (4.0, 3.0), CAPI_ESC))
    corpo = elipse(42, 40, 23, 14, CAPI)
    a.pintar(corpo)
    for x0 in (34, 62):
        a.pintar(tubo([(x0, 48), (x0 - 1, 55), (x0, 60)], (4.4, 3.2), CAPI))
        a.pintar(elipse(x0 + 0.5, 61, 4, 1.6, CAPI_ESC))
    # pelo: risquinhos mais escuros
    for (x, y) in corpo:
        if (x * 7 + y * 13) % 23 == 0 and y > 30:
            a.ponto(x, y, CAPI[0])
            a.ponto(x + 1, y - 1, CAPI[1])
    # cabeça quadradona
    a.pintar(elipse(64, 30, 11, 10, CAPI, rot=0.1))
    a.pintar(elipse(60, 20, 3, 2.5, CAPI_ESC))
    focinho = poligono([(66, 22), (78, 23), (82, 28), (82, 38), (76, 41), (66, 40)], CAPI, (0.6, 1))
    a.pintar(focinho)
    a.pintar(elipse(80, 28, 2.4, 2.2, rampa("#1a100a", "#2e1d14", "#4a3020")), contorno=False)
    a.linha([(81, 36), (78, 37), (75, 36)], CAPI_ESC[0])
    # olho pequeno lá no alto
    a.ponto(68, 25, "#120b07"); a.ponto(69, 25, "#120b07"); a.ponto(68, 24, "#ffffff")
    # passarinho (bem-te-vi) nas costas
    a.pintar(elipse(40, 24, 4, 3, rampa("#b48a0a", "#e8c21a", "#ffe24a")))
    a.pintar(elipse(44, 21, 2.6, 2.4, rampa("#1a1a1a", "#2a2a2a", "#3a3a3a")))
    a.ponto(44, 21, "#ffffff"); a.ponto(45, 21, "#ffffff"); a.ponto(45, 20, "#111111")
    a.ponto(47, 21, "#3a2a18")
    a.pintar(poligono([(35, 23), (38, 22), (37, 25)], rampa("#5a4a30", "#7a6646", "#9a845e")))
    if not fundo:
        return a
    t.colar(a)
    moldura(t)
    return t


# ----------------------------------------------------------------- inimigos

COBRA = rampa("#1d4d1a", "#2f7a26", "#4caa35", "#82d455")
LISTRA = rampa("#8a7a0a", "#c8b41a", "#f0dc3a")


def cobra():
    """cobra_corpo.png: pedaço do corpo (6x8) que se repete na vertical.
    cobra_cabeca.png: 2 quadros de 10x10, cabeça olhando para baixo (língua para dentro/fora)."""
    corpo = Tela(6, 8)
    px = {}
    for y in range(8):
        for x in range(1, 5):
            t = 1.0 - (x - 1) / 3.5
            px[(x, y)] = _tom(LISTRA if y in (5, 6) else COBRA, t, x, y, 0)
    corpo.pintar(px, contorno=False)
    for y in range(8):
        corpo.put(0, y, cor("#0f2a0c")); corpo.put(5, y, cor("#0f2a0c"))
    corpo.put(2, 2, COBRA[0]); corpo.put(3, 3, COBRA[0])
    corpo.salvar("assets/cobra_corpo.png")

    folha = Tela(20, 10)
    for q in range(2):
        c = Tela(10, 10)
        c.pintar(poligono([(1, 1), (9, 1), (8, 5), (6, 8), (4, 8), (2, 5)], COBRA, (1, 0.3)))
        c.put(2, 3, cor("#ffe23a")); c.put(7, 3, cor("#ffe23a"))
        c.put(2, 4, cor("#111111")); c.put(7, 4, cor("#111111"))
        c.put(4, 7, COBRA[0]); c.put(5, 7, COBRA[0])
        c.put(4, 2, LISTRA[2]); c.put(5, 2, LISTRA[1])
        if q == 1:
            c.put(5, 9, cor("#e02a3a")); c.put(4, 9, cor("#e02a3a"))
        else:
            c.put(5, 9, (0, 0, 0, 0))
        folha.colar(c, q * 10, 0)
    folha.salvar("assets/cobra_cabeca.png")


PIRANHA = rampa("#4c5866", "#76889a", "#a2b4c4", "#d2e0ea")
BARRIGA = rampa("#8e1a14", "#c92e24", "#f0503a")


def piranha():
    """piranha.png: 2 quadros de 14x11 olhando para a direita (boca fechada/aberta)."""
    folha = Tela(28, 11)
    for q in range(2):
        p = Tela(14, 11)
        p.pintar(poligono([(1, 2), (4, 5), (1, 8)], rampa("#4a5462", "#6a7888", "#8a9aaa")))
        corpo = elipse(8, 5.5, 5.5, 4.6, PIRANHA)
        p.pintar(corpo)
        p.pintar(recortar(elipse(9, 8.5, 5, 3, BARRIGA), corpo), contorno=False)
        p.pintar(poligono([(6, 1), (9, -1), (9, 2)], rampa("#3a4450", "#5a6676")))
        p.put(10, 4, cor("#ffe0a0")); p.put(11, 4, cor("#c41a1a")); p.put(10, 3, cor("#ffffff"))
        if q == 1:
            for y in (6, 7, 8):
                p.put(13, y, (0, 0, 0, 0)); p.put(12, y, cor("#3a0a0a"))
            p.put(12, 6, cor("#ffffff")); p.put(12, 8, cor("#ffffff"))
        else:
            p.put(12, 7, cor("#ffffff")); p.put(13, 7, cor("#3a0a0a"))
        folha.colar(p, q * 14, 0)
    folha.salvar("assets/piranha.png")

    # bolhas que avisam que a piranha vai pular (2 quadros 12x6)
    b = Tela(24, 6)
    for q, pts in enumerate([[(2, 4), (6, 2), (9, 4)], [(3, 2), (7, 4), (10, 1)]]):
        for (x, y) in pts:
            x += q * 12
            b.put(x, y, cor("#e8f8ff")); b.put(x + 1, y, cor("#9fd8ef"))
            b.put(x, y + 1, cor("#9fd8ef"))
    b.salvar("assets/bolhas.png")


def previa(nomes, saida, escala=4):
    imgs = [Image.open(os.path.join(RAIZ, n)).convert("RGBA") for n in nomes]
    larg = sum(i.width * escala + 8 for i in imgs)
    alt = max(i.height * escala for i in imgs)
    folha = Image.new("RGBA", (larg, alt), (40, 40, 40, 255))
    x = 0
    for i in imgs:
        g = i.resize((i.width * escala, i.height * escala), Image.NEAREST)
        folha.alpha_composite(g, (x, 0))
        x += g.width + 8
    os.makedirs(os.path.join(RAIZ, "tools/preview"), exist_ok=True)
    folha.save(os.path.join(RAIZ, "tools/preview", saida))


if __name__ == "__main__":
    for nome, f in [("arara", arara), ("tucano", tucano), ("onca", onca), ("boto", boto), ("capivara", capivara)]:
        f().salvar("assets/animais/%s.png" % nome)
    cobra()
    piranha()
    previa(["assets/animais/%s.png" % n for n in ("arara", "onca", "boto", "tucano", "capivara")], "animais.png")
    previa(["assets/cobra_corpo.png", "assets/cobra_cabeca.png", "assets/piranha.png", "assets/bolhas.png"],
           "inimigos.png", 10)
