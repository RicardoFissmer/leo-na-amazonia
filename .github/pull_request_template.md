## O que mudou

<!-- Descreva a mudança em poucas linhas. Ex.: "A piranha agora espera 2 s entre os pulos na fase 1." -->

## Issue relacionada

<!-- Ex.: Closes #12. Toda mudança começa por uma issue (ver docs/PLANO_GCS.md, seção 6). -->
Closes #

## Tipo de mudança

- [ ] `feat` — funcionalidade nova no jogo
- [ ] `fix` — correção de bug
- [ ] `docs` — documentação (README, GDD, plano de GCS)
- [ ] `ci` / `chore` — workflows, configuração, ferramentas

## Como testar

<!-- Passos para conferir a mudança. Ex.: "Abra no Godot 4.7, F5, jogue a fase 1 até o rio." -->
1.
2.

O build Web deste PR fica no artifact **jogo-web-pr-NÚMERO** da execução do CI (aba *Checks*).

## Checklist

- [ ] Testei no Godot 4.7 (F5) e o jogo abre sem erros no console
- [ ] Não movi nem renomeei cenas, scripts ou assets (o Godot usa caminhos `res://`)
- [ ] Os commits seguem o padrão Conventional Commits (`feat:`, `fix:`, `docs:`...)
- [ ] O nome da branch segue o padrão (`feature/`, `fix/`, `hotfix/`, `docs/`, `chore/`)
- [ ] Atualizei a documentação, se a mudança afeta como jogar ou como contribuir
- [ ] O CI (`validar-godot`) passou
