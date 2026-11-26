# Vídeos — como foram feitos e como refazer

Esta pasta gera os dois vídeos da entrega final, no mesmo projeto Remotion (`src/Root.tsx`):

| Composição | Vídeo | Duração |
|---|---|---|
| `Apresentacao` | Apresentação do jogo, narrada e legendada (gravação do jogo + cartões) | 10 min 10 s |
| `ApresentacaoSemNarracao` | A mesma, sem voz e sem legendas (para gravar a própria voz por cima) | 10 min 10 s |
| `LeoTrailer` | Trailer narrativo com balões de fala do Léo | 90 s |

## Apresentação (10 min)

1. **Roteiro:** `apresentacao/roteiro_apresentacao.json` (60 falas, cada uma com o bloco e a duração).
2. **Voz:** `py apresentacao/gerar_vozes.py` gera todas as falas com a voz *Microsoft Daniel* (pt-BR) do Windows
   (`falar.ps1`, velocidade 1,06, com o mínimo de pausa na pontuação para a fala ficar mais corrida), normaliza o
   volume em `public/voz/<id>.wav` e grava a duração de cada fala no roteiro. Para refazer só algumas:
   `py apresentacao/gerar_vozes.py c03 c04`.
3. **Gravar o jogo:** o `_gravacao.gd` (na raiz do jogo) joga sozinho no ritmo das falas e anota em `marcas.json` o
   quadro em que cada fala começa. Cenas usadas: `live` (menu → história → tutorial → fase 1 → montagem → quiz, em uma
   tomada só), `live_fim` (o final da montagem e do quiz, recriando o mesmo estado), `outras` (fases 2 e 4, vidas e
   final), `capivara` (montagem e quiz da última fase, acertando tudo). A versão 1.3 (cena `antes`) foi gravada a partir da tag `v1.3`. Comando (1080p com `override.cfg`, ver abaixo):
   ```bash
   Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --write-movie video/gravacoes/live/f.png res://_gravacao.tscn -- --cena=live
   ```
   Depois, converter os quadros para `public/clipes/<cena>.mp4` como no passo 2 do trailer. O `live.mp4` (58 MB) não
   vai para o Git; é refeito por esse comando.
4. **Linha do tempo:** `py apresentacao/montar_timeline.py` junta roteiro + marcas, corta do menu os trechos sem
   fala (para o começo ir direto ao ponto) e gera `src/apresentacao.json` e
   `apresentacao/roteiro_com_tempos.txt` (o roteiro com o minuto de cada fala).
5. **Renderizar:**
   ```bash
   npx remotion render src/index.ts Apresentacao out/apresentacao_leo_na_amazonia.mp4 --codec h264 --crf 18 --audio-codec aac
   npx remotion render src/index.ts ApresentacaoSemNarracao out/apresentacao_sem_narracao.mp4 --codec h264 --crf 18 --audio-codec aac
   ```
   A música do jogo e os sons baixam automaticamente (*ducking*) enquanto a narração fala.

## Trailer narrativo (90 s)

Vídeo de ~90 s (1920×1080, 30 fps) que apresenta o jogo pelo ponto de vista do Léo. Roteiro e intenção em
[ROTEIRO.md](ROTEIRO.md).

Produzido com a skill **claude-animated-shorts** (<https://github.com/mromidev/claude-animated-shorts>, MIT),
adaptada para este projeto:

| Da skill | Como usamos |
|---|---|
| Fórmula de roteiro (gancho → cenário → escalada → virada → frase dupla → explicação → consequência → retorno) | Mantida, com o Léo falando em primeira pessoa |
| Remotion para montar o vídeo | Mantido (`src/`) |
| Mundo 3D em three.js | Trocado pelo mundo em pixel art do próprio jogo (camadas com parallax e desfoque) |
| Voz narrada | Trocada por balões de fala com "blips" a cada letra (estilo videogame) |
| Câmera: deslizes suaves, aproximação lenta nas pausas, sacudidas de 7 quadros, flash após o gancho | Mantida (`src/camera.ts`) |
| Som sintetizado (`dsp.py`, `sfx_gen.py`) + mixagem com loudness | Mantido (`audio/`), com a música do próprio jogo |
| Checagem quadro a quadro (`short_qa.py`) | Adaptada para 16:9 (`qa.py`) |
| Vertical 9:16, só inglês, sem legendas | Trocado por 16:9, português e balões de texto |

### Passo a passo para refazer o trailer

Precisa de Godot 4.7, Node 20+, Python 3 com `pillow numpy scipy` (`py -m pip install pillow numpy scipy`).

1. **Gravar as cenas do jogo** (na pasta do projeto do jogo). O script `_gravacao.gd` joga sozinho e marca os
   momentos em `video/gravacoes/<cena>/marcas.json`. Para gravar em 1080p, crie um `override.cfg` temporário
   com o conteúdo abaixo e apague depois:
   ```
   [display]
   window/size/window_width_override=1920
   window/size/window_height_override=1080
   ```
   ```bash
   Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --write-movie video/gravacoes/fase1/f.png res://_gravacao.tscn -- --cena=fase1
   ```
   Cenas: `menu historia fase1 queda dano montagem fase3 fase5 final`.
2. **Converter para MP4** (na pasta `video/`):
   ```bash
   npx remotion ffmpeg -framerate 30 -i gravacoes/fase1/f%08d.png -c:v libx264 -crf 12 -pix_fmt yuv420p public/clipes/fase1.mp4
   ```
3. **Retrato do Léo:** `py tools/gerar_retrato.py` (na pasta do jogo) → `video/public/leo/`.
4. **Trilha:** `py audio/mixar.py` → `public/audio/mix.wav`. Usa o mesmo `src/roteiro.json` da imagem.
5. **Renderizar:** `npm install` e depois
   ```bash
   npx remotion render src/index.ts LeoTrailer out/leo-na-amazonia.mp4 --codec h264 --crf 16 --audio-codec aac
   ```
   Para ajustar olhando o resultado na hora: `npm run studio`.
6. **Checar:** `py qa.py out/leo-na-amazonia.mp4 out/qa_final`.

Para mudar uma fala ou o tempo de uma cena, edite `src/roteiro.json` e refaça os passos 4 e 5.

## Créditos
- Jogo, arte e roteiro: projeto Léo na Amazônia.
- Skill claude-animated-shorts (mromidev) — MIT, ver `audio/LICENSE-claude-animated-shorts.txt`.
- Remotion (licença Remotion: gratuita para indivíduos, estudantes e equipes pequenas).
- Fonte Baloo 2 (SIL Open Font License) via @fontsource.
