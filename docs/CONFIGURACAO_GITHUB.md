# Configuração do GitHub — passo a passo

Guia das configurações que **não ficam em arquivos** do repositório e precisam ser feitas na interface do GitHub
(Settings). Elas completam o [Plano de GCS](PLANO_GCS.md).

- Repositório: <https://github.com/RicardoFissmer/leo-na-amazonia>
- Dono / gerente de configuração / revisor: **@RicardoFissmer** (projeto individual)

> **Ordem recomendada:** 1 → 5 → 4 → 3. O CI já rodou no Pull Request #1, então o status check `validar-godot`
> já aparece na busca do passo 3.

---

## 1. Repositório público

**Por quê:** o professor precisa acessar, e no plano gratuito do GitHub os *required reviewers* de environments só
funcionam em repositórios públicos.

1. Abra o repositório → **Settings** (engrenagem, no menu de cima).
2. Em **General**, role até **Danger Zone** → **Change repository visibility**.
3. Confirme que está **Public**. *(Este repositório já está público; só confira.)*

## 2. Colaborador revisor — não aplicado

O projeto é individual, então **não há colaborador revisor** e a regra da `main` exige **0 aprovações**
(ver [Plano de GCS, seção 2](PLANO_GCS.md#2-papéis-e-responsabilidades)). Se um dia houver um revisor:

1. **Settings** → **Collaborators** → **Add people** → usuário da pessoa → ela aceita o convite
   (em repositório de conta pessoal, todo colaborador recebe escrita).
2. **Settings** → **Rules** → **Rulesets** → `proteger-main` → *Required approvals* de `0` para `1`.

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
     - **Required approvals:** `0` — o GitHub não deixa o autor aprovar o próprio PR; com `1` e sem outro
       colaborador, nenhum PR entraria. O Pull Request continua **obrigatório**.
     - [ ] **Require review from Code Owners** — **deixe desmarcado** (pelo mesmo motivo).
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
