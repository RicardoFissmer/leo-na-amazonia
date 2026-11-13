"""Gera a folha de sprites do Léo (16x24 por quadro) e o retrato grande usado no vídeo.

Uso (na pasta do projeto):  py tools/gerar_leo.py
Saída: assets/leo.png (todos os quadros em uma linha) e tools/preview/leo_quadros.png (ampliado).

Os quadros, na ordem da folha:
  0-1   parado (respirando)       2   parado piscando
  3-8   correndo (6 quadros)      9   pulando (subindo)
  10    caindo                    11  machucado
  12    comemorando (braços para cima)
"""
import os

from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LW, LH = 16, 24

PALETA = {
    "o": "#2a150a",  # contorno
    "h": "#1a0f08", "H": "#352013", "g": "#5c3a22",  # cabelo
    "d": "#8a4f24", "s": "#b8743e", "S": "#d9955a", "L": "#ecb07a",  # pele
    "w": "#f6f2ea", "e": "#120c0a", "m": "#7a2618", "r": "#c0503a",  # olho, boca, língua
    "y": "#ffd21f", "Y": "#fff27a", "k": "#d09400",  # camisa
    "v": "#1f9d3a", "b": "#1e4fbf",  # gola e escudo
    "n": "#1f8f3a", "N": "#47c25c", "q": "#12622a",  # short
    "B": "#1e4fbf", "C": "#4a88f0", "W": "#e8eef8", "X": "#163a8a",  # tênis
}

# Cabeça em 3/4 olhando para a direita (11x13): cabelo alto e cacheado, laterais curtas.
# Linha 6 = sobrancelhas, 7-8 = olhos, 10 = boca.
CABECA = [
    "...o.o.o...",
    "..ohohgho..",
    ".ohHgHHgHo.",
    "ohHHHgHHHgo",
    "ohHHHHHHHHo",
    "osSSSSSSShHo"[:11],
    "osSShhShhSo",
    "osssweSSweo",
    "osdswesSweo",
    "odssSSSSSSo",
    ".odssSmmSo.",
    "..oddsssSo.",
    "...ooooo...",
]
# variações do rosto: troca as linhas 6 a 10
ROSTOS = {
    "normal": None,
    "piscar": ["osSShhShhSo", "osssSSSSSSo", "osdseeSseeo", "odssSSSSSSo", ".odssSmmSo."],
    "feliz": ["osShhSShhSo", "ossseeSseeo", "osdsSSSSSSo", "odssSSSSSSo", ".odssmrrmo."],
    "dor": ["osShhShhSSo", "osssehSehSo", "osdshesShSo", "odssSSSSSSo", ".odssmmmSo."],
    "falando": ["osSShhShhSo", "osssweSSweo", "osdswesSweo", "odssSSSSSSo", ".odssmrmSo."],
}

TRONCO = [
    "..ovvvvo",
    ".oyyvvyyo",
    ".oYyyybko",
    ".oYyyyyko",
    ".okkkkkko",
    ".onnnnnqo",
    ".oNnnqnqo",
]


def cor(c):
    h = PALETA[c].lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


class Quadro:
    def __init__(self):
        self.px = {}

    def put(self, x, y, c, sobre=True):
        if 0 <= x < LW and 0 <= y < LH and (sobre or (x, y) not in self.px):
            self.px[(x, y)] = c

    def grade(self, linhas, x0, y0):
        for j, linha in enumerate(linhas):
            for i, c in enumerate(linha):
                if c != ".":
                    self.put(x0 + i, y0 + j, c)

    def linha(self, x0, y0, x1, y1, c, largura=2):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for k in range(n + 1):
            x = round(x0 + (x1 - x0) * k / n)
            y = round(y0 + (y1 - y0) * k / n)
            for dx in range(largura):
                self.put(x + dx, y, c)

    def contorno(self):
        borda = set()
        for (x, y), c in self.px.items():
            for vx, vy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                v = (x + vx, y + vy)
                if v not in self.px:
                    borda.add(v)
        for (x, y) in borda:
            self.put(x, y, "o", sobre=False)

    def imagem(self):
        img = Image.new("RGBA", (LW, LH), (0, 0, 0, 0))
        for (x, y), c in self.px.items():
            img.putpixel((x, y), cor(c))
        return img


def perna(q, quadril_x, quadril_y, pe_dx, levanta, frente):
    """Perna de 2 px do quadril até o pé, com o tênis (4x2) apontando para a direita."""
    pele = "s" if frente else "d"
    pe_x = quadril_x + pe_dx
    pe_y = 21 - levanta
    q.linha(quadril_x, quadril_y, pe_x, pe_y, pele)
    corpo, ponta, sola = ("B", "C", "W") if frente else ("X", "B", "C")
    for i in range(4):
        q.put(pe_x - 1 + i, pe_y + 1, ponta if i == 3 else corpo)
        q.put(pe_x - 1 + i, pe_y + 2, sola)


