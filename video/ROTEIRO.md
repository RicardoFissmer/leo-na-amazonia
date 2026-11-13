# Vídeo de apresentação — Léo na Amazônia

- **Duração:** ~95 s · **Formato:** 1920×1080, 30 fps (16:9, para apresentar em sala e postar)
- **Objetivo:** apresentar o jogo e fazer quem vai jogar **se identificar com o Léo** e gostar dele.
- **Voz:** o Léo "fala" em primeira pessoa por **balões de fala** com som de "blip" a cada letra (estilo videogame).
  Não usamos narração gravada. Assim o vídeo funciona sem voz e lê bem em sala.
- **Produção:** skill *claude-animated-shorts* (Remotion), adaptada: mundo em pixel art do próprio jogo (no lugar do
  3D), português, 16:9, balões no lugar de voz-off. Mantidos da skill: fórmula de roteiro (gancho → cenário →
  escalada → virada → frase dupla → explicação → consequência → retorno), câmera com deslizes suaves (18–40 quadros),
  toda pausa com aproximação lenta, sacudidas de impacto que trocam de lado a cada quadro e somem em 7 quadros,
  flash branco depois do gancho, som sintetizado + mixagem com loudness, checagem quadro a quadro (QA).

## Por que o Léo cativa (o que o vídeo precisa mostrar)

| Traço | Como aparece |
|---|---|
| É uma criança como quem joga (9 anos) | Ele mesmo se apresenta, olhando para a câmera |
| Tem família e afeto | A vovó Lúcia e o Livro da Floresta |
| É corajoso, mas sente medo | "Confesso: morro de medo da onça!" |
| Erra e tenta de novo | Cai no rio → "Tudo bem! Tente de novo." → consegue |
| Ama a natureza e aprender | Monta o nome dos bichos e aprende curiosidades |
| Convida o jogador | "Você me ajuda?" / "Então vem comigo!" |

## Roteiro por cena

| # | Tempo | Beat (skill) | Imagem | Fala do Léo (balão) | Som |
|---|---|---|---|---|---|
| 1 | 0–6 s | Gancho | Preto → flash branco → close do Léo piscando | "Psiu! Você aí!" / "Oi! Eu sou o Léo!" | Blips, "pop" no flash |
| 2 | 6–14 s | Cenário | Léo na mata (parallax com desfoque no fundo) | "Tenho 9 anos e moro na Amazônia, na beira do rio." / "Adoro bicho, adoro correr..." | Música entra |
| 3 | 14–21 s | Cenário | Livro da Floresta (imagem do jogo, câmera desliza) | "...e adoro o Livro da Floresta da minha vó Lúcia!" | Brilhos |
| 4 | 21–27 s | Virada | Ventania: letras voando pela tela, sacudida | "Até que... FUUUU! Uma ventania levou todas as letras!" | Vento, sacudida |
| 5 | 27–34 s | Frase dupla | Léo determinado / onça aparece | "A boa notícia: as letras caíram na floresta." / "A má notícia: as letras caíram... NA FLORESTA." | Rosnado de brincadeira |
| 6 | 34–56 s | Escalada | Gameplay real: corre, pula, onça, piranha, cobra | "Então eu corro..." / "pulo..." / "desvio da onça..." / "fujo da piranha..." / "e da cobra também!" | Sons do jogo, sacudida em cada perigo |
| 7 | 56–63 s | Identificação | Léo cai no rio → "Tudo bem! Tente de novo." → consegue | "Às vezes eu caio..." / "...mas eu sempre tento de novo!" | Splash, "ufa" |
| 8 | 63–76 s | Explicação | Tela de montar ARARA + Verdadeiro ou Falso | "Com as letras, eu monto o nome do bicho..." / "...e aprendo um monte de coisa!" | Sons do jogo |
| 9 | 76–83 s | Consequência | Desfile dos 5 animais | "Arara, onça, boto, tucano, capivara... cada nome volta pro livro!" | Brilho a cada animal |
| 10 | 83–90 s | Retorno / convite | Close do Léo sorrindo | "Você também ama a natureza?" / "Então vem comigo!" | Música sobe |
| 11 | 90–96 s | Encerramento | Capa + logo + onde baixar | (sem balão) | Final da música |

## Créditos que aparecem no fim
- Jogo: Léo na Amazônia (Godot 4.7) — github.com/RicardoFissmer/leo-na-amazonia
- Efeitos: VesperaFX (devkcud, MPL-2.0) · Vídeo feito com Remotion
