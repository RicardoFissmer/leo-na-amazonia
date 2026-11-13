"""Trilha do vídeo: música do jogo arranjada, "voz" de blips do Léo, sons gravados do jogo e efeitos sintetizados.

Uso (na pasta video/):  py audio/mixar.py
Lê src/roteiro.json (o mesmo roteiro do Remotion) e gravacoes/*/f.wav. Gera public/audio/mix.wav (48 kHz, 24 bits).

Usa dsp.py e sfx_gen.py da skill claude-animated-shorts (MIT, ver LICENSE-claude-animated-shorts.txt).
"""
import json
import os
import subprocess
import sys

import numpy as np
from scipy import signal

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import sfx_gen as G  # noqa: E402
from dsp import (SR, TAU, ns, tt, rng, dbg, lp, hp, bp, fades, pan, st, read_wav, write_wav,  # noqa: E402
                 integrated, true_peak, make_ir, convolve_st)

VIDEO = os.path.dirname(AQUI)
R = json.load(open(os.path.join(VIDEO, "src", "roteiro.json"), encoding="utf-8"))
FPS = R["fps"]
DUR = R["total"] / FPS
N = ns(DUR)
r = rng(2026)


def seg(frame):
    return frame / FPS


def place(buf, x, t, gain=1.0):
    """soma x (mono ou estéreo) em buf a partir do tempo t"""
    x = st(x) * gain
    i = ns(t)
    if i >= buf.shape[1]:
        return
    n = min(x.shape[1], buf.shape[1] - i)
    if i < 0:
        x = x[:, -i:]
        n = min(x.shape[1], buf.shape[1])
        i = 0
    buf[:, i:i + n] += x[:, :n]


# ---------------------------------------------------------------- música do jogo

def musica():
    cache = os.path.join(AQUI, "cache")
    os.makedirs(cache, exist_ok=True)
    wav = os.path.join(cache, "musica.wav")
    if not os.path.exists(wav):
        ogg = os.path.join(VIDEO, "..", "sons", "musica.ogg")
        subprocess.run(["npx", "remotion", "ffmpeg", "-y", "-loglevel", "error", "-i", ogg, "-ar", str(SR),
                        "-ac", "2", "-c:a", "pcm_s16le", wav], cwd=VIDEO, check=True, shell=True)
    x, sr = read_wav(wav)
    assert sr == SR
    # repete o loop de 16 s até cobrir o vídeo (com cruzamento curto para não "clicar")
    laco = x.shape[1]
    cruz = ns(0.02)
    out = np.zeros((2, N + laco))
    pos = 0
    while pos < N:
        pedaco = x.copy()
        pedaco[:, :cruz] *= np.linspace(0, 1, cruz)
        pedaco[:, -cruz:] *= np.linspace(1, 0, cruz)
        out[:, pos:pos + laco] += pedaco
        pos += laco - cruz
    m = out[:, :N]
    t = np.arange(N) / SR
    # arranjo por volume: entra no flash, fica mais baixo e abafado no gancho, sobe no cenário,
    # abaixa na ventania e nos trechos de jogo (para os sons do jogo aparecerem), sobe no convite e some no fim
    pontos = [(0.0, -60), (0.55, -60), (0.65, -16), (5.6, -16), (6.2, -7), (20.6, -7), (21.0, -13), (27.0, -13),
              (27.4, -8), (33.8, -8), (34.0, -11), (56.6, -11), (56.8, -8), (75.0, -8), (75.3, -6), (85.0, -5),
              (88.4, -7), (90.0, -60)]
    ts, ds = zip(*pontos)
    ganho = dbg(np.interp(t, ts, ds))
    abafado = lp(m, 900, 2)
    mistura = np.clip((t - 5.6) / 0.6, 0, 1)  # gancho abafado, depois aberto
    return (abafado * (1 - mistura) + m * mistura) * ganho


# ---------------------------------------------------------------- voz de blips do Léo

