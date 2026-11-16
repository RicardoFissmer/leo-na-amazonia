# Plano de Gestão de Configuração de Software (GCS) — Léo na Amazônia

| | |
|---|---|
| **Projeto** | Léo na Amazônia — jogo de plataforma 2D educativo (Godot 4.7) |
| **Repositório** | <https://github.com/RicardoFissmer/leo-na-amazonia> |
| **Disciplina** | Gerência, Configuração e Processos de Software — Prof. Luiz C. Camargo (Católica SC) |
| **Atividade** | N2-P2 — Execução do plano de Gestão de Configuração |
| **Autor / gerente de configuração** | Ricardo Fissmer Batista (@RicardoFissmer) |
| **Versão deste plano** | 1.1 — 16/11/2026 (inclui o par de revisão) |

> Este plano é ele mesmo um **item de configuração** (IC-17): fica versionado em `docs/PLANO_GCS.md` e só muda
> por Pull Request aprovado, como qualquer outro arquivo do jogo.

---

## 1. Introdução e objetivo

O jogo *Léo na Amazônia* já passou por várias versões (v1.3 a v1.6: tutorial, história, efeitos, novo personagem).
Até a v1.6, as mudanças iam direto para a `main`, sem revisão nem validação automática. Uma mudança errada em um
script ou em um caminho `res://` podia quebrar o jogo publicado sem ninguém perceber.

**Objetivo:** garantir que toda mudança no jogo seja **rastreável** (por que mudou, quem mudou, quem revisou),
**validada** (abre no Godot e exporta para Web) e **publicada de forma controlada** (teste em `staging`, aprovação
para `production`), com **versões identificáveis** (tags SemVer) que permitam voltar a qualquer estado aprovado.

**Escopo:** todo o conteúdo do repositório `RicardoFissmer/leo-na-amazonia` — código GDScript, cenas, shaders,
assets de arte e som, configuração do Godot, documentação, ferramentas de geração de arte, projeto do vídeo e os
workflows do GitHub Actions — e as configurações do repositório no GitHub (regras da `main`, environments, Pages).

**Fora do escopo:** os executáveis gerados (ficam nas Releases e no Pages, são reproduzíveis a partir de uma tag) e a
pasta `.godot/` (cache local do editor).

## 2. Papéis e responsabilidades

| Papel | Pessoa | Responsabilidades |
|---|---|---|
| **Dono do projeto** | Ricardo (@RicardoFissmer) | Decide o que entra no jogo, abre as issues, desenvolve nas branches. |
| **Gerente de configuração** | Ricardo (@RicardoFissmer) | Mantém este plano, as regras da `main`, os environments e os workflows; cria as tags de baseline e as Releases; faz o merge dos PRs aprovados. |
| **Revisor obrigatório de `production`** | Ricardo (@RicardoFissmer) | Testa o build de `staging` e aprova (ou rejeita) a publicação no GitHub Pages. |
| **Revisor de código (par de revisão)** | Bryan Bellinaso (@BryanBellinaso) | Colaborador com acesso de **escrita**. Revisa e aprova os Pull Requests para a `main` (1 aprovação obrigatória). |

**Por que o revisor dos PRs é o Bryan e não o dono:** o GitHub não deixa o autor aprovar o próprio Pull Request.
Como o projeto é individual, o Bryan é o "segundo par de olhos" que a regra da `main` exige: nenhum PR entra sem a
aprovação dele, além do CI verde.

**Histórico:** o PR #1 (implantação da GCS) entrou com 0 aprovações, porque ainda não havia revisor. Com a entrada
do Bryan, a regra passou a exigir **1 aprovação**, e a primeira mudança revisada por ele é o PR que incluiu este
papel no plano.

**CODEOWNERS:** o arquivo `.github/CODEOWNERS` tem só o Ricardo (`* @RicardoFissmer`), para o GitHub marcá-lo como
dono de tudo. O Bryan **não** foi incluído e a opção *Require review from Code Owners* fica **desligada**: ligada,
todo PR do Ricardo precisaria da aprovação do próprio Ricardo, o que o GitHub não permite — os PRs travariam. A
revisão do Bryan já é garantida pela regra de 1 aprovação.

## 3. Itens de configuração (ICs)

