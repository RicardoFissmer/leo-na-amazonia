# GDD — Léo na Amazônia

**Documento de Design do Jogo**
Versão do documento: 1.6 — atualizado em 12/11/2026
Versão do jogo descrita: 1.6 (Godot 4.7.2)

---

## Sumário

1. [Visão geral](#1-visão-geral)
2. [Público-alvo e objetivos pedagógicos](#2-público-alvo-e-objetivos-pedagógicos)
3. [Pilares de design](#3-pilares-de-design)
4. [Fluxo do jogo](#4-fluxo-do-jogo)
5. [Mecânicas](#5-mecânicas)
6. [Personagens e perigos](#6-personagens-e-perigos)
7. [Conteúdo: fases, palavras e perguntas](#7-conteúdo-fases-palavras-e-perguntas)
8. [Design de fase](#8-design-de-fase)
9. [Pontuação, vidas e progressão](#9-pontuação-vidas-e-progressão)
10. [Interface (UI/HUD)](#10-interface-uihud)
11. [Controles](#11-controles)
12. [Arte](#12-arte)
13. [Áudio](#13-áudio)
14. [Tecnologia e arquitetura](#14-tecnologia-e-arquitetura)
15. [Limitações conhecidas](#15-limitações-conhecidas)
16. [Próximos passos (roadmap)](#16-próximos-passos-roadmap)
17. [Histórico de versões](#17-histórico-de-versões)

---

## 1. Visão geral

| | |
|---|---|
| **Título** | Léo na Amazônia |
| **Gênero** | Plataforma 2D + quebra-cabeça de palavras + quiz educativo |
| **Plataforma** | PC (Windows). O código-fonte roda em qualquer sistema com Godot 4.7 |
| **Engine** | Godot Engine 4.7.2 (GDScript) |
| **Modo de jogo** | Um jogador |
| **Duração de uma partida** | Cerca de 10 a 15 minutos (5 fases) |
| **Idioma** | Português do Brasil |

**Resumo (*elevator pitch*):** o Léo, um menino brasileiro, explora a floresta amazônica pulando
entre troncos e desviando de onças, cobras e piranhas. No caminho ele coleta letras fora de ordem.
Com elas, o jogador monta o nome de um animal da Amazônia, descobre uma curiosidade sobre ele e
responde a um desafio de Verdadeiro ou Falso. Aprender a escrever o nome do bicho é a recompensa de
cada fase.

---

### História (sinopse)

O Léo adora o **Livro da Floresta** da vovó Lúcia: cada página mostra um animal da Amazônia e o nome dele.
Numa tarde, uma ventania arranca as letras do livro e espalha tudo pela mata, e os animais ficam sem nome.
O Léo entra na floresta para recuperar as letras e devolver o nome de cada animal.

| Elemento | No jogo |
|---|---|
| **Personagem e desejo** | O Léo quer consertar o livro da avó e devolver o nome aos animais |
| **Conflito** | As letras estão espalhadas e fora de ordem, no meio de onças, cobras, piranhas, rios e buracos |
| **Consequência** | Cada palavra montada "volta para o livro" ("Muito bem! O nome voltou para o livro!"). Ao final das 5 fases, o livro está completo e a vovó agradece |

A história aparece em 3 telas antes da fase 1 e em 2 telas depois da fase 5 (com a pontuação final).
O texto é mostrado aos poucos e pode ser pulado com Esc.

---

## 2. Público-alvo e objetivos pedagógicos

**Público-alvo:** crianças em fase de alfabetização e começo do ensino fundamental (aproximadamente
6 a 10 anos), que já reconhecem as letras e estão aprendendo a formar palavras.

**Objetivos pedagógicos:**

- **Consciência fonológica e ortografia:** reconhecer as letras de uma palavra e colocá-las na ordem certa.
- **Leitura de pistas:** usar a dica escrita ("O golfinho dos rios") para descobrir a palavra.
- **Leitura e compreensão:** ler afirmações curtas e julgar se são verdadeiras ou falsas.
- **Conhecimento sobre a fauna amazônica:** cada animal traz uma curiosidade e 5 afirmações com explicação.
- **Aprender com o erro:** o erro nunca encerra o jogo. As letras certas ficam marcadas na montagem e
  toda resposta do quiz vem com explicação.

---

## 3. Pilares de design

1. **Aprender brincando:** o conteúdo educativo é a recompensa da fase, não uma interrupção.
2. **Erro sem punição pesada:** não existe *game over*. Perder as vidas só recomeça a fase atual.
3. **Perigos sempre avisam antes:** a cobra treme e a piranha solta bolhas antes de atacar, para a
   criança aprender o padrão.
4. **Simples de ler:** pouca informação na tela, letras grandes nas telas de desafio, cores fortes.
5. **Fácil de expandir:** palavras, perguntas e o mapa ficam em listas de texto que qualquer pessoa consegue editar.

---

## 4. Fluxo do jogo

```
 Tela inicial ──► História (3 telas) ──► Fase N ──────────────────────┐
  (Jogar /                                │                           │
   Como jogar /    (fase 1: tutorial) ────├─ 1. Plataforma: coletar todas as letras
   Sair)                                  │      └─ perdeu as 3 vidas? → recomeça a fase N
     ▲                                    ├─ 2. Montar a palavra + curiosidade
     │                                    ├─ 3. Verdadeiro ou Falso (3 afirmações)
     │                                    └─ Enter ─► N < 5 ? Fase N+1 : Final (2 telas)
     │                                                                │
     └──────────── Esc (a qualquer momento) / fim do Final ◄──────────┘
```

**Fluxo da primeira partida e onde o jogador pode travar:**

| Momento | Ação esperada | Retorno ao jogador | Onde pode travar |
|---|---|---|---|
| Entrada | Ler a história e entender a missão | Telas com imagem e texto que aparece aos poucos | Criança que ainda não lê com fluência (a narração em áudio ainda não existe) |
| Aprendizado | Andar, pegar a primeira letra, pular | Dicas do tutorial, uma de cada vez, que somem quando a ação é feita | Não perceber a dica no alto da tela |
| Desafio | Passar por buraco, onça, piranha e cobra | Aviso antes do perigo (tremor, bolhas); na parte do tutorial, errar não tira vida | Pular cedo demais sobre o rio |
| Conclusão | Montar a palavra e responder o quiz | Letras verdes/vermelhas, explicação de cada resposta, curiosidade | Não reconhecer a palavra pela dica |

---

## 5. Mecânicas

### 5.1 Movimento do Léo

| Parâmetro | Valor | Observação |
|---|---|---|
| Velocidade horizontal | 90 px/s | |
| Força do pulo | 265 px/s | Altura máxima de cerca de 3 blocos (≈ 50 px) |
| Gravidade | 700 px/s² | |
| Velocidade máxima de queda | 400 px/s | |
| *Coyote time* | 0,1 s | Ainda dá para pular logo depois de sair da beirada |
| Pulo variável | — | Soltar o botão cedo corta a subida (pulo baixo) |
| Invencibilidade após dano | 1,2 s | O Léo pisca e é empurrado para trás |
| *Jump buffer* | 0,12 s | Apertar o pulo um pouco antes de tocar o chão também vale |
| Esticar e achatar | — | O corpo estica no pulo (0,8 × 1,2) e achata ao aterrissar, voltando ao normal aos poucos |
| Poeira | — | Nuvenzinha nos pés ao pular, ao aterrissar (maior se a queda foi alta) e enquanto corre |

### 5.2 Coleta de letras

- Cada fase espalha as letras da palavra pelo mapa em posições fixas (`1` a `8` no mapa).
  A ordem é embaralhada com uma semente fixa por fase, então a fase é sempre igual, mas as letras
  nunca ficam na ordem certa.
- Posições `x` geram **letras erradas** (sorteadas entre as que não existem na palavra).
- Letras com acento ou cedilha (como o **Ç** de ONÇA) aparecem do jeito que são escritas.

### 5.3 Montar a palavra

- As letras aparecem na ordem em que foram coletadas. Se por acaso já estiverem na ordem certa, são embaralhadas de novo.
- O jogador preenche os espaços da esquerda para a direita. Clicar num espaço preenchido ou apertar Backspace desfaz.
- Com todos os espaços preenchidos, o jogo confere: letras certas ficam **verdes e travadas**, as erradas
  ficam vermelhas por 1 segundo e voltam para baixo.

### 5.4 Verdadeiro ou Falso

- Cada animal tem 5 afirmações. O jogo sorteia 3: uma verdadeira, uma falsa e uma qualquer, em ordem aleatória.
- Depois da resposta, os botões travam, a resposta correta fica destacada e aparece uma explicação curta.
- Os botões só aceitam resposta 0,25 s depois de aparecerem, para o Enter da tela anterior não
  responder a pergunta sem querer.

### 5.5 Tutorial da fase 1

Segue três ideias: **uma ação por vez**, **tentativa segura** e **retorno perceptível**.

- As dicas aparecem num quadro com borda piscando, logo abaixo da dica do animal, quando o Léo chega a certa coluna do mapa.
  Cada dica some quando o jogador faz a ação (anda, pega a letra, pula, passa do obstáculo).
- Sequência: andar → pegar a moeda com letra → onde as letras aparecem → pular → buraco → onça → piranha → cobra → "Agora é com você!".
- Até a coluna 38 do mapa, errar **não tira vida**. Ao cair, o Léo volta para logo antes do obstáculo da dica atual
  e aparece "Tudo bem! Tente de novo.".
- Concluir uma dica toca um som curto de confirmação.
- Se o jogador passar da parte do tutorial e depois perder as 3 vidas, a fase 1 recomeça sem repetir as dicas.

### 5.6 Tempo de leitura

Como o público está aprendendo a ler, as mensagens ficam mais tempo na tela: 2,5 s por padrão, 3 s para "letra errada"
e 3,5 s para o nome da fase com a dica. As telas de história, montagem e quiz esperam o jogador apertar Enter.

---

## 6. Personagens e perigos

| | Descrição | Comportamento |
|---|---|---|
| **Léo** (protagonista) | Menino brasileiro de camiseta amarela e short verde | Anda, pula, coleta letras |
| **Vovó Lúcia** | Avó do Léo, dona do Livro da Floresta | Aparece só na história (citada no começo e no final) |
| **Onça-pintada** | Inimigo terrestre | Patrulha o trecho de chão onde está, sem cair nos buracos. Velocidade: 28 px/s |
| **Cobra** | Inimigo suspenso | Fica escondida dentro de um tronco (1,8 s), treme como aviso (0,6 s), desce rápido até a altura do Léo (0,2 s), fica embaixo (1 s) e sobe (0,7 s). Só machuca quando está para fora |
| **Piranha** | Inimigo aquático | Espera de 1,4 a 2,4 s, solta bolhas como aviso (0,6 s) e pula cerca de 3,5 blocos para fora do rio, girando o corpo, com respingos |
| **Arara** (enfeite) | Voa no céu, ao fundo | Sem interação |
| **Animais das fases** | Arara, onça, boto, tucano, capivara | Aparecem como ilustração nas telas de desafio |

---

## 7. Conteúdo: fases, palavras e perguntas

| Fase | Palavra | Dica | Curiosidade exibida |
|---|---|---|---|
| 1 | **ARARA** | Ave colorida de bico forte | A arara usa o bico forte para quebrar castanhas e sementes bem duras. |
| 2 | **ONÇA** | O maior felino das Américas | A onça-pintada é o maior felino das Américas e é uma ótima nadadora. |
| 3 | **BOTO** | O golfinho dos rios | O boto-cor-de-rosa vive nos rios da Amazônia e usa sons para se localizar na água. |
| 4 | **TUCANO** | Ave de bico enorme | O bico do tucano é grande, mas leve, e ajuda a controlar a temperatura do corpo. |
| 5 | **CAPIVARA** | O maior roedor do mundo | A capivara é o maior roedor do mundo. Ela nada muito bem e adora ficar na água. |

**Afirmações do Verdadeiro ou Falso** (V = verdadeira, F = falsa):

| Animal | Afirmações |
|---|---|
| Arara | V: Consegue quebrar castanhas duras com o bico · F: Só come carne · V: Os casais ficam juntos por muitos anos · F: Não consegue voar · V: Come barro dos barrancos dos rios |
| Onça | V: É o maior felino das Américas · V: Sabe nadar · F: Todas têm as pintas iguais · F: Vive em bandos, como os leões · F: Vive na África |
| Boto | V: É um golfinho de rio · F: Vive no mar · V: Usa sons para encontrar comida · F: É um peixe · V: Precisa subir à superfície para respirar |
| Tucano | V: O bico é grande, mas leve · F: Não voa por causa do bico · V: Espalha sementes pela floresta · F: Dorme no chão · V: O bico ajuda a se refrescar |
| Capivara | V: É o maior roedor do mundo · F: Não sabe nadar · V: Come plantas · F: Vive sempre sozinha · V: Fica alguns minutos embaixo d'água |

O texto completo de cada afirmação e das explicações está na lista `PALAVRAS` em `scripts/main.gd`.

---

## 8. Design de fase

A fase tem 80 × 12 blocos de 16 × 16 px (1280 × 192 px). A câmera segue o Léo e mostra 20 × 11 blocos por vez.
O mapa é definido como texto em `scripts/main.gd`:

```
................................................................................
................................................................................
................................................................................
.......................................4........................................
................................................................................
.........2............................===..............................6........
...................7...........................x................................
........===..................3....===...............===...............===.......
..P...1..............x..O....F.....C...................O.5.....F...x....C....8..
##############..############~~~###############...############~~~################
##############..############~~~###############...############~~~################
##############..############~~~###############...############~~~################
```

| Símbolo | Significado |
|---|---|
| `#` | Chão (grama em cima, terra embaixo) |
| `~` | Rio (cair tira uma vida e volta ao início) |
| `=` | Tronco/plataforma (dá para atravessar por baixo e subir em cima) |
| `P` | Início do Léo |
| `O` | Onça (patrulha o chão logo abaixo) |
| `C` | Cobra (pendurada no tronco logo acima) |
| `F` | Piranha (mora no rio logo abaixo) |
| `1`–`8` | Posições das letras da palavra |
| `x` | Letra errada (distração) |
| `.` | Vazio |

**Ritmo da fase (da esquerda para a direita):** começo tranquilo, com a primeira letra no chão e uma
plataforma → primeiro buraco → onça → rio com piranha, com uma letra bem em cima dela (exige esperar a
hora certa) → cobra embaixo de tronco → letra alta que exige subir nas plataformas → buraco largo →
segunda onça → segundo rio com piranha → segunda cobra → fim do mapa.

Palavras com menos de 8 letras simplesmente não usam as últimas posições.

---

## 9. Pontuação, vidas e progressão

| Evento | Efeito |
|---|---|
| Letra certa | +10 pontos |
| Letra errada | −5 pontos (mínimo 0) |
| Montar a palavra | +50 na 1ª tentativa, −15 a cada tentativa extra (mínimo +10) |
| Acerto no Verdadeiro ou Falso | +20 por afirmação (máximo +60 por fase) |
| Encostar num inimigo | −1 vida, empurrão e 1,2 s de invencibilidade |
| Cair no rio/buraco | −1 vida e volta ao início da fase |
| Perder as 3 vidas | A fase recomeça (letras e vidas restauradas, pontos mantidos) |
| Completar a fase | Libera a próxima. As vidas voltam a 3 |
| Completar a fase 5 | Fim do jogo, com volta à tela inicial |

Pontuação máxima teórica por fase: letras (10 × nº de letras) + 50 + 60.
Exemplo para a ARARA: 50 + 50 + 60 = 160.

---

## 10. Interface (UI/HUD)

- **Tela inicial:** logo em pixel art (o mesmo da capa) que balança e solta brilhos; placas de madeira
  *Jogar*, *Como jogar*, *Modo retrô* e *Sair*; a cabeça do Léo marca o botão selecionado e o botão "pula" ao
  ser escolhido. Ao fundo, a mata anda sozinha: o Léo corre e pula para pegar as letras de "AMAZONIA", a onça
  corre atrás, há vaga-lumes e folhas caindo. Versão do jogo no canto.
- **HUD na fase:** letras coletadas e espaços vazios (`_`) no canto superior esquerdo, dica logo abaixo,
  corações e pontos no canto superior direito, e mensagens temporárias no centro.
- **Tela de montagem:** imagem do animal (96 × 72), dica, espaços da palavra e letras disponíveis.
- **Tela de Verdadeiro ou Falso:** imagem do animal, afirmação em letra grande, botões verde (VERDADEIRO)
  e vermelho (FALSO), explicação e botão *Próxima*. No fim, mostra o resumo de acertos.
- **Cores:** verde-escuro da floresta (#163d28) nos painéis, amarelo (#ffd21f) nos destaques,
  verde/vermelho para certo/errado.

---

## 11. Controles

| Ação | Teclado | Mouse |
|---|---|---|
| Andar | ← → ou A D | — |
| Pular (segurar = mais alto) | Espaço, ↑ ou W | — |
| Navegar em menus e desafios | Setas | Passar o mouse |
| Confirmar / avançar | Enter | Clique |
| Desfazer letra (montagem) | Backspace | Clique na letra colocada |
| Voltar ao menu | Esc | — |
| Ligar/desligar som | M | — |

---

## 12. Arte

- **Estilo:** pixel art, com contorno escuro, sombreamento em 3–4 tons e luz vindo de cima à esquerda.
- **Resolução interna:** 320 × 180 px, ampliada por um número inteiro de vezes (janela de 1280 × 720 por padrão)
  com filtro *nearest*, para os pixels ficarem nítidos.
- **Blocos:** 16 × 16 px. **Léo: 16 × 24 px, 13 quadros** — parado respirando (2) e piscando (1), corrida (6),
  pulo, queda, dano e comemoração; rosto em 3/4 com dois olhos, cabelo alto e cacheado, camisa amarela com gola
  verde e escudo azul, short verde e tênis azul. Onça: 20 × 9 px. Cobra: cabeça 10 × 10 + corpo
  que se repete. Piranha: 14 × 11 px (2 quadros).
- **Fundo:** três camadas com *parallax* (0,15 / 0,4 / 0,8 da velocidade da câmera). No menu, elas andam sozinhas.
- **Ilustrações dos animais:** 96 × 72 px, com cenário próprio (galho, mata, rio). São geradas pelo
  script `tools/gerar_arte.py` (Python + Pillow), que desenha formas sombreadas com contorno automático.
  As versões antigas (64 × 48) ficam em `tools/backup_animais_antigos/`.

---

### Efeitos de tela

| Efeito | Quando | Por quê |
|---|---|---|
| Vinheta leve + cor um pouco mais viva | Sempre, só no cenário (camada abaixo do HUD) | Dá clima de mata fechada sem afetar a leitura dos textos |
| Transição pixelada (a tela vira "pixelões" e escurece, ~0,5 s) | Ao abrir a história, começar a fase 1, trocar de fase, recomeçar a fase e voltar ao menu no final | Deixa claro que algo mudou e combina com o estilo pixel art |
| Modo retrô: linhas de TV antiga, tela levemente curva e vinheta | Opcional (tecla R ou botão no menu). Desligado por padrão e salvo em `user://config.cfg` | Diversão para quem gosta de visual retrô, sem prejudicar quem precisa de texto nítido |

Efeitos do VesperaFX **não usados** de propósito: ruído/rastreamento de VHS, distorção psicodélica, rastros
e redução de paleta com pontilhado. Eles reduzem a legibilidade, o que vai contra a prioridade de acessibilidade
para crianças em alfabetização.

---

## 13. Áudio

| Arquivo | Quando toca |
|---|---|
| `musica.ogg` | Música da selva, em loop, o tempo todo |
| `pulo.wav` | Ao pular (com pequena variação de tom) |
| `letra.wav` | Letra certa coletada / resposta certa no quiz |
| `erro.wav` | Letra errada / montagem errada / resposta errada |
| `dano.wav` | Encostar em um inimigo |
| `caiu.wav` | Cair no rio ou num buraco |
| `vitoria.wav` | Palavra montada / acertar todas do quiz |
| `menu.wav` | Mudar de botão nos menus / colocar letra |
| `comecar.wav` | Começar a partida / terminar o quiz sem gabaritar |

---

## 14. Tecnologia e arquitetura

- **Engine:** Godot 4.7.2, renderizador Forward+, GDScript, sem plugins.
- **Efeitos de tela:** `scripts/efeitos.gd` com shaders próprios (`shaders/ambiente.gdshader` e `shaders/tela.gdshader`) montados a partir de módulos do [VesperaFX](https://github.com/devkcud/VesperaFX) (devkcud, MPL-2.0), copiados sem modificação em `shaders/vesperafx/`.
- **Cena única:** `scenes/main.tscn` tem um só nó com `main.gd`. Todo o resto (sprites, colisões,
  interface, controles do teclado) é criado por código. Assim tudo fica visível em texto e fácil de versionar.
- **Comunicação por sinais:** o jogador emite `caiu`, `machucado(quem)` e `pulou`; a letra emite `coletada`;
  a montagem e o quiz emitem `concluido`; o título emite `jogar`. O `main.gd` escuta tudo e aplica as regras.
- **Dados:** palavras, dicas, curiosidades e perguntas ficam na constante `PALAVRAS`, e o mapa na constante `MAPA`.

```
main.gd
 ├─ Parallax2D ×3        fundo
 ├─ hud.gd               interface da fase
 ├─ audio.gd             música e efeitos
 ├─ titulo.gd            tela inicial
 ├─ montagem.gd          montar a palavra
 ├─ verdadeiro_falso.gd  quiz
 └─ mundo                recriado a cada fase
     ├─ player.gd, letra.gd
     └─ onca.gd, cobra.gd, piranha.gd, arara.gd
```

---

## 15. Limitações conhecidas

- O tutorial cobre movimento e perigos. A montagem e o quiz são explicados só pelo texto da tela.
- Ainda não houve testes com crianças do público-alvo.
- As 5 fases usam o mesmo mapa.
- Não há salvamento, recorde, menu de pausa nem controle de volume.
- Ao recomeçar a fase, os pontos já ganhos são mantidos e as letras podem ser coletadas de novo (falha conhecida).
- Só teclado e mouse. Não há gamepad nem toque.
- Executável apenas para Windows. Outros sistemas precisam abrir o projeto no Godot.

---

## 16. Próximos passos (roadmap)

| Prioridade | Item |
|---|---|
| Alta | Testar com crianças do público-alvo, registrar observações e ajustar |
| Alta | Narração em áudio da história, das dicas e das perguntas |
| Alta | Corrigir os pontos que se acumulam ao recomeçar a fase |
| Alta | Um mapa diferente para cada animal, com dificuldade crescente |
| Média | Novos desafios: "Quem sou eu?" (silhueta) e "Letra que falta" |
| Média | Checkpoint no meio da fase |
| Baixa | Recorde salvo, álbum de animais descobertos, mais animais (pirarucu, preguiça, sucuri) |
| Baixa | Suporte a gamepad e celular |

---

## 17. Histórico de versões

| Versão | Data | Mudanças |
|---|---|---|
| 1.0 | 16/09/2026 | Primeira versão jogável: plataforma, coleta de letras, montagem da palavra, 4 fases (arara, onça, boto, tucano), onça como inimigo, menu, som |
| 1.1 | 15/10/2026 | Novos inimigos: cobra e piranha. Nova fase: CAPIVARA (8 letras). Ilustrações dos animais refeitas em 96 × 72 |
| 1.2 | 17/10/2026 | Novo desafio: Verdadeiro ou Falso depois de montar a palavra. Texto do *Como jogar* atualizado |
| 1.3 | 29/10/2026 | Guia completo de instalação e uso no README, este GDD, executável único para Windows |
| 1.4 | 12/11/2026 | História do Livro da Floresta (telas de abertura e final), tutorial na fase 1 com tentativa segura, mensagens com mais tempo de leitura, capa do jogo |
| 1.5 | 12/11/2026 | Efeitos de tela com o VesperaFX: vinheta e cor no cenário, transição pixelada entre telas e modo retrô opcional (tecla R / menu) |
| 1.6 | 12/11/2026 | Léo redesenhado (16×24, 13 quadros, esticar/achatar, poeira, *jump buffer*), menu novo (logo, placas de madeira, cursor do Léo, cena viva) e vídeo de apresentação |
