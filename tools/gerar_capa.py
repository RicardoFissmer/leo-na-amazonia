"""Gera a capa do jogo em pixel art, no mesmo estilo dos sprites.

Uso (na pasta do projeto):  py tools/gerar_capa.py
Precisa do Pillow:          py -m pip install pillow

A capa é desenhada em 320x180 (a resolução do jogo) e ampliada sem borrar:
  capa/capa_1920x1080.png  capa principal (16:9)
  capa/capa_1280x640.png   prévia para redes sociais / GitHub (2:1)
  capa/capa_320x180.png    original, pixel por pixel
"""
import os

from PIL import Image

import gerar_arte as ga
from gerar_arte import Tela, cor, rampa, elipse, poligono, tubo

RAIZ = ga.RAIZ
LW, LH = 320, 180
CHAO = 148  # y da superfície do chão (igual ao jogo: linha 9 do mapa)


def asset(nome):
    return Image.open(os.path.join(RAIZ, "assets", nome)).convert("RGBA")


def recortado(tela):
    """Imagem só com a área desenhada (sem bordas transparentes)."""
    img = tela.img if isinstance(tela, Tela) else tela
    return img.crop(img.getbbox())


def colar(capa, img, x, y, espelhar=False):
    if espelhar:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    capa.alpha_composite(img, (int(x), int(y)))


def ladrilhar(capa, tile, x0, y0, x1, y1):
    for y in range(y0, y1, tile.height):
        for x in range(x0, x1, tile.width):
            pedaco = tile.crop((0, 0, min(tile.width, x1 - x), min(tile.height, y1 - y)))
            capa.alpha_composite(pedaco, (x, y))


# ----------------------------------------------------------------- Léo grande

PELE = rampa("#6e4020", "#9a6236", "#c68642", "#dfa565")
CABELO = rampa("#160d07", "#2a190d", "#3b2314", "#55341e")
CAMISA = rampa("#b8860b", "#e6b400", "#ffd21f", "#fff07a")
SHORT = rampa("#145c27", "#1f7d36", "#1f9d3a", "#45c25c")
TENIS = rampa("#0f2a6e", "#1e4fbf", "#3a78e8", "#7aa8ff")


def leo():
    """Léo pulando com o braço esticado para pegar uma letra (40x52)."""
    t = Tela(40, 52)
    # perna de trás esticada e perna da frente dobrada
    t.pintar(tubo([(16, 33), (12, 39), (8, 42)], (2.6, 2.0), PELE))
    t.pintar(elipse(7, 43.5, 3.6, 2.2, TENIS))
    t.pintar(tubo([(22, 33), (28, 37), (26, 43)], (2.8, 2.1), PELE))
    t.pintar(elipse(27, 45, 3.8, 2.2, TENIS))
    for x in range(24, 31):
        t.put(x, 47, cor("#e8eef8"))
    # braço de trás
    t.pintar(tubo([(14, 20), (10, 25), (8, 29)], (2.2, 1.8), PELE))
    # shorts e camisa
    t.pintar(poligono([(12, 29), (26, 29), (27, 35), (21, 36), (19, 33), (17, 36), (11, 35)], SHORT, (0.4, 1)))
    camisa = elipse(19, 24, 7.2, 7.5, CAMISA, dither=0.0)
    t.pintar(camisa)
    # escudo azul no peito e barra verde na barra da camisa (como no sprite do jogo)
    for (x, y, c) in [(19, 23, "#3a78e8"), (20, 23, "#1e4fbf"), (19, 24, "#1e4fbf"), (20, 24, "#123a9a")]:
        t.put(x, y, cor(c))
    for x in range(14, 25):
        if (x, 30) in camisa:
            t.put(x, 30, cor("#1f9d3a"))
    # braço da frente esticado para cima, com manga amarela
    t.pintar(tubo([(26, 15), (28, 11), (31, 5)], (2.2, 2.0), PELE))
    t.pintar(tubo([(23, 20), (26, 15)], (3.0, 2.6), CAMISA))
    t.pintar(elipse(31.5, 4, 2.6, 2.6, PELE))
    # cabeça
    t.pintar(elipse(17, 10, 6.6, 6.4, PELE))
    t.linha([(15, 17), (17, 19), (19, 17)], "#1f9d3a")  # gola em V
    t.pintar(elipse(11.5, 11, 1.8, 2.2, PELE))  # orelha
    # cabelo alto (como no sprite do jogo)
    cabelo = {}
    for (cx, cy, r) in [(13, 4, 3.4), (17, 2, 3.8), (21, 4, 3.2), (12, 7, 2.6), (22, 7, 2.2), (15, -1, 2.6),
                        (19, -1, 2.4)]:
        cabelo.update(elipse(cx, cy + 1, r, r, CABELO, dither=0.3))
    cabelo = {k: v for k, v in cabelo.items() if k[1] <= 7 or k[0] <= 12}
    t.pintar(cabelo)
    # rosto olhando para a letra (para cima e para a direita)
    t.put(19, 9, cor("#141414")); t.put(19, 10, cor("#141414")); t.put(20, 9, cor("#ffffff"))
    t.put(22, 9, cor("#141414")); t.put(22, 10, cor("#141414")); t.put(23, 9, cor("#ffffff"))
    t.put(18, 7, CABELO[1]); t.put(19, 7, CABELO[1]); t.put(22, 7, CABELO[1]); t.put(23, 7, CABELO[1])
    t.linha([(19, 13), (20, 14), (22, 14), (23, 13)], "#6b2a1a")
    t.put(17, 12, cor("#e09070")); t.put(24, 12, cor("#e09070"))
    return t