| ID | Item de configuração | Tipo | Local | Responsável |
|---|---|---|---|---|
| IC-01 | Scripts do jogo (16 arquivos: `main.gd`, `player.gd`, `onca.gd`, `cobra.gd`, `piranha.gd`, `tutorial.gd`, `historia.gd`, `titulo.gd`, `efeitos.gd`, ...) | Código-fonte GDScript | `scripts/*.gd` (+ `*.gd.uid`) | Ricardo |
| IC-02 | Cena principal | Cena Godot (`.tscn`) | `scenes/main.tscn` | Ricardo |
| IC-03 | Recursos `.tres` | Recurso Godot | *(nenhum hoje — tudo é criado por código; se surgir, entra aqui)* | Ricardo |
| IC-04 | Shaders próprios (vinheta, transição, modo retrô) | Código de shader | `shaders/*.gdshader` | Ricardo |
| IC-05 | Módulos de terceiros VesperaFX (MPL-2.0, sem modificação) | Código de terceiros | `shaders/vesperafx/` (+ `LICENSE.txt`, `LEIAME.md`) | Ricardo |
| IC-06 | Arte em pixel art (Léo, animais, cenário, interface) | Asset binário (PNG) + `.import` | `assets/`, `assets/animais/`, `assets/historia/`, `assets/ui/` | Ricardo |
| IC-07 | Música e efeitos sonoros | Asset binário (OGG/WAV) + `.import` | `sons/` | Ricardo |
| IC-08 | Configuração do projeto Godot (versão 4.7, cena principal, resolução 320×180) | Configuração | `project.godot` | Ricardo |
| IC-09 | Presets de exportação (Windows e Web sem threads) | Configuração | `export_presets.cfg` | Ricardo |
| IC-10 | Workflow de integração contínua | Configuração de CI | `.github/workflows/ci.yml` | Ricardo |
| IC-11 | Workflow de entrega (staging → production → Pages) | Configuração de CD | `.github/workflows/deploy.yml` | Ricardo |
| IC-12 | Templates de PR e de issues, CODEOWNERS | Configuração de colaboração | `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/`, `.github/CODEOWNERS` | Ricardo |
| IC-13 | Regras do Git | Configuração | `.gitignore`, `.gitattributes` | Ricardo |
| IC-14 | README (como abrir, jogar e contribuir) | Documentação | `README.md` | Ricardo |
| IC-15 | GDD — documento de design do jogo | Documentação | `docs/GDD.md` | Ricardo |
| IC-16 | Guia das configurações do GitHub | Documentação | `docs/CONFIGURACAO_GITHUB.md` | Ricardo |
| IC-17 | **Este Plano de GCS** | Documentação / processo | `docs/PLANO_GCS.md` | Ricardo |
| IC-18 | Geradores de arte (Léo, retrato, menu, animais, história, capa) | Ferramenta (Python) | `tools/*.py` | Ricardo |
| IC-19 | Capa do jogo | Asset binário | `capa/` | Ricardo |
| IC-20 | Projeto do vídeo de apresentação (roteiro, Remotion, trilha) | Código + mídia | `video/` | Ricardo |
| IC-21 | Configurações do repositório no GitHub (ruleset `proteger-main`, environments `staging`/`production`/`github-pages`, Pages, colaborador) | Configuração externa (fora de arquivos) | GitHub → *Settings* (documentadas no IC-16) | Ricardo |

**Não são ICs (não versionados):** `.godot/` (cache), `build/` (builds exportados), `video/node_modules/`,
`video/gravacoes/` e `video/out/` (arquivos gerados). Estão no `.gitignore`.

**Regra importante do Godot:** cenas, scripts e assets são referenciados pelo caminho `res://...`. Por isso, **mover
ou renomear um IC dos grupos IC-01 a IC-07 é uma mudança que exige issue própria e teste no editor**, porque
quebra referências.

## 4. Nomenclatura e padrões

### 4.1 Branches

| Prefixo | Uso | Exemplo neste jogo |
|---|---|---|
| `feature/` | Funcionalidade nova | `feature/fase-pirarucu` |
| `fix/` | Correção de bug encontrada antes de publicar | `fix/onca-atravessa-leo` |
| `hotfix/` | Correção urgente de algo já publicado em `production` | `hotfix/web-tela-preta` |
| `docs/` | Só documentação | `docs/atualiza-gdd-fase6` |
| `chore/` | Configuração, CI, ferramentas, manutenção | `chore/gcs-setup` |

