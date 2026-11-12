"""Gera as imagens das telas da história (começo e fim do jogo), 96x72 como as dos animais.

Uso (na pasta do projeto):  py tools/gerar_historia.py
Gera em assets/historia/: livro.png, livro_vento.png, leo_missao.png, livro_completo.png
"""
import os
import random

import gerar_arte as ga
from gerar_arte import Tela, cor, rampa, elipse, poligono
from gerar_capa import leo, recortado

CAPA_LIVRO = rampa("#16391f", "#245a30", "#337a40", "#4a9a55")
PAGINA = rampa("#c8b386", "#e4d4ac", "#f4eacd", "#fffaf0")
BORDA_PAGINA = cor("#7a6440")
TINTA = "#4a3a28"


def cenario(t, semente=21):
    ga.ceu(t)
    ga.mata(t, 30, (8, 13), ga.MATA_LONGE, semente)
    ga.mata(t, 52, (6, 10), ga.MATA_PERTO, semente + 1)


def livro(t, nomes=True, figuras=True):
    """Livro aberto no centro da imagem. As páginas têm figura de um animal e o nome embaixo."""
    t.pintar(poligono([(9, 21), (48, 26), (87, 21), (87, 63), (48, 68), (9, 63)], CAPA_LIVRO, (0.3, 1)))
    t.pintar(poligono([(12, 19), (47, 24), (47, 63), (12, 58)], PAGINA, (1, 0.4)), cor_contorno=BORDA_PAGINA)
    t.pintar(poligono([(49, 24), (84, 19), (84, 58), (49, 63)], PAGINA, (-1, 0.4)), cor_contorno=BORDA_PAGINA)
    t.linha([(48, 24), (48, 64)], "#8a7650")
    if figuras:
        # página da esquerda: arara
        t.pintar(elipse(25, 33, 4.5, 5.5, ga.VERMELHO))
        t.pintar(elipse(27.5, 30.5, 2.4, 2.4, ga.VERMELHO))
        t.ponto(28, 30, "#ffffff")
        t.ponto(30, 31, "#e6dcc6"); t.ponto(30, 32, "#e6dcc6"); t.ponto(31, 32, "#bdb09a")
        t.pintar(elipse(23.5, 35, 2.2, 3.4, ga.AZUL, rot=0.3))
        t.ponto(22, 33, "#ffd02a"); t.ponto(23, 33, "#45b14b")
        # página da direita: onça
        t.pintar(elipse(66, 32, 6, 5, ga.OURO))
        t.pintar(elipse(62, 27.5, 1.6, 1.6, ga.OURO)); t.pintar(elipse(70, 27.5, 1.6, 1.6, ga.OURO))
        t.pintar(elipse(66, 34.5, 2.6, 1.8, ga.CREME), contorno=False)
        t.ponto(64, 31, "#141414"); t.ponto(68, 31, "#141414"); t.ponto(66, 33, "#5c2a2a")
        for (x, y) in [(62, 30), (70, 30), (63, 35), (69, 35), (66, 29)]:
            t.ponto(x, y, "#2e1a06")
    # linhas de texto (só o desenho, sem letras de verdade)
    for k, y in enumerate((48, 52, 55)):
        t.linha([(16, y - 3), (16 + (26 if k else 20), y)], "#9a8a6a")
        t.linha([(53, y + 1), (53 + (26 if k else 20), y - 2)], "#9a8a6a")
    if nomes:
        # o nome do animal, em destaque, embaixo da figura
        t.linha([(17, 41), (33, 43)], TINTA); t.linha([(17, 42), (33, 44)], TINTA)
        t.linha([(57, 42), (75, 40)], TINTA); t.linha([(57, 43), (75, 41)], TINTA)


def moedinha(t, x, y):
    t.pintar(elipse(x, y, 3.2, 3.2, rampa("#9a6b00", "#e0a514", "#ffcc00", "#fff3a0"), dither=0),
             cor_contorno=cor("#6b4a00"))
    t.ponto(int(x), int(y), "#6b3e00")


def brilho(t, x, y):
    for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
        t.ponto(x + dx, y + dy, "#fffbe0" if (dx, dy) == (0, 0) else "#ffe04a")


def vento(t, y, x0, x1, amplitude=2):
    pts = []
    for x in range(x0, x1 + 1, 3):
        pts.append((x, y - int(amplitude * ((x - x0) / max(1, x1 - x0)) ** 2 * 3)))
    t.linha(pts, "#f4fff8")


def livro_normal():
    t = Tela()
    cenario(t)
    livro(t)
    return t


def livro_vento():
    t = Tela()
    cenario(t, 31)
    livro(t, nomes=False)
    rnd = random.Random(4)
    for (x, y) in [(22, 39), (36, 33), (58, 37), (70, 31), (44, 18), (60, 12), (78, 10), (88, 20), (30, 12),
                   (70, 4), (84, 34), (14, 8)]:
        moedinha(t, x + rnd.randint(-1, 1), y)
    vento(t, 16, 4, 40)
    vento(t, 9, 46, 92)
    vento(t, 30, 64, 94, 1)
    return t


def leo_missao():
    t = Tela()
    cenario(t, 41)
    ga.chao_grama(t, 62)
    for (x, y) in [(14, 18), (78, 14), (86, 30), (10, 36)]:
        moedinha(t, x, y)
    l = recortado(leo())
    t.img.alpha_composite(l, ((ga.W - l.width) // 2, 62 - l.height + 2))
    brilho(t, 70, 22)
    brilho(t, 22, 26)
    return t


def livro_completo():
    t = Tela()
    cenario(t, 51)
    livro(t)
    for (x, y) in [(6, 10), (90, 8), (20, 4), (76, 14), (4, 40), (92, 44), (48, 10), (34, 14), (62, 6)]:
        brilho(t, x, y)
    return t


if __name__ == "__main__":
    os.makedirs(os.path.join(ga.RAIZ, "assets", "historia"), exist_ok=True)
    nomes = []
    for nome, f in [("livro", livro_normal), ("livro_vento", livro_vento), ("leo_missao", leo_missao),
                    ("livro_completo", livro_completo)]:
        f().salvar("assets/historia/%s.png" % nome)
        nomes.append("assets/historia/%s.png" % nome)
    ga.previa(nomes, "historia.png")
