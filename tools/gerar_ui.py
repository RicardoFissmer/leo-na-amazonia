"""Gera as imagens da interface do menu: logo, placas de madeira dos botões, cursor e folha.

Uso (na pasta do projeto):  py tools/gerar_ui.py
Saída em assets/ui/.
"""
import os

from PIL import Image

import gerar_arte as ga
from gerar_arte import Tela, cor, rampa, elipse
from gerar_capa import texto_titulo

PASTA = os.path.join(ga.RAIZ, "assets", "ui")

MADEIRA = rampa("#5a3418", "#73441f", "#8c5629", "#a86c34", "#c48a48")
CONTORNO = cor("#2a150a")


def logo():
    l1 = texto_titulo("LÉO NA", 2)
    l2 = texto_titulo("AMAZÔNIA", 3)
    larg = max(l1.width, l2.width)
    img = Image.new("RGBA", (larg, l1.height + l2.height - 4), (0, 0, 0, 0))
    img.alpha_composite(l1, ((larg - l1.width) // 2, 0))
    img.alpha_composite(l2, ((larg - l2.width) // 2, l1.height - 4))
    return img


def placa(foco=False):
    """Placa de madeira 32x18 para usar como 9-slice (bordas de 6 px)."""
    w, h = 32, 18
    t = Tela(w, h)
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            tom = 1.0 - (y - 1) / (h - 3)  # mais claro em cima
            if foco:
                tom = min(1.0, tom + 0.35)
            t.put(x, y, ga._tom(MADEIRA, tom * 0.85 + 0.1, x, y, 0.15))
    # veios da madeira
    escuro = MADEIRA[0] if not foco else MADEIRA[1]
    for (y, x0, x1) in [(5, 3, 12), (8, 16, 28), (11, 5, 20), (13, 22, 29)]:
        for x in range(x0, x1):
            t.put(x, y, escuro)
    # brilho na borda de cima e sombra embaixo
    for x in range(2, w - 2):
        t.put(x, 1, cor("#e2b070") if foco else MADEIRA[4])
        t.put(x, h - 2, MADEIRA[0])
    # pregos nos cantos
    for (x, y) in [(3, 3), (w - 4, 3), (3, h - 4), (w - 4, h - 4)]:
        t.put(x, y, cor("#d8d0c0")); t.put(x + 1, y + 1, cor("#5a5048"))
    # contorno (dourado quando está selecionado)
    borda = cor("#ffd21f") if foco else CONTORNO
    for x in range(1, w - 1):
        t.put(x, 0, borda); t.put(x, h - 1, borda)
    for y in range(1, h - 1):
        t.put(0, y, borda); t.put(w - 1, y, borda)
    return t.img


def cursor():
    """Cabeça do Léo (do sprite do jogo) para marcar o botão selecionado."""
    folha = Image.open(os.path.join(ga.RAIZ, "assets", "leo.png")).convert("RGBA")
    cabeca = folha.crop((0, 0, 16, 13))
    return cabeca.crop(cabeca.getbbox())


def folha_caindo():
    t = Tela(6, 4)
    t.pintar(elipse(3, 2, 2.6, 1.4, ga.FOLHA, rot=0.3, dither=0), contorno=False)
    return t.img


if __name__ == "__main__":
    os.makedirs(PASTA, exist_ok=True)
    for nome, img in [("logo", logo()), ("placa", placa()), ("placa_foco", placa(True)),
                      ("cursor_leo", cursor()), ("folha", folha_caindo())]:
        caminho = os.path.join(PASTA, nome + ".png")
        img.save(caminho)
        print("ok", caminho, img.size)