Nomes em minúsculas, com hífens, curtos e ligados ao assunto da issue.

### 4.2 Commits — Conventional Commits

Formato: `tipo: descrição no imperativo, em português`.

| Tipo | Quando | Exemplo |
|---|---|---|
| `feat` | Algo novo no jogo | `feat: adiciona fase do pirarucu` |
| `fix` | Correção de bug | `fix: impede a onça de machucar o Léo durante a montagem` |
| `docs` | Documentação | `docs: explica o fluxo de aprovação no plano de GCS` |
| `ci` | Workflows | `ci: valida o projeto no Godot 4.7.2 em cada PR` |
| `chore` | Configuração, manutenção | `chore: adiciona preset de exportação Web` |
| `refactor` / `style` / `test` | Reorganização sem mudar comportamento, formatação, testes | `refactor: separa a lógica do tutorial em tutorial.gd` |

Mudança que quebra compatibilidade (ex.: save antigo deixa de funcionar) leva `!` — `feat!: ...` — e sobe o MAJOR.

### 4.3 Versões — SemVer `vMAJOR.MINOR.PATCH`

| Parte | Sobe quando | Exemplo no Léo na Amazônia |
|---|---|---|
| **MAJOR** | Muda o jogo de um jeito incompatível ou reformula a experiência | `v2.0.0`: novo mapa para cada fase e sistema de save que invalida o anterior |
| **MINOR** | Funcionalidade nova compatível | `v1.7.0`: versão Web publicada no GitHub Pages; `v1.8.0`: fase nova do pirarucu |
| **PATCH** | Só correção de bug | `v1.7.1`: a piranha passa a respeitar a tentativa segura do tutorial |

**Histórico:** as versões anteriores à gestão de configuração foram publicadas como `v1.3` a `v1.6` (formato curto).
A partir deste plano, as versões usam SemVer completo, continuando a numeração: a **primeira baseline é `v1.7.0`**.
A versão também aparece no canto da tela inicial do jogo (`VERSAO` em `scripts/titulo.gd`) e deve ser atualizada no
mesmo PR que prepara a release.

## 5. Estratégia de branching — GitHub Flow

```
main  ──●───────────●──────────────●─────────▶  (sempre estável; cada merge vira deploy)
         \         / \            /
          ●──●──●─●   ●──●───────●             branches curtas (feature/, fix/, docs/, chore/)
          chore/gcs-setup  feature/fase-pirarucu
```

- A **`main` é protegida e sempre estável**: só recebe código por Pull Request aprovado e com CI verde.
- Cada mudança nasce em uma **branch curta** a partir da `main` atualizada e morre no merge (a branch é apagada).
- Não há branch `develop` nem branches de release.

**Por que GitHub Flow e não Git Flow:** o projeto tem **uma pessoa desenvolvendo e um revisor**, entregas pequenas e
um único produto publicado (o jogo Web). O Git Flow (develop, release, hotfix em paralelo) traria cerimônia sem
benefício. A "estabilização" que o Git Flow faria em uma branch de release aqui é feita pelo environment `staging`,
e a decisão de publicar é feita pelo portão de aprovação de `production`.

## 6. Controle de mudanças

```
Issue ─▶ Branch ─▶ Commits ─▶ Pull Request ─▶ CI (validar-godot) ─▶ Revisão do Bryan ─▶ Merge ─▶ Deploy
  │                                                │                     │
  │                                                └─ falhou: corrige na └─ pediu alterações: novos commits
  │                                                   mesma branch          na mesma branch, CI roda de novo,
  │                                                                         aprovação anterior é descartada
  └─ toda mudança começa aqui (template de bug ou de funcionalidade)
```

1. **Issue** — o pedido de mudança. Usa o template de *Bug* ou de *Nova funcionalidade*, com critérios de aceite.
2. **Branch** — criada a partir da `main` com o prefixo certo (seção 4.1).
3. **Commits** — pequenos, no padrão Conventional Commits.
4. **Pull Request** para a `main` — usa o template (o que mudou, `Closes #N`, como testar, checklist).
5. **CI** — o workflow `CI` roda o job **`validar-godot`**: importa o projeto no Godot 4.7.2, roda a cena principal
   procurando erros de script e faz um export Web de teste. O build fica como artifact do PR para ser jogado.
   **Sem CI verde, o merge fica bloqueado.**