ALTURA = {"normal": 1.0, "falando": 1.0, "feliz": 1.12, "medo": 1.28, "determinado": 0.86, "piscar": 1.0}
CPS = 26


def blip(f0, dur=0.05):
    t = tt(dur)
    onda = np.sign(np.sin(TAU * f0 * t)) * 0.45 + np.sin(TAU * f0 * t) * 0.55
    onda += 0.3 * np.sin(TAU * f0 * 2 * t)
    env = np.minimum(1, t / 0.004) * np.exp(-t / 0.022)
    return lp(onda * env, 3200, 2)


def voz():
    out = np.zeros((2, N))
    vogais = "aeiouáéíóúâêôãõAEIOUÁÉÍÓÚÂÊÔÃÕ"
    for f in R["falas"]:
        texto = f["texto"].replace("[", "").replace("]", "")
        base = 520 * ALTURA.get(f["expressao"], 1.0)
        for k, c in enumerate(texto):
            if not c.isalpha() or k % 2:
                continue
            t0 = seg(f["ini"]) + k / CPS
            if t0 > seg(f["ini"] + f["dur"]):
                break
            fator = 1.18 if c in vogais else 0.94
            fator *= 1 + 0.06 * np.sin(k * 1.7)  # melodia de fala
            # a última letra de uma pergunta sobe, de uma exclamação desce um pouco
            if k >= len(texto) - 3 and texto.endswith("?"):
                fator *= 1.25
            place(out, pan(blip(base * fator), -0.15), t0, dbg(-13))
    return out


# ---------------------------------------------------------------- sons gravados do jogo

def jogo():
    out = np.zeros((2, N))
    for c in R["cenas"]:
        if "clipe" not in c:
            continue
        x, sr = read_wav(os.path.join(VIDEO, "gravacoes", c["clipe"], "f.wav"))
        if sr != SR:
            x = signal.resample_poly(x, SR, sr, axis=-1)
        de = max(0, c["de"] - 8)
        ini = c["ini"] - 8
        dur = c["fim"] - ini
        a, b = ns(seg(de)), ns(seg(de + dur))
        pedaco = x[:, a:b].copy()
        if pedaco.shape[1] < 2:
            continue
        pedaco = fades(pedaco, 0.02, 0.06)
        place(out, pedaco, seg(ini), dbg(-1))
    return out


# ---------------------------------------------------------------- efeitos sintetizados

def pop():
    t = tt(0.12)
    y = np.sin(TAU * (300 * t + 2600 * t * t)) * np.exp(-t / 0.03)
    return y + hp(r.standard_normal(len(t)), 2500) * np.exp(-t / 0.004) * 0.3


def baque():
    t = tt(0.3)
    return np.sin(TAU * 58 * t * (1 + 0.6 * np.exp(-t / 0.02))) * np.exp(-t / 0.09) * 1.4


def sino(f0, dur=1.2):
    t = tt(dur)
    y = sum(a * np.sin(TAU * f0 * m * t) * np.exp(-t / (dur * d)) for m, a, d in
            [(1, 1.0, 0.35), (2.0, 0.4, 0.2), (3.01, 0.25, 0.12), (4.2, 0.12, 0.08)])
    return y * np.minimum(1, t / 0.002)


def brilho(t0, notas=(1568, 2093, 2637), passo=0.07, ganho=-20):
    out = []
    for i, f in enumerate(notas):
        out.append((sino(f, 0.9), t0 + i * passo, ganho))
    return out


def rosnado(dur=1.1):
    n = ns(dur)
    t = np.arange(n) / SR
    ruido = bp(r.standard_normal(n), 70, 420, 2)
    trem = 0.6 + 0.4 * np.sin(TAU * 23 * t) * np.sin(TAU * 3.1 * t)
    env = np.minimum(1, t / 0.12) * np.clip((dur - t) / 0.3, 0, 1)
    voz_ = np.sin(TAU * (85 + 15 * np.sin(TAU * 2 * t)) * t) * 0.5
    return (ruido * 2.5 + voz_) * trem * env


