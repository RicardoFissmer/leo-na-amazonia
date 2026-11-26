"""Monta a linha do tempo do vídeo de apresentação (src/apresentacao.json).

Junta o roteiro (falas e durações), as marcas das gravações do jogo
(gravacoes/live, apresentacao/marcas_outras.json, gravacoes/antes) e decide
em que quadro do vídeo cada trecho e cada fala começa.
Uso (na pasta video/):  py -3.14 apresentacao/montar_timeline.py
"""
import json
from pathlib import Path

FPS = 30
VAO = 12        # intervalo entre falas seguidas (0,4 s)
ATRASO = 6      # a fala começa 0,2 s depois da marca da gravação

base = Path(__file__).resolve().parent.parent
roteiro = json.loads((base / "apresentacao/roteiro_apresentacao.json").read_text(encoding="utf-8"))
falas = {f["id"]: f for f in roteiro["falas"]}
live = json.loads((base / "gravacoes/live/marcas.json").read_text(encoding="utf-8"))
outras = json.loads((base / "apresentacao/marcas_outras.json").read_text(encoding="utf-8"))


def q(seg: float) -> int:
    return int(round(seg * FPS))


segmentos = []
saida_falas = []
capitulos = []
t = 0  # quadro atual do vídeo


def fala(fid: str, ini: int) -> int:
    """Coloca a fala no quadro `ini` e devolve o quadro em que ela termina."""
    f = falas[fid]
    dur = q(f["dur"])
    saida_falas.append({"id": fid, "ini": ini, "dur": dur, "texto": f["texto"]})
    return ini + dur


def em_sequencia(ids, ini: int) -> int:
    fim = ini
    for fid in ids:
        fim = fala(fid, fim) + VAO
    return fim - VAO


def segmento(tipo: str, ini: int, dur: int, **extra):
    segmentos.append({"tipo": tipo, "ini": ini, "dur": dur, **extra})


def capitulo(texto: str, ini: int, sub: str = ""):
    capitulos.append({"texto": texto, "sub": sub, "ini": ini})


# 1. abertura: quem sou, qual é o jogo
fim = em_sequencia(["a01", "a02", "a03"], t + 24)
segmento("abertura", t, fim + 30 - t)
t = fim + 30

# 2. gravação contínua: menu -> história -> tutorial -> fase -> montagem -> quiz
ids_proposta = ["p01", "p02", "p03"]
dur_proposta = sum(q(falas[i]["dur"]) for i in ids_proposta) + VAO * (len(ids_proposta) - 1)
l0 = max(0, live["m01"] - (24 + dur_proposta + 24))
# A gravação contínua parou no meio da montagem; o final (a partir da fala w02) foi gravado à parte
# (cena live_fim, que recria o mesmo estado). As duas partes se emendam com uma fusão de 8 quadros.
fim_mc = json.loads((base / "gravacoes/live_fim/marcas.json").read_text(encoding="utf-8"))
CORTE, FUSAO = live["w02"], 8
d0 = fim_mc["w02"]
dur_parte1 = CORTE - l0
for k in ["w02", "w03", "w04", "q01", "q02", "q03", "q04", "q05", "fim"]:
    live[k] = CORTE + fim_mc[k] - d0  # marcas da parte final no relógio da gravação principal
dur_live = live["fim"] - l0
segmento("video", t, dur_parte1 + FUSAO, src="clipes/live.mp4", de=l0, som=True)
segmento("video", t + dur_parte1, dur_live - dur_parte1, src="clipes/live_fim.mp4", de=d0, som=True, fusao=FUSAO)
capitulo("A proposta", t + 10, "jogo de plataforma educativo")
ini_prop = t + 24
fim_p = ini_prop
cartoes = []
for fid in ids_proposta:
    cartoes.append({"ini": fim_p})
    fim_p = fala(fid, fim_p) + VAO
segmento("proposta", ini_prop - 10, fim_p - ini_prop + 20, cartoes=[c["ini"] - (ini_prop - 10) for c in cartoes])
nomes = {"m01": ("A tela inicial", "menu"), "h01": ("A história", "o objetivo do jogo"),
         "t01": ("Primeira vez jogando", "o tutorial ensina uma ação de cada vez"),
         "f01": ("O resto da fase", "agora sem dicas"),
         "w01": ("Desafio 1", "montar a palavra"), "q01": ("Desafio 2", "verdadeiro ou falso")}
