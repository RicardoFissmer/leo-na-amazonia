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


# 1. abertura: quem sou e qual é o jogo (uma fala só, direto ao ponto)
fim = em_sequencia(["a01"], t + 18)
segmento("abertura", t, fim + 24 - t)
t = fim + 24

# 2. gravação contínua: menu -> história -> tutorial -> fase -> montagem -> quiz
ids_proposta = ["p01", "p02"]
dur_proposta = sum(q(falas[i]["dur"]) for i in ids_proposta) + VAO * (len(ids_proposta) - 1)
l0 = max(0, live["m01"] - (18 + dur_proposta + 18))
# A gravação contínua parou no meio da montagem; o final (a partir da fala w02) foi gravado à parte
# (cena live_fim, que recria o mesmo estado). As duas partes se emendam com uma fusão de 8 quadros.
fim_mc = json.loads((base / "gravacoes/live_fim/marcas.json").read_text(encoding="utf-8"))
CORTE, FUSAO = live["w02"], 8
d0 = fim_mc["w02"]
for k in ["w02", "w03", "w04", "q01", "q02", "q03", "q04", "q05", "fim"]:
    live[k] = CORTE + fim_mc[k] - d0  # marcas da parte final no relógio da gravação principal
# Trechos do menu que saem do vídeo, para ir mais direto ao ponto (no relógio da gravação principal):
# o silêncio depois de m01, o modo retrô inteiro (m03), parte da tela Como jogar e o silêncio depois de m05.
def fim_fala_live(fid, folga):
    return live[fid] + ATRASO + q(falas[fid]["dur"]) + folga
cortes = [
    (fim_fala_live("m01", 15), live["m02"] - 3),
    (live["m03"] - 10, live["m04"] + 20),
    (live["m04"] + 20 + q(falas["m04"]["dur"]) + 100, live["m05"] - 3),
    (fim_fala_live("m05", 12), live["jogar"] - 3),
]
# pedaços que ficam: (início, fim, arquivo, início no arquivo)
pedacos, ini_p = [], l0
for c0, c1 in cortes:
    pedacos.append((ini_p, c0, "clipes/live.mp4", ini_p))
    ini_p = c1
pedacos.append((ini_p, CORTE, "clipes/live.mp4", ini_p))
pedacos.append((CORTE, live["fim"], "clipes/live_fim.mp4", d0))


def no_video(m: int) -> int:
    """Quadro do vídeo final para um quadro da gravação principal (marcas dentro de um corte vão para o fim dele)."""
    acc = t
    for p0, p1, _, _ in pedacos:
        if m < p1:
            return acc + max(0, m - p0)
        acc += p1 - p0
    return acc


acc = t
for i, (p0, p1, src, de) in enumerate(pedacos):
    ult = i == len(pedacos) - 1
    extra = {"fusao": FUSAO} if i > 0 else {}
    segmento("video", acc, p1 - p0 + (0 if ult else FUSAO), src=src, de=de, som=True, **extra)
    acc += p1 - p0
dur_live = acc - t
capitulo("A proposta", t + 10, "jogo de plataforma educativo")
ini_prop = t + 18
cartoes = [ini_prop]
fim_p = fala("p01", ini_prop) + VAO
cartoes += [ini_prop + 90, fim_p]
fim_p = fala("p02", fim_p) + VAO
segmento("proposta", ini_prop - 10, fim_p - ini_prop + 20, cartoes=[c - (ini_prop - 10) for c in cartoes])
nomes = {"m01": ("A tela inicial", "menu"), "h01": ("A história", "o objetivo do jogo"),
         "t01": ("Primeira vez jogando", "o tutorial ensina uma ação de cada vez"),
         "f01": ("O resto da fase", "agora sem dicas"),
         "w01": ("Desafio 1", "montar a palavra"), "q01": ("Desafio 2", "verdadeiro ou falso")}
for fid in sorted((k for k in live if k in falas), key=lambda k: live[k]):
    ini = no_video(live[fid]) + ATRASO
    fala(fid, ini)
    if fid in nomes:
        capitulo(nomes[fid][0], ini - ATRASO, nomes[fid][1])
# fala sem marca própria: cai na terceira resposta do quiz (o _gravacao.gd responde 16 s depois da marca q03)
fala("q03b", no_video(live["q03"]) + q(15.4))
t += dur_live

# 3. outras fases, a fase da capivara completa, vidas e final
cap = json.loads((base / "gravacoes/capivara/marcas.json").read_text(encoding="utf-8"))
o0 = outras["o01"] - 15
o_meio = outras["o03"] - 19  # antes de a gravação trocar para a fase da onça
c0 = cap["c01"] - 30
trechos = [("clipes/outras.mp4", o0, o_meio, outras, ["o01", "o02"]),
           ("clipes/capivara.mp4", c0, cap["fim"], cap, ["c01", "c02", "c03", "c04"]),
           ("clipes/outras.mp4", o_meio, outras["fim"], outras, ["o03", "o04"])]
titulos = {"o01": ("As outras fases", "onça, boto, tucano e capivara"),
           "o03": ("Vidas", "fora do tutorial, errar custa"),
           "o04": ("O final", "o livro está completo")}
for i, (src, a0, a1, marcas, ids) in enumerate(trechos):
    ult = i == len(trechos) - 1
    extra = {"fusao": FUSAO} if i > 0 else {}
    segmento("video", t, a1 - a0 + (0 if ult else FUSAO), src=src, de=a0, som=True, **extra)
    for fid in ids:
        ini = t + marcas[fid] - a0 + ATRASO
        fala(fid, ini)
        if fid in titulos:
            capitulo(titulos[fid][0], ini - ATRASO, titulos[fid][1])
    t += a1 - a0

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

# 9. o que ainda falta
fim = em_sequencia(["l01", "l02"], t + 15)
segmento("limites", t, fim + 20 - t)
capitulo("O que ainda falta", t + 6, "próximos passos")
t = fim + 20

# 10. encerramento
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