def efeitos():
    lista = []
    # gancho
    lista.append((pop(), seg(18), -8))
    lista.append((G.whoosh(0.5, r, peak=0.18), seg(14), -16))
    # transições entre cenas
    for f in [180, 420, 1020, 1700, 2030, 2250, 2460, 2550]:
        lista.append((G.whoosh(0.7, r, peak=0.35, f_lo=300, f_hi=1800), seg(f) - 0.35, -20))
    # pássaros na mata
    lista.append((G.bird_chirps(15.0, r, density=0.6), seg(180), -24))
    lista.append((G.bird_chirps(7.0, r, density=0.5, kind="blackbird"), seg(2250), -24))
    lista.append((G.crickets(6.0, r), seg(0), -34))
    # livro
    lista += brilho(seg(430))
    lista += brilho(seg(560), (2093, 2637, 3136), 0.06, -24)
    # ventania + moedas
    lista.append((G.breeze(6.2, r, level=1.0, gust=0.6, bright=1600), seg(630), -22))
    lista.append((G.whoosh(1.3, r, peak=0.3, f_lo=250, f_hi=3000, width=1.0, tail=0.5, air=0.3), seg(636), -14))
    for i in range(14):
        lista.append((G.clink(r, f0=r.uniform(2400, 4200), dur=0.15), seg(642 + i * 4) + r.uniform(0, 0.03), -18))
    # boa notícia / má notícia
    lista.append((rosnado(), seg(918), -9))
    # impactos (as mesmas sacudidas da imagem)
    for k in R["kicks"]:
        lista.append((baque(), seg(k["f"]), -10 if k["a"] >= 12 else -16))
    # desfile: um sino por animal e brilho no livro completo
    notas = [1047, 1175, 1319, 1568, 1760]
    for i, a in enumerate(R["desfile"]):
        lista.append((sino(notas[i], 0.8), seg(a["f"]) + 0.08, -18))
        lista.append((G.whoosh(0.35, r, peak=0.12, f_lo=600, f_hi=2600), seg(a["f"]), -24))
    lista += brilho(seg(2175), (1568, 1976, 2349, 3136), 0.08, -16)
    # convite: "vem comigo!" com um viva de criança
    for i, (base, esc) in enumerate([(310, 1.35), (350, 1.4)]):
        lista.append((G.hurrah(rng(77 + i), base, esc, kid=True), seg(2372) + i * 0.12, -23))
    lista += brilho(seg(2368), (1568, 2093, 2637, 3136), 0.06, -18)
    # final
    lista += brilho(seg(2560), (1047, 1319, 1568, 2093), 0.12, -14)

    out = np.zeros((2, N))
    for x, t0, g in lista:
        place(out, x, t0, dbg(g))
    # reverb leve para colar os efeitos no mesmo "espaço"
    ir = make_ir(0.9, 11)
    molhado = convolve_st(out, ir)[:, :N]
    return out + molhado * 0.18


def limitar(x, teto_db=-1.0):
    teto = dbg(teto_db)
    return np.tanh(x / teto) * teto


def main():
    partes = {"musica": musica(), "voz": voz(), "jogo": jogo(), "efeitos": efeitos()}
    for k, v in partes.items():
        print(f"{k:8s} pico {20 * np.log10(np.abs(v).max() + 1e-9):6.1f} dBFS")
    mix = sum(partes.values())
    # loudness alvo -16 LUFS (bom para vídeo em sala e na internet), pico abaixo de -1 dBTP
    lufs = integrated(mix)
    mix *= dbg(-16.0 - lufs)
    mix = limitar(mix, -1.2)
    mix = fades(mix, 0.0, 0.5)
    print(f"final: {integrated(mix):.1f} LUFS, pico real {true_peak(mix):.1f} dBTP, {mix.shape[1] / SR:.2f} s")
    destino = os.path.join(VIDEO, "public", "audio", "mix.wav")
    write_wav(destino, mix)
    print("ok", destino)


if __name__ == "__main__":
    main()
