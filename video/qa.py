"""Checagem quadro a quadro do vídeo final (adaptada de templates/scripts/short_qa.py da skill
claude-animated-shorts, MIT): especificações, loudness, silêncios, quadros pretos/brancos/congelados,
"pulos" bruscos de imagem e folhas de contato a cada 2 s.

Uso (na pasta video/):  py qa.py out/leo-na-amazonia.mp4 out/qa_final
Os momentos planejados (flash, entradas com fade, fade final) vêm de src/roteiro.json.
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

vid, out = sys.argv[1], sys.argv[2]
R_ = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "src", "roteiro.json"), encoding="utf-8"))
planejado = set(range(0, 18)) | set(range(17, 28)) | set(range(R_["total"] - 24, R_["total"]))
for c in R_["cenas"]:
    planejado.update(range(c["ini"] - 9, c["ini"] + 2))
os.makedirs(out, exist_ok=True)


BIN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "node_modules", "@remotion", "compositor-win32-x64-msvc")


def run(*a, binario=False):
    # usa o ffmpeg/ffprobe que vem com o Remotion ("npx remotion ffmpeg ..." vira o executável direto)
    a = list(a)
    if a[:2] == ["npx", "remotion"]:
        a = [os.path.join(BIN, a[2] + ".exe")] + a[3:]
    r = subprocess.run(a, capture_output=True)
    if not binario:
        r.stdout = r.stdout.decode("utf-8", "replace")
        r.stderr = r.stderr.decode("utf-8", "replace")
    return r


R = []
pr = json.loads(run("npx", "remotion", "ffprobe", "-v", "error", "-show_entries",
                    "stream=codec_type,codec_name,width,height,r_frame_rate,nb_frames,sample_rate,channels:format=duration",
                    "-of", "json", vid).stdout)
v = next(s for s in pr["streams"] if s["codec_type"] == "video")
au = [s for s in pr["streams"] if s["codec_type"] == "audio"]
R.append(f"SPECS {v['width']}x{v['height']} {v['r_frame_rate']} fps, {v.get('nb_frames')} quadros, "
         f"{float(pr['format']['duration']):.3f} s; áudio: "
         + (", ".join(f"{s['codec_name']} {s['sample_rate']} Hz {s['channels']}ch" for s in au) if au else "NENHUM"))
if au:
    e = run("npx", "remotion", "ffmpeg", "-i", vid, "-map", "0:a:0", "-af", "ebur128=peak=true", "-f", "null", "-").stderr
    tail = e[e.rfind("Summary:"):]
    R.append("LOUDNESS " + " | ".join(l.strip() for l in tail.splitlines() if l.strip().startswith(("I:", "LRA:", "Peak:"))))
    e = run("npx", "remotion", "ffmpeg", "-i", vid, "-map", "0:a:0", "-af", "silencedetect=n=-45dB:d=0.3",
            "-f", "null", "-").stderr
    R.append("SILÊNCIOS " + ("; ".join(l.split("] ")[-1] for l in e.splitlines() if "silence_" in l) or "nenhum"))

W, H = 320, 180
# o ffmpeg do Remotion não tem saída "rawvideo": extrai PNGs pequenos e lê com o Pillow
pasta_q = os.path.join(out, "quadros")
os.makedirs(pasta_q, exist_ok=True)
for f in os.listdir(pasta_q):
    os.remove(os.path.join(pasta_q, f))
run("npx", "remotion", "ffmpeg", "-v", "error", "-i", vid, "-vf", f"scale={W}:{H}:flags=area",
    os.path.join(pasta_q, "q%05d.png"))
F = np.stack([np.asarray(Image.open(os.path.join(pasta_q, f)).convert("RGB"))
              for f in sorted(os.listdir(pasta_q))])
n = len(F)
f32 = F.astype(np.float32) / 255
luma = f32 @ np.array([0.2126, 0.7152, 0.0722], np.float32)
L = luma.reshape(n, -1)
media = L.mean(1)
diff = np.abs(np.diff(F.astype(np.int16), axis=0)).mean(axis=(1, 2, 3))
med = np.array([np.median(diff[max(0, i - 8):i + 9]) for i in range(len(diff))])
pulos = [i + 1 for i in range(len(diff)) if diff[i] > 3 * med[i] + 1.0 and (i + 1) not in planejado]
pretos = [i for i in range(n) if media[i] < 0.04 and i not in planejado]
brancos = [i for i in range(n) if media[i] > 0.93 and i not in planejado]
congelados, ini = [], None
for i in range(len(diff)):
    if diff[i] < 0.02:
        ini = i if ini is None else ini
    else:
        if ini is not None and i - ini >= 12:
            congelados.append((ini, i))
        ini = None
R.append(f"QUADROS {n}; pretos fora do planejado {pretos[:20]}; brancos fora do planejado {brancos[:20]}; "
         f"congelados >=12q {congelados[:20]}")
R.append(f"PULOS (mudança brusca > 3x a mediana local, fora de cortes planejados): {pulos[:40]}")
R.append(f"MOVIMENTO diferença média {diff.mean():.2f}; quadros quase parados (<0,3): {int((diff < 0.3).sum())} "
         f"({(diff < 0.3).mean() * 100:.0f}%)")

cw, ch = 192, 108
for k in range(0, n, 60):
    S = Image.new("RGB", (cw * 10, ch * 6), "black")
    d = ImageDraw.Draw(S)
    for j in range(min(60, n - k)):
        x, y = (j % 10) * cw, (j // 10) * ch
        S.paste(Image.fromarray(F[k + j]).resize((cw, ch)), (x, y))
        d.rectangle([x, y, x + 34, y + 12], fill="black")
        d.text((x + 2, y + 1), str(k + j), fill="yellow")
    S.save(os.path.join(out, f"folha_{k:04d}.jpg"), quality=85)
open(os.path.join(out, "relatorio.md"), "w", encoding="utf-8").write("\n".join(R) + "\n")
print("\n".join(R))
