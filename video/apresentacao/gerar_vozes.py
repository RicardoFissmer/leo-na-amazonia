"""Gera todas as falas da apresentação com a voz do Windows e normaliza o volume.

Para cada fala do roteiro: falar.ps1 -> apresentacao/voz/<id>.wav (bruto) -> public/voz/<id>.wav (normalizado),
e grava a duração em `dur` no roteiro (o _gravacao.gd e o montar_timeline.py usam esse valor).
Uso (na pasta video/):  py -3.14 apresentacao/gerar_vozes.py [ids...]
"""
import json
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

VELOCIDADE = 1.06
ALVO_RMS = 0.13  # mesmo nível das falas da primeira versão (RMS só dos trechos com voz)

base = Path(__file__).resolve().parent.parent
p_rot = base / "apresentacao/roteiro_apresentacao.json"
roteiro = json.loads(p_rot.read_text(encoding="utf-8"))
so = set(sys.argv[1:])
(base / "apresentacao/voz").mkdir(exist_ok=True)


def ler(p: Path):
    with wave.open(str(p)) as w:
        n, sr, ch, sw = w.getnframes(), w.getframerate(), w.getnchannels(), w.getsampwidth()
        x = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float32) / 32768
    return x.reshape(-1, ch).mean(axis=1), sr


def gravar(p: Path, x, sr):
    with wave.open(str(p), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())


for f in roteiro["falas"]:
    if so and f["id"] not in so:
        continue
    bruto = base / f"apresentacao/voz/{f['id']}.wav"
    subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", str(base / "apresentacao/falar.ps1"),
                    "-Texto", f["texto"], "-Saida", str(bruto), "-Velocidade", str(VELOCIDADE)], check=True)
    x, sr = ler(bruto)
    # corta silêncio do começo e do fim (sobra 40 ms)
    voz = np.nonzero(np.abs(x) > 0.01)[0]
    m = int(0.04 * sr)
    x = x[max(0, voz[0] - m): voz[-1] + m]
    janelas = x[: len(x) // 480 * 480].reshape(-1, 480)
    rms_j = np.sqrt((janelas ** 2).mean(axis=1))
    rms = np.sqrt((rms_j[rms_j > 0.02] ** 2).mean())
    x = x * (ALVO_RMS / rms)
    pico = np.abs(x).max()
    if pico > 0.89:  # limita o pico em -1 dBFS
        x = x * (0.89 / pico)
    # entrada e saída suaves (5 ms) para não estalar
    r = int(0.005 * sr)
    x[:r] *= np.linspace(0, 1, r)
    x[-r:] *= np.linspace(1, 0, r)
    gravar(base / f"public/voz/{f['id']}.wav", x, sr)
    f["dur"] = round(len(x) / sr, 2)
    print(f"{f['id']}: {f['dur']:.2f} s")

p_rot.write_text(json.dumps(roteiro, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
