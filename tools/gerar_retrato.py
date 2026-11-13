"""Gera o retrato grande do Léo (busto 64x64, de frente) com várias expressões, para o vídeo.

Uso (na pasta do projeto):  py tools/gerar_retrato.py
Saída: video/public/leo/<expressao>.png e tools/preview/retratos.png
"""
import os

from PIL import Image

import gerar_arte as ga
from gerar_arte import Tela, cor, rampa, elipse, poligono, tubo

PELE = rampa("#6e3c1c", "#8f5228", "#b8743e", "#d9955a", "#ecb07a")
CABELO = rampa("#120a05", "#1f130a", "#352013", "#5c3a22")
CAMISA = rampa("#b8860b", "#e6b400", "#ffd21f", "#fff27a")
VERDE = rampa("#12622a", "#1f8f3a", "#1f9d3a", "#47c25c")
AZUL = rampa("#123a9a", "#1e4fbf", "#3a78e8")
CONTORNO = cor("#2a150a")
S = 64


def olho(t, cx, cy, expressao, lado):
    if expressao in ("piscar",):
        t.linha([(cx - 4, cy + 1), (cx - 2, cy + 2), (cx + 2, cy + 2), (cx + 4, cy + 1)], "#2a150a")
        return
    if expressao == "feliz":
        t.linha([(cx - 4, cy + 2), (cx - 2, cy), (cx, cy - 1), (cx + 2, cy), (cx + 4, cy + 2)], "#2a150a")
        t.linha([(cx - 4, cy + 3), (cx - 2, cy + 1), (cx, cy), (cx + 2, cy + 1), (cx + 4, cy + 3)], "#2a150a")
        return
    ry = 5.2 if expressao == "medo" else 4.6
    t.pintar(elipse(cx, cy, 4.2, ry, rampa("#cfc8bc", "#ece6dc", "#fbf8f2"), dither=0),
             cor_contorno=CONTORNO)
    # íris e pupila olhando para quem assiste (um pouco para o centro)
    ix = cx + (0.6 if lado < 0 else -0.6)
    r_iris = 2.0 if expressao == "medo" else 2.8
    t.pintar(elipse(ix, cy + 0.6, r_iris, r_iris + 0.3, rampa("#2a160a", "#4a2a14", "#6a3e1e"), dither=0),
             contorno=False)
    t.pintar(elipse(ix, cy + 0.8, r_iris * 0.55, r_iris * 0.6, rampa("#050303", "#0d0806"), dither=0),
             contorno=False)
    t.ponto(int(ix) - 1, int(cy) - 1, "#ffffff")
    t.ponto(int(ix), int(cy) - 1, "#ffffff")
    # pálpebra de cima
    t.linha([(cx - 4, cy - 4), (cx - 2, cy - 5), (cx + 2, cy - 5), (cx + 4, cy - 4)], "#2a150a")


def sobrancelhas(t, expressao):
    if expressao == "medo":
        pares = [((19, 24), (27, 22)), ((37, 22), (45, 24))]   # levantadas no meio
    elif expressao == "determinado":
        pares = [((19, 23), (27, 26)), ((37, 26), (45, 23))]   # franzidas
    elif expressao == "feliz":
        pares = [((19, 24), (27, 23)), ((37, 23), (45, 24))]
    else:
        # arqueadas e simpáticas
        for pts in ([(19, 25), (21, 23), (25, 23), (27, 24)], [(37, 24), (39, 23), (43, 23), (45, 25)]):
            t.linha(pts, "#1a0f08")
            t.linha([(x, y + 1) for (x, y) in pts], "#1a0f08")
        return
    for a, b in pares:
        t.linha([a, b], "#1a0f08")
        t.linha([(a[0], a[1] + 1), (b[0], b[1] + 1)], "#1a0f08")