# ----------------------------------------------------------------- letras

# Fonte em blocos, 7x9 (I tem 6 de largura). "#" = pixel aceso.
FONTE = {
    "A": [".#####.", "#######", "##...##", "##...##", "#######", "#######", "##...##", "##...##", "##...##"],
    "E": ["#######", "#######", "##.....", "######.", "######.", "##.....", "##.....", "#######", "#######"],
    "I": ["######", "######", "..##..", "..##..", "..##..", "..##..", "..##..", "######", "######"],
    "L": ["##.....", "##.....", "##.....", "##.....", "##.....", "##.....", "##.....", "#######", "#######"],
    "M": ["##...##", "###.###", "#######", "##.#.##", "##...##", "##...##", "##...##", "##...##", "##...##"],
    "N": ["##...##", "###..##", "####.##", "#######", "##.####", "##..###", "##...##", "##...##", "##...##"],
    "O": [".#####.", "#######", "##...##", "##...##", "##...##", "##...##", "##...##", "#######", ".#####."],
    "Z": ["#######", "#######", "....###", "...###.", "..###..", ".###...", "###....", "#######", "#######"],
}
ACENTOS = {"É": ("E", ["...##..", "..##..."]), "Ô": ("O", ["..###..", ".##.##."])}
TOPO = 3  # linhas reservadas para os acentos


def mascara_texto(txt, escala, espaco=1):
    px = set()
    x = 0
    for ch in txt:
        if ch == " ":
            x += 4 * escala
            continue
        base, acento = ACENTOS.get(ch, (ch, None))
        linhas = ([None] * TOPO if not acento else acento + [None]) + FONTE[base]
        for gy, linha in enumerate(linhas):
            if linha is None:
                continue
            for gx, c in enumerate(linha):
                if c == "#":
                    for dy in range(escala):
                        for dx in range(escala):
                            px.add((x + gx * escala + dx, gy * escala + dy))
        x += (len(FONTE[base][0]) + espaco) * escala
    largura = x - espaco * escala
    return px, largura, (TOPO + 9) * escala


TITULO = rampa("#d9640a", "#f59a12", "#ffc21a", "#ffe04a", "#fff3a0")


