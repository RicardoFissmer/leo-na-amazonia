# Léo na Amazônia

Jogo de plataforma 2D educativo feito no Godot 4. O Léo anda pela selva e coleta letras para formar palavras sobre a Amazônia.

## Como abrir

1. Baixe o **Godot 4.5 ou mais novo** (versão padrão, não a .NET) em https://godotengine.org/download
2. Descompacte e abra o executável (não precisa instalar).
3. No gerenciador de projetos, clique em **Importar**, escolha o arquivo `project.godot` desta pasta e confirme.
4. Com o projeto aberto, aperte **F5** para jogar.

Na primeira vez o Godot importa as imagens e cria a pasta `.godot/`. Isso é normal.

## Controles

| Tecla | Ação |
|---|---|
| ← → ou A D | andar |
| Espaço, ↑ ou W | pular (segure para pular mais alto) |
| Enter | escolher no menu / próxima fase |
| Esc | voltar ao menu |
| M | liga/desliga o som |

## Regras

- Cada fase tem uma palavra escondida e uma dica no topo da tela.
- As letras da palavra estão espalhadas **fora de ordem**. Cada letra certa vale +10 pontos e letras erradas tiram 5.
- Depois de pegar todas, aparece a imagem do animal e o jogador **monta a palavra na ordem certa**
  (clicando nas letras ou usando setas + Enter; Backspace desfaz). Acertar de primeira vale +50.
- Encostar na onça ou cair no rio/buraco tira uma vida. Sem vidas, a fase recomeça.
- Ao montar a palavra aparece uma curiosidade sobre o animal.

## Estrutura

```
assets/          imagens em pixel art (Léo, onça, arara, letras, chão, fundos)
assets/animais/  imagens dos animais (64×48) usadas na tela de montar a palavra
sons/            música da selva (musica.ogg) e efeitos sonoros (.wav)
scenes/main.tscn cena principal
scripts/
  main.gd        tela inicial, monta a fase a partir do MAPA e aplica as regras
  titulo.gd      tela inicial (Jogar, Como jogar, Sair)
  montagem.gd    tela de montar a palavra com a imagem do animal
  audio.gd       música e efeitos sonoros
  player.gd      movimento e pulo do Léo
  letra.gd       letra coletável
  onca.gd        onça que patrulha o chão
  arara.gd       arara voando (enfeite)
  hud.gd         palavra, dica, vidas, pontos e painel de fim de fase
  util.gd        funções de apoio
```

## Como mudar o jogo

- **Novas palavras:** edite a lista `PALAVRAS` no começo de `scripts/main.gd` (até 6 letras) e coloque uma imagem 64×48 em `assets/animais/`.
- **Mudar a fase:** edite o `MAPA` em `scripts/main.gd`. Cada caractere é um bloco de 16×16 px:
  `#` chão, `~` água, `=` plataforma, `P` início, `O` onça, `1`–`6` letras da palavra, `x` letra errada.
- **Ajustar o pulo e a velocidade:** constantes no topo de `scripts/player.gd`.
- **Trocar sons:** substitua os arquivos em `sons/` mantendo o mesmo nome. O volume fica em `scripts/audio.gd`.