def boca(t, expressao):
    if expressao == "falando":
        t.pintar(elipse(32, 46, 4.6, 3.4, rampa("#3a0c08", "#5a1a10", "#7a2618"), dither=0), cor_contorno=CONTORNO)
        t.linha([(29, 44), (35, 44)], "#f6f2ea")
        t.pintar(elipse(32, 47.5, 2.6, 1.3, rampa("#b03a30", "#d0605a"), dither=0), contorno=False)
    elif expressao == "feliz":
        t.pintar(poligono([(25, 43), (39, 43), (36, 48), (32, 49), (28, 48)],
                          rampa("#3a0c08", "#5a1a10", "#7a2618"), (0, 1)), cor_contorno=CONTORNO)
        t.linha([(27, 44), (37, 44)], "#f6f2ea")
        t.pintar(elipse(32, 47.5, 2.8, 1.2, rampa("#b03a30", "#d0605a"), dither=0), contorno=False)
    elif expressao == "medo":
        t.pintar(elipse(32, 46.5, 2.6, 3.0, rampa("#3a0c08", "#5a1a10"), dither=0), cor_contorno=CONTORNO)
    elif expressao == "determinado":
        t.linha([(28, 46), (31, 46), (35, 45), (37, 44)], "#4a1a10")
    else:
        t.linha([(27, 44), (29, 46), (35, 46), (37, 44)], "#4a1a10")


def retrato(expressao="normal"):
    t = Tela(S, S)
    # ombros e camisa
    t.pintar(elipse(32, 74, 27, 20, CAMISA))
    t.pintar(poligono([(26, 53), (38, 53), (32, 61)], VERDE, (0, 1)), cor_contorno=cor("#0e3a18"))
    t.pintar(poligono([(28, 53), (36, 53), (32, 58)], PELE, (0, 1)), contorno=False)
    t.pintar(elipse(42, 60, 2.6, 2.6, AZUL, dither=0), cor_contorno=cor("#0a1e50"))
    # pescoço
    t.pintar(poligono([(27, 46), (37, 46), (37, 54), (27, 54)], PELE, (1, 0)), contorno=False)
    # orelhas e cabeça
    t.pintar(elipse(15, 35, 3.6, 4.6, PELE))
    t.pintar(elipse(49, 35, 3.6, 4.6, PELE))
    t.pintar(elipse(32, 34, 17, 16.5, PELE))
    # cabelo alto e cacheado
    cabelo = {}
    cachos = [(16, 20, 5.5), (21, 14, 6.0), (27, 10, 6.5), (33, 9, 6.5), (39, 10, 6.5), (44, 14, 6.0),
              (48, 20, 5.0), (24, 6, 5.0), (31, 4, 5.0), (38, 5, 5.0), (19, 9, 4.5), (45, 8, 4.5),
              (32, 15, 7.0)]
    for (cx, cy, r) in cachos:
        cabelo.update(elipse(cx, cy, r, r * 0.95, CABELO, dither=0.25))
    # recorta a franja para deixar a testa aparecer
    cabelo = {k: v for k, v in cabelo.items() if k[1] < 21 or k[0] < 17 or k[0] > 47}
    t.pintar(cabelo, cor_contorno=cor("#0a0603"))
    for (x, y) in [(22, 9), (28, 6), (34, 5), (40, 8), (25, 15), (37, 13), (45, 17), (18, 17), (31, 11)]:
        t.ponto(x, y, "#6a4428")
        t.ponto(x + 1, y, "#4a2e1a")
    # rosto
    sobrancelhas(t, expressao)
    olho(t, 23, 32, expressao, -1)
    olho(t, 41, 32, expressao, 1)
    t.linha([(31, 38), (32, 40), (34, 40)], "#8f5228")  # nariz
    for (x, y) in [(18, 39), (19, 40), (45, 39), (46, 40)]:
        t.ponto(x, y, "#d97a5a")  # bochechas
    boca(t, expressao)
    if expressao == "medo":
        t.pintar(elipse(50, 24, 1.6, 2.4, rampa("#8ac8f0", "#c8ecff", "#ffffff"), dither=0),
                 cor_contorno=cor("#3a6a9a"))  # gota de suor
    return t.img


EXPRESSOES = ["normal", "falando", "piscar", "feliz", "medo", "determinado"]

if __name__ == "__main__":
    pasta = os.path.join(ga.RAIZ, "video", "public", "leo")
    os.makedirs(pasta, exist_ok=True)
    prev = Image.new("RGBA", (len(EXPRESSOES) * (S * 4 + 8), S * 4), (40, 90, 60, 255))
    for i, e in enumerate(EXPRESSOES):
        img = retrato(e)
        img.save(os.path.join(pasta, e + ".png"))
        prev.alpha_composite(img.resize((S * 4, S * 4), Image.NEAREST), (i * (S * 4 + 8), 0))
    prev.save(os.path.join(ga.RAIZ, "tools", "preview", "retratos.png"))
    print("ok", len(EXPRESSOES), "expressões")