for fid in sorted((k for k in live if k in falas), key=lambda k: live[k]):
    ini = t + live[fid] - l0 + ATRASO
    fala(fid, ini)
    if fid in nomes:
        capitulo(nomes[fid][0], ini - ATRASO, nomes[fid][1])
t += dur_live

# 3. outras fases, vidas e final
o0 = outras["o01"] - 15
dur_o = outras["fim"] - o0
segmento("video", t, dur_o, src="clipes/outras.mp4", de=o0, som=True)
for fid, nome in [("o01", ("As outras fases", "onça, boto, tucano e capivara")),
                  ("o02", None), ("o03", ("Vidas", "fora do tutorial, errar custa")),
                  ("o04", ("O final", "o livro está completo"))]:
    ini = t + outras[fid] - o0 + ATRASO
    fala(fid, ini)
    if nome:
        capitulo(nome[0], ini - ATRASO, nome[1])
t += dur_o

# 4. ajustes: de onde vieram
fim = em_sequencia(["j01", "j02"], t + 24)
segmento("ajustes", t, fim + 24 - t)
capitulo("Os ajustes", t + 6, "do protótipo até a versão final")
t = fim + 24

# 5. antes: versão 1.3
fim = em_sequencia(["j03", "j04"], t + 15)
segmento("video", t, fim + 15 - t, src="clipes/antes.mp4", de=0, som=True, etiqueta="ANTES · versão 1.3 (outubro)")
t = fim + 15

# 6. depois: história e tutorial
fim = fala("j05", t + 12) + 12
segmento("video", t, fim - t, src="clipes/live.mp4", de=live["h01"] - 6, som=False,
         etiqueta="DEPOIS · história com personagem, conflito e consequência")
t = fim
fim = fala("j06", t + 12) + 12
segmento("video", t, fim - t, src="clipes/live.mp4", de=live["t01"] - 30, som=False,
         etiqueta="DEPOIS · tutorial e dica do animal em destaque")
t = fim

# 7. sprites
ini_j08 = None
fim = fala("j07", t + 15) + VAO
ini_j08 = fim
fim = fala("j08", fim) + 20
segmento("sprites", t, fim - t, troca=ini_j08 - t)
t = fim

# 8. menus lado a lado e versão web
fim = fala("j09", t + 15) + 20
segmento("menus", t, fim - t, antes_de=0, depois_de=60)
t = fim
fim = fala("j10", t + 12) + 24
segmento("web", t, fim - t)
t = fim

# 9. encerramento
fim = em_sequencia(["e01", "e02", "e03"], t + 20)
segmento("encerramento", t, fim + 75 - t)
capitulo("Links", t + 6, "repositório, jogo no navegador e Windows")
t = fim + 75

saida = {"fps": FPS, "total": t, "segmentos": segmentos, "falas": saida_falas, "capitulos": capitulos}
(base / "src/apresentacao.json").write_text(json.dumps(saida, ensure_ascii=False, indent=1), encoding="utf-8")

# roteiro com tempos, para quem quiser gravar a própria voz por cima da versão sem narração
linhas = ["Léo na Amazônia - roteiro da apresentação com tempos (mm:ss)", ""]
for f in sorted(saida_falas, key=lambda x: x["ini"]):
    s = f["ini"] / FPS
    linhas.append(f"[{int(s // 60):02d}:{s % 60:04.1f}] ({f['dur'] / FPS:.0f} s)  {f['texto']}")
(base / "apresentacao/roteiro_com_tempos.txt").write_text("\n".join(linhas) + "\n", encoding="utf-8")

# confere sobreposição de falas
ordem = sorted(saida_falas, key=lambda x: x["ini"])
for a, b in zip(ordem, ordem[1:]):
    if a["ini"] + a["dur"] > b["ini"]:
        print(f"AVISO: {a['id']} termina depois de {b['id']} começar ({(a['ini'] + a['dur'] - b['ini']) / FPS:.1f} s)")
print(f"total: {t} quadros = {t / FPS / 60:.2f} min, {len(saida_falas)} falas")