6. **Revisão** — o Ricardo marca o checklist do template e pede a revisão do **Bryan**, que lê o diff na aba
   *Files changed* e, se quiser, joga o build do artifact.
   - **Aprovou (*Approve*):** o PR fica pronto para merge.
   - **Pediu alterações (*Request changes*):** o Ricardo faz novos commits **na mesma branch**; o CI roda de novo
     e, como a regra descarta aprovações antigas quando chegam commits novos, o Bryan precisa **revisar e aprovar
     outra vez**. O PR só sai desse ciclo aprovado ou fechado (mudança rejeitada, issue fechada com justificativa).
7. **Merge** — feito pelo Ricardo (*Squash and merge* ou *Merge commit*), branch apagada.
8. **Deploy** — o merge dispara o workflow `Deploy` (seção 8).

A issue fecha sozinha no merge (`Closes #N`), ligando pedido → código → revisão → deploy.

## 7. Baselines e releases

**Baseline** = um estado do repositório aprovado e publicado, identificado por uma **tag anotada SemVer**.

- **Quando se cria:** a cada publicação **aprovada em `production`** e concluída no GitHub Pages. Nunca antes da
  aprovação — assim toda tag corresponde a algo que de fato foi para os jogadores.
- **Quem cria:** o gerente de configuração (Ricardo), no commit da `main` que foi publicado:
  ```bash
  git switch main && git pull
  git tag -a v1.7.0 -m "v1.7.0: versão Web no GitHub Pages + gestão de configuração"
  git push origin v1.7.0
  ```
- **O que a baseline contém:** o estado completo de todos os ICs versionados (IC-01 a IC-20) naquele commit — código,
  cenas, assets, configuração do Godot, presets de exportação, workflows e a documentação, incluindo esta versão do
  plano. O IC-21 (configurações do GitHub) é descrito no IC-16 da mesma tag.
- **Release no GitHub:** para cada baseline, uma Release com notas das mudanças (issues/PRs incluídos), o executável
  do Windows (`LeoNaAmazonia-windows.zip`) e o link da versão Web.
- **Voltar a uma baseline:** `git switch --detach v1.7.0` reproduz exatamente aquela versão; para republicar, roda-se o
  workflow `Deploy` manualmente a partir dela (ou um `hotfix/` a partir da tag).

**Primeira baseline:** `v1.7.0`, depois do merge do PR `chore/gcs-setup` e da aprovação do primeiro deploy.

## 8. Ambientes e entrega (CI/CD)

| Environment | O que é | O que dispara | Quem aprova | Regras |
|---|---|---|---|---|
| **`staging`** | Versão de **teste**: o build Web do commit, publicado como *artifact* baixável (link no resumo da execução). | Todo `push` na `main` (merge de PR) ou execução manual (`workflow_dispatch`) do workflow `Deploy`. | Ninguém (automático). | Só a branch `main`. |
| **`production`** | **Portão de aprovação** para a versão dos jogadores. | Termina o `staging` com sucesso. | **Ricardo (required reviewer).** | Só a branch `main`; *Prevent self-review* desligado (ver abaixo). |
| **`github-pages`** | A publicação em si, em <https://ricardofissmer.github.io/leo-na-amazonia/>. | Aprovação de `production`. | — (herda a aprovação anterior) | Criado pelo GitHub; só a `main`. |

**Fluxo do workflow `Deploy`:**
```
push na main ─▶ build (Godot 4.7.2 → Web) ─▶ staging (artifact + link) ─▶ production ⏸ aguarda aprovação
                                                                              │ Ricardo aprova
                                                                              ▼
                                                                       publicar-pages ─▶ jogo no ar
```

- **Por que dois jobs no final (`production` e `publicar-pages`):** a ação oficial de publicação do Pages exige o
  environment `github-pages`. O job `production` existe só para ser o **portão de aprovação**; o `publicar-pages`
  depende dele (`needs: production`), então nada é publicado sem a aprovação.
- **Prevent self-review desligado:** quem dispara o deploy é quem faz o merge (o Ricardo), e o único revisor
  obrigatório também é o Ricardo. Com a opção ligada, o GitHub impediria a aprovação e o deploy ficaria parado.