def braco(q, ombro_x, ombro_y, mao_dx, mao_dy, frente):
    """Braço com manga amarela, antebraço de pele e mão 2x2."""
    mx, my = ombro_x + mao_dx, ombro_y + mao_dy
    pele, luz = ("s", "S") if frente else ("d", "s")
    meio_x, meio_y = ombro_x + round(mao_dx * 0.35), ombro_y + round(mao_dy * 0.35)
    q.linha(meio_x, meio_y, mx, my, pele)
    q.linha(ombro_x, ombro_y, meio_x, meio_y, "y" if frente else "k")
    q.put(mx, my, luz); q.put(mx + 1, my, pele); q.put(mx, my + 1, pele); q.put(mx + 1, my + 1, pele)


def quadro(rosto="normal", bob=0, pernas=((0, 0), (0, 0)), bracos=((0, 4), (0, 4)),
           cabeca_dx=0, cabeca_dy=0):
    """pernas = ((dx do pé da frente, quanto levanta), (dx do pé de trás, quanto levanta))
    bracos = ((dx, dy) da mão da frente, (dx, dy) da mão de trás) a partir do ombro."""
    q = Quadro()
    (fdx, flev), (tdx, tlev) = pernas
    (bfx, bfy), (btx, bty) = bracos
    # coisas de trás primeiro
    braco(q, 3, 13 + bob, btx, bty, frente=False)
    perna(q, 6, 18 + bob, tdx, tlev, frente=False)
    q.grade(TRONCO, 3, 12 + bob)
    perna(q, 9, 18 + bob, fdx, flev, frente=True)
    cabeca = list(CABECA)
    if ROSTOS[rosto]:
        cabeca[6:11] = ROSTOS[rosto]
    q.grade(cabeca, 3 + cabeca_dx, bob + cabeca_dy)
    braco(q, 11, 13 + bob, bfx, bfy, frente=True)
    q.contorno()
    return q.imagem()


QUADROS = [
    # parado: respirando (o corpo desce 1 px) e piscando
    quadro(),
    quadro(bob=1, bracos=((0, 3), (0, 3))),
    quadro(rosto="piscar"),
    # corrida: contato, descida, passagem, contato, descida, passagem
    quadro(bob=0, pernas=((3, 0), (-3, 0)), bracos=((-2, 3), (3, 3)), cabeca_dx=1),
    quadro(bob=1, pernas=((2, 0), (-2, 1)), bracos=((-1, 4), (2, 4)), cabeca_dx=1),
    quadro(bob=0, pernas=((0, 1), (1, 0)), bracos=((1, 4), (0, 4)), cabeca_dx=1),
    quadro(bob=0, pernas=((-3, 0), (3, 0)), bracos=((3, 3), (-2, 3)), cabeca_dx=1),
    quadro(bob=1, pernas=((-2, 1), (2, 0)), bracos=((2, 4), (-1, 4)), cabeca_dx=1),
    quadro(bob=0, pernas=((1, 0), (0, 1)), bracos=((0, 4), (1, 4)), cabeca_dx=1),
    # pulando: joelho da frente para cima, braço da frente para cima
    quadro(rosto="feliz", pernas=((3, 2), (-2, 0)), bracos=((2, -6), (-3, 1))),
    # caindo: pernas soltas, braços abertos para cima
    quadro(pernas=((2, 0), (-2, 1)), bracos=((3, -4), (-3, -4))),
    # machucado: cabeça para trás, braços para os lados
    quadro(rosto="dor", pernas=((-2, 0), (2, 1)), bracos=((3, -2), (-3, -1)), cabeca_dx=-1),
    # comemorando
    quadro(rosto="feliz", bob=0, bracos=((1, -7), (-1, -7))),
]


def salvar():
    folha = Image.new("RGBA", (LW * len(QUADROS), LH), (0, 0, 0, 0))
    for i, img in enumerate(QUADROS):
        folha.alpha_composite(img, (i * LW, 0))
    folha.save(os.path.join(RAIZ, "assets", "leo.png"))
    # prévia ampliada com fundo de mata
    esc = 8
    prev = Image.new("RGBA", (folha.width * esc + (len(QUADROS) - 1) * 16, LH * esc), (60, 120, 90, 255))
    for i, img in enumerate(QUADROS):
        prev.alpha_composite(img.resize((LW * esc, LH * esc), Image.NEAREST), (i * (LW * esc + 16), 0))
    os.makedirs(os.path.join(RAIZ, "tools", "preview"), exist_ok=True)
    prev.save(os.path.join(RAIZ, "tools", "preview", "leo_quadros.png"))
    print("ok", len(QUADROS), "quadros")


if __name__ == "__main__":
    salvar()
