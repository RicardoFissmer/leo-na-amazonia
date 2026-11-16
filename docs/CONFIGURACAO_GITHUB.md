# Configuração do GitHub — passo a passo

Guia das configurações que **não ficam em arquivos** do repositório e precisam ser feitas na interface do GitHub
(Settings). Elas completam o [Plano de GCS](PLANO_GCS.md).

- Repositório: <https://github.com/RicardoFissmer/leo-na-amazonia>
- Dono / gerente de configuração: **@RicardoFissmer**
- Revisor (par de revisão): **@BryanBellinaso**

> **Ordem recomendada:** 1 → 5 → 4 → 3. O CI já rodou no Pull Request #1, então o status check `validar-godot`
> já aparece na busca do passo 3.

---

## 1. Repositório público

**Por quê:** o professor precisa acessar, e no plano gratuito do GitHub os *required reviewers* de environments só
funcionam em repositórios públicos.

1. Abra o repositório → **Settings** (engrenagem, no menu de cima).
2. Em **General**, role até **Danger Zone** → **Change repository visibility**.
3. Confirme que está **Public**. *(Este repositório já está público; só confira.)*

## 2. Colaborador revisor com acesso de escrita

**Por quê:** o Bryan é o par de revisão. Ele precisa de escrita para ser um revisor que conta para a regra de
aprovação da `main`.

1. **Settings** → **Collaborators** (seção *Access*) → **Add people** → `BryanBellinaso` → **Add to repository**.
2. O Bryan recebe o convite por e-mail/notificação e **aceita** em
   <https://github.com/RicardoFissmer/leo-na-amazonia/invitations>.
3. Depois de aceito, ele aparece na lista como colaborador. Em repositório de conta pessoal, todo colaborador tem
   **escrita** (*Write*): pode criar branches, fazer push nelas e revisar PRs.

## 3. Proteção da `main` (Ruleset)

**Por quê:** garante que nada entra na `main` sem Pull Request e CI verde — nem o próprio dono. É isso que gera a
evidência do push recusado.

1. **Settings** → **Rules** → **Rulesets** → **New ruleset** → **New branch ruleset**.
2. **Ruleset name:** `proteger-main`.
3. **Enforcement status:** **Active**.
4. **Bypass list:** **deixe vazia** (não adicione *Repository admin* nem ninguém).
   Sem bypass, o seu push como dono também é recusado — e é exatamente isso que queremos para a evidência.
5. **Target branches** → **Add target** → **Include default branch** (a `main`).
6. Em **Branch rules**, marque:
   - [x] **Restrict deletions** — ninguém apaga a `main`.
   - [x] **Require a pull request before merging**
     - **Required approvals:** `1` (a aprovação do Bryan)
     - [x] **Dismiss stale pull request approvals when new commits are pushed** — se o código mudar depois da
       aprovação, o Bryan precisa aprovar de novo.
     - [ ] **Require review from Code Owners** — **deixe desmarcado** (o CODEOWNERS só tem você, e você não pode
       aprovar o próprio PR).
   - [x] **Require status checks to pass**
     - **Add checks** → digite **`validar-godot`** e selecione.
     - [x] **Require branches to be up to date before merging** (opcional, recomendado).
   - [x] **Block force pushes**
7. **Create**.

> **Dica sobre o status check:** se `validar-godot` não aparecer na busca, digite o nome inteiro e confira se o
> Pull Request #1 já mostra o check **CI / validar-godot** com sucesso (ele já rodou uma vez).

## 4. Environments `staging` e `production`

**Por quê:** separam "versão para testar" de "versão publicada para os jogadores". O `production` só avança com a
sua aprovação.

### `staging`
1. **Settings** → **Environments** → **New environment** → nome `staging` → **Configure environment**.
2. **Deployment branches and tags** → **Selected branches and tags** → **Add deployment branch or tag rule** →
   `main` → **Add rule**.
3. Não precisa de revisores. **Save protection rules** (se o botão aparecer).

### `production`
1. **New environment** → `production` → **Configure environment**.
2. [x] **Required reviewers** → adicione **RicardoFissmer**.
3. [ ] **Prevent self-review** → **deixe desmarcado.** Essa opção impede que quem *disparou* o deploy aprove o
   próprio deploy. Aqui quem dispara é você (o merge na `main` é feito por você) e o único revisor obrigatório
   também é você. Com a opção marcada, o deploy de `production` ficaria esperando para sempre.
4. **Deployment branches and tags** → **Selected branches and tags** → regra `main`.
5. **Save protection rules**.

> O environment **`github-pages`** é criado sozinho pelo GitHub no passo 5. Ele é usado só pelo job que publica no
> Pages, que roda **depois** da sua aprovação em `production`. Confira em **Settings → Environments → github-pages**
> se a regra de branch está como `main`.

## 5. GitHub Pages

1. **Settings** → **Pages**.
2. **Build and deployment** → **Source:** **GitHub Actions**.
3. Não precisa escolher tema nem branch. O endereço do jogo vai ser
   **<https://ricardofissmer.github.io/leo-na-amazonia/>** depois do primeiro deploy aprovado.

## 6. Como aprovar um deploy de `production`

1. Depois do merge na `main`, abra a aba **Actions** → workflow **Deploy** → a execução mais recente.
2. O job `staging` termina e o resumo mostra o link do **artifact** com o build Web para testar.
3. Aparece a faixa amarela **"Waiting for review — This workflow is waiting for approval to deploy to production"**.
4. Clique em **Review deployments** → marque **production** → (opcional) escreva um comentário → **Approve and deploy**.
5. O job `publicar-pages` roda e, ao terminar, mostra o endereço do jogo.
6. Para ver o histórico: aba **Code** → painel da direita **Deployments**, ou
   <https://github.com/RicardoFissmer/leo-na-amazonia/deployments>.

Você também recebe um e-mail/notificação do GitHub pedindo a aprovação.