- **Permissões mínimas:** o workflow inteiro roda com `contents: read`; só o job `publicar-pages` recebe
  `pages: write` e `id-token: write`.
- **Export Web sem threads:** o GitHub Pages não envia os cabeçalhos de *cross-origin isolation* (COOP/COEP); por
  isso o preset Web usa `variant/thread_support=false` (template `web_nothreads` do Godot 4.3+).

## 9. Proteção da branch `main`

Configurada como **ruleset `proteger-main`** (Settings → Rules → Rulesets), alvo: branch padrão (`main`).

| Regra | Por quê |
|---|---|
| **Require a pull request before merging**, **1 aprovação** | Nenhuma linha entra sem passar pelo par de revisão (Bryan). |
| **Dismiss stale approvals** ao chegar commit novo | A aprovação vale para o código que foi revisado, não para o que veio depois. |
| **Require status checks to pass: `validar-godot`** | Garante que o jogo abre e exporta para Web antes de entrar na `main` (que vira deploy). |
| **Block force pushes** | Ninguém reescreve o histórico da `main` — a auditoria depende dele. |
| **Restrict deletions** | A `main` não pode ser apagada. |
| **Bypass list vazia** (nem administradores) | Vale para todos, inclusive o dono. É o que faz o `git push origin main` do próprio Ricardo ser **recusado** (evidência da seção 10). |
| *Require review from Code Owners* **desligado** | Ver seção 2: travaria todos os PRs do dono. |

## 10. Auditoria e evidências

### Como verificar o histórico

| O que auditar | Onde |
|---|---|
| Pedidos de mudança | Aba **Issues** (abertas/fechadas, ligadas aos PRs) |
| Quem mudou o quê e quem revisou | Aba **Pull requests** → *Closed* → cada PR mostra a issue, os commits, o CI e a aprovação do revisor |
| Validação automática | Aba **Actions** → workflow **CI** (logs do `validar-godot` de cada PR) |
| Deploys e aprovações | Aba **Actions** → workflow **Deploy** (quem aprovou `production` e quando) e a página **Deployments** (`/deployments`) com o histórico por environment |
| Baselines | `git tag -l "v*"` ou a página **Releases** / **Tags** |
| Histórico de um arquivo | `git log --follow -- caminho/do/arquivo` ou *History* na interface |
| Regras em vigor | **Settings → Rules → Rulesets → proteger-main** e **Settings → Environments** |

### Evidências da entrega N2-P2

- [ ] `docs/PLANO_GCS.md` publicado na `main` (via Pull Request)
- [ ] Repositório público
- [ ] Terminal com o `git push` direto na `main` **recusado** pelo GitHub
- [ ] Ruleset `proteger-main` configurado (print da tela de regras)
- [ ] PR `chore/gcs-setup` com CI verde e merge na `main`
- [ ] Bryan (@BryanBellinaso) como colaborador com escrita (print de Settings → Collaborators)
- [ ] PR `docs/par-revisao` revisado e aprovado pelo Bryan
- [ ] Environments `staging` e `production`, com Ricardo como *required reviewer*
- [ ] Execução do `Deploy` com `production` aguardando aprovação e depois aprovado
- [ ] Jogo publicado no GitHub Pages
- [ ] Tag `v1.7.0` (primeira baseline)

## 11. Ferramentas

| Ferramenta | Versão / detalhe | Uso |
|---|---|---|
| **Godot Engine** | 4.7.2 (stable, versão padrão — não .NET) | Desenvolvimento, validação e exportação do jogo |
| **Git** | 2.x | Controle de versão, branches, tags |
| **GitHub** | Repositório público, rulesets, environments, issues, PRs, Releases | Hospedagem e controle de mudanças |
| **GitHub Actions** | Runner `ubuntu-latest`, imagem `barichello/godot-ci:4.7.2`; ações `checkout@v7`, `upload-artifact@v7`, `upload-pages-artifact@v5`, `deploy-pages@v5` | CI (`ci.yml`) e CD (`deploy.yml`) |
| **GitHub Pages** | Fonte: GitHub Actions | Publicação da versão Web (`production`) |
| **Python 3 + Pillow** | Scripts em `tools/` | Geração da arte em pixel art (IC-18) |
| **Node + Remotion** | `video/` | Vídeo de apresentação (IC-20) |
