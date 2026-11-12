# VesperaFX (módulos usados no jogo)

Shaders de pós-processamento para Godot 4, criados por **devkcud**.

- Repositório original: <https://github.com/devkcud/VesperaFX>
- Versão copiada: commit `048e40611f5d710f653130c68c5613a164f6f564`
- Licença: **Mozilla Public License 2.0** (ver `LICENSE.txt` nesta pasta)

Usamos só quatro módulos, **sem modificação**:

| Arquivo | Para que usamos |
|---|---|
| `include/crt.gdshaderinc` | Vinheta (sempre ligada, leve) e linhas de TV / curvatura do modo retrô |
| `include/pixelation.gdshaderinc` | Transição pixelada entre telas e fases |
| `include/rendering.gdshaderinc` | Saturação e contraste do cenário |
| `include/utils.gdshaderinc` | Constantes usadas pelo `rendering.gdshaderinc` |

Os shaders que combinam esses módulos são do nosso projeto: `shaders/ambiente.gdshader` e `shaders/tela.gdshader`.
Se algum arquivo desta pasta for alterado, a MPL 2.0 pede que a versão alterada desse arquivo continue disponível
sob a mesma licença.