def texto_titulo(txt, escala):
    """Texto amarelo em degradê, com brilho em cima, contorno verde-escuro e sombra."""
    px, larg, alt = mascara_texto(txt, escala)
    m = 3
    img = Image.new("RGBA", (larg + m * 2 + 2, alt + m * 2 + 3), (0, 0, 0, 0))
    px = {(x + m, y + m) for (x, y) in px}
    viz8 = [(dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
    anel1 = {(x + dx, y + dy) for (x, y) in px for dx, dy in viz8} - px
    anel2 = {(x + dx, y + dy) for (x, y) in px | anel1 for dx, dy in viz8} - px - anel1
    sombra = {(x + 1, y + 3) for (x, y) in px | anel1 | anel2}
    for (x, y) in sombra:
        img.putpixel((x, y), (4, 18, 10, 170))
    for (x, y) in anel2:
        img.putpixel((x, y), cor("#04140a"))
    for (x, y) in anel1:
        img.putpixel((x, y), cor("#0e3322"))
    topo_cap = (TOPO * escala) + m
    for (x, y) in px:
        t = 1.0 - (y - topo_cap) / (9 * escala)
        c = ga._tom(TITULO, t, x, y, 0.18)
        if (x, y - 1) not in px:
            c = cor("#fffbe0")
        img.putpixel((x, y), c)
    return img


def moeda(letra):
    """Moeda do jogo (coin.png) com a letra desenhada na fonte do título."""
    img = asset("coin.png").copy()
    g = FONTE[letra]
    x0 = (img.width - len(g[0])) // 2
    y0 = (img.height - 9) // 2
    for gy, linha in enumerate(g):
        for gx, c in enumerate(linha):
            if c == "#":
                img.putpixel((x0 + gx, y0 + gy), cor("#6b3e00"))
    return img


def brilho(capa, x, y):
    """Estrelinha de 5 pixels em volta da moeda."""
    for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
        capa.putpixel((x + dx, y + dy), cor("#fffbe0") if (dx, dy) == (0, 0) else cor("#ffe04a"))


# ----------------------------------------------------------------- cena

def galho_lateral(largura, espelhar=False):
    t = Tela(largura + 4, 14)
    t.pintar(poligono([(-2, 5), (largura, 3), (largura + 2, 6), (largura, 9), (-2, 11)], ga.GALHO))
    for x in range(4, largura - 2, 7):
        t.linha([(x, 6), (x + 3, 7)], ga.GALHO[0])
    t.pintar(elipse(largura - 10, 3, 5, 2.2, ga.FOLHA, rot=-0.5))
    t.pintar(elipse(largura - 4, 11, 4.5, 2, ga.FOLHA, rot=0.4))
    img = t.img
    return img.transpose(Image.FLIP_LEFT_RIGHT) if espelhar else img


def capa():
    c = Image.new("RGBA", (LW, LH), cor("#8fd9b0"))

    # fundo do jogo em 3 camadas (as mesmas do parallax)
    colar(c, asset("bg_far.png").crop((40, 0, 40 + LW, 180)), 0, 0)
    colar(c, asset("bg_mid.png").crop((100, 0, 100 + LW, 180)), 0, 0)
    colar(c, asset("bg_canopy.png").crop((60, 0, 60 + LW, 90)), 0, 0)

    # chão com um rio no meio-esquerda
    rio = (64, 128)
    ground, dirt, water = asset("ground.png"), asset("dirt.png"), asset("water.png")
    for (x0, x1) in [(0, rio[0]), (rio[1], LW)]:
        ladrilhar(c, ground, x0, CHAO, x1, CHAO + 16)
        ladrilhar(c, dirt, x0, CHAO + 16, x1, LH)

    # plantas no chão
    bush, heliconia = asset("bush.png"), asset("heliconia.png")
    for x in (40, 150, 196):
        colar(c, bush, x, CHAO - bush.height + 1)
    for x in (58, 134, 214, 300):
        colar(c, heliconia, x, CHAO - heliconia.height + 1)

    # galhos laterais com o tucano (esquerda) e a arara (direita, virada para o centro)
    colar(c, galho_lateral(66), -4, 78)
    tucano = recortado(ga.tucano(fundo=False))
    colar(c, tucano, 6, 83 - tucano.height + 6)
    colar(c, galho_lateral(70, espelhar=True), LW - 70, 70)
    arara = recortado(ga.arara(fundo=False))
    colar(c, arara, LW - arara.width - 4, 75 - arara.height + 6, espelhar=True)

    # boto pulando do rio (desenhado antes da água para o rabo ficar submerso)
    boto = recortado(ga.boto(fundo=False))
    colar(c, boto, rio[0] - 4, CHAO + 8 - boto.height)
    ladrilhar(c, water, rio[0], CHAO + 4, rio[1], LH)
    colar(c, asset("lily.png"), rio[0] + 34, CHAO + 3)
    for (x, y) in [(rio[0] + 6, CHAO + 1), (rio[0] + 12, CHAO - 2), (rio[0] + 3, CHAO - 4), (rio[0] + 18, CHAO),
                   (rio[1] - 16, CHAO + 1), (rio[1] - 11, CHAO - 1)]:
        c.putpixel((x, y), cor("#e8f8ff"))
        c.putpixel((x + 1, y), cor("#9fd8ef"))

    # capivara na margem esquerda, onça à direita (virada para o Léo)
    capivara = recortado(ga.capivara(fundo=False))
    colar(c, capivara, -14, CHAO + 2 - capivara.height)
    onca = recortado(ga.onca(fundo=False))
    colar(c, onca, LW - onca.width + 4, CHAO + 2 - onca.height, espelhar=True)

    # moedas com letras e o Léo pulando para pegar uma delas
    leo_img = recortado(leo())
    lx, ly = 148, 90
    sombra = Image.new("RGBA", (22, 3), (8, 40, 16, 110))
    colar(c, sombra, lx + 6, CHAO - 1)
    colar(c, leo_img, lx, ly)
    for (letra, x, y) in [("A", lx + 13, ly - 19), ("O", 110, 92), ("N", 212, 98)]:
        colar(c, moeda(letra), x, y)
    brilho(c, lx + 10, ly - 18)
    brilho(c, lx + 34, ly - 12)
    brilho(c, 131, 90)

    # título
    linha1 = texto_titulo("LÉO NA", 2)
    linha2 = texto_titulo("AMAZÔNIA", 3)
    colar(c, linha1, (LW - linha1.width) // 2, 0)
    colar(c, linha2, (LW - linha2.width) // 2, 26)
    return c


def salvar(img, nome):
    pasta = os.path.join(RAIZ, "capa")
    os.makedirs(pasta, exist_ok=True)
    open(os.path.join(pasta, ".gdignore"), "a").close()
    caminho = os.path.join(pasta, nome)
    img.save(caminho)
    print("ok", caminho)


if __name__ == "__main__":
    c = capa()
    salvar(c, "capa_320x180.png")
    salvar(c.resize((1920, 1080), Image.NEAREST), "capa_1920x1080.png")
    # 2:1 para redes sociais: corta 20 px da terra embaixo
    salvar(c.crop((0, 0, 320, 160)).resize((1280, 640), Image.NEAREST), "capa_1280x640.png")
