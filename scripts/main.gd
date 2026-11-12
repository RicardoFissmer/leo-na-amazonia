extends Node2D
## Monta o fundo, a fase a partir do MAPA e controla as regras do jogo.

const Util = preload("res://scripts/util.gd")
const Player = preload("res://scripts/player.gd")
const Letra = preload("res://scripts/letra.gd")
const Onca = preload("res://scripts/onca.gd")
const Cobra = preload("res://scripts/cobra.gd")
const Piranha = preload("res://scripts/piranha.gd")
const Arara = preload("res://scripts/arara.gd")
const Hud = preload("res://scripts/hud.gd")
const Audio = preload("res://scripts/audio.gd")
const Titulo = preload("res://scripts/titulo.gd")
const Montagem = preload("res://scripts/montagem.gd")
const VerdadeiroFalso = preload("res://scripts/verdadeiro_falso.gd")
const Historia = preload("res://scripts/historia.gd")
const Tutorial = preload("res://scripts/tutorial.gd")
const Efeitos = preload("res://scripts/efeitos.gd")

const TILE := 16
const ALTURA_TELA := 180

## Para adicionar uma fase nova, é só colocar mais uma palavra aqui.
## Palavras com até 8 letras cabem no mapa. A imagem do animal tem 96x72 pixels.
## "perguntas" são as afirmações do desafio Verdadeiro ou Falso: [texto, é verdade?, explicação].
## O jogo sorteia 3 delas (sempre pelo menos uma verdadeira e uma falsa).
const PALAVRAS := [
	{"palavra": "ARARA", "dica": "Ave colorida de bico forte", "imagem": "res://assets/animais/arara.png",
		"fato": "A arara usa o bico forte para quebrar castanhas e sementes bem duras.",
		"perguntas": [
			["A arara consegue quebrar castanhas duras com o bico.", true,
				"O bico dela é forte o bastante para abrir cascas bem duras."],
			["A arara só come carne.", false,
				"Ela come frutas, sementes e castanhas."],
			["Os casais de araras costumam ficar juntos por muitos anos.", true,
				"Elas vivem em casais e voam lado a lado pela floresta."],
			["A arara não consegue voar.", false,
				"Ela voa muito bem e atravessa grandes distâncias."],
			["Araras comem barro dos barrancos dos rios.", true,
				"O barro tem sais minerais que fazem bem para elas."],
		]},
	{"palavra": "ONÇA", "dica": "O maior felino das Américas", "imagem": "res://assets/animais/onca.png",
		"fato": "A onça-pintada é o maior felino das Américas e é uma ótima nadadora.",
		"perguntas": [
			["A onça-pintada é o maior felino das Américas.", true,
				"Ela é maior que a onça-parda e que a jaguatirica."],
			["A onça-pintada sabe nadar.", true,
				"Ela nada muito bem e até caça dentro dos rios."],
			["Todas as onças têm as pintas iguais.", false,
				"Cada onça tem um desenho único, como uma impressão digital."],
			["A onça vive em bandos, como os leões.", false,
				"Ela vive sozinha e tem o seu próprio território."],
			["A onça-pintada vive na África.", false,
				"Ela vive nas Américas, inclusive na Amazônia."],
		]},
	{"palavra": "BOTO", "dica": "O golfinho dos rios", "imagem": "res://assets/animais/boto.png",
		"fato": "O boto-cor-de-rosa vive nos rios da Amazônia e usa sons para se localizar na água.",
		"perguntas": [
			["O boto-cor-de-rosa é um golfinho de rio.", true,
				"Ele vive em água doce, nos rios e lagos da Amazônia."],
			["O boto vive no mar.", false,
				"O boto-cor-de-rosa vive em água doce, nos rios."],
			["O boto usa sons para encontrar comida.", true,
				"Ele faz sons e escuta o eco para achar os peixes."],
			["O boto é um peixe.", false,
				"Ele é um mamífero: respira ar e amamenta os filhotes."],
			["O boto precisa subir até a superfície para respirar.", true,
				"Ele respira ar por um buraco no alto da cabeça."],
		]},
	{"palavra": "TUCANO", "dica": "Ave de bico enorme", "imagem": "res://assets/animais/tucano.png",
		"fato": "O bico do tucano é grande, mas leve, e ajuda a controlar a temperatura do corpo.",
		"perguntas": [
			["O bico do tucano é grande, mas é leve.", true,
				"Por dentro ele parece uma esponja, cheio de espaços com ar."],
			["O tucano não consegue voar por causa do bico.", false,
				"Ele voa sim! O bico é leve."],
			["O tucano ajuda a espalhar sementes pela floresta.", true,
				"Ele come frutas e solta as sementes em outros lugares."],
			["O tucano dorme no chão.", false,
				"Ele dorme em buracos de árvores, com o bico virado para as costas."],
			["O bico ajuda o tucano a se refrescar.", true,
				"O bico solta o calor do corpo nos dias quentes."],
		]},
	{"palavra": "CAPIVARA", "dica": "O maior roedor do mundo", "imagem": "res://assets/animais/capivara.png",
		"fato": "A capivara é o maior roedor do mundo. Ela nada muito bem e adora ficar na água.",
		"perguntas": [
			["A capivara é o maior roedor do mundo.", true,
				"Ela é parente do porquinho-da-índia, só que bem maior."],
			["A capivara não sabe nadar.", false,
				"Ela nada muito bem e tem uma pele entre os dedos que ajuda a nadar."],
			["A capivara come plantas.", true,
				"Ela come capim e plantas que crescem na água."],
			["A capivara vive sempre sozinha.", false,
				"Ela vive em grupos, perto de rios e lagos."],
			["A capivara consegue ficar alguns minutos embaixo d'água.", true,
				"Ela prende a respiração para se esconder dos predadores."],
		]},
]

## História: o Livro da Floresta da vovó Lúcia perdeu as letras numa ventania,
## e o Léo vai até a mata devolver o nome de cada animal.
const HISTORIA_INICIO := [
	{"titulo": "O Livro da Floresta", "imagem": "res://assets/historia/livro.png",
		"texto": "O Léo adora o Livro da Floresta da vovó Lúcia. Cada página mostra um animal da Amazônia e o nome dele."},
	{"titulo": "Uma ventania!", "imagem": "res://assets/historia/livro_vento.png",
		"texto": "Numa tarde, uma ventania arrancou as letras do livro e espalhou tudo pela mata. Os animais ficaram sem nome!"},
	{"titulo": "A missão do Léo", "imagem": "res://assets/historia/leo_missao.png",
		"texto": "O Léo vai entrar na floresta para achar as letras e devolver o nome de cada animal. Cuidado com a onça, a cobra e a piranha!"},
]
const HISTORIA_FIM := [
	{"titulo": "O livro está completo!", "imagem": "res://assets/historia/livro_completo.png",
		"texto": "O Léo achou todas as letras! A arara, a onça, o boto, o tucano e a capivara têm o seu nome de volta."},
	{"titulo": "Obrigada, Léo!", "imagem": "res://assets/historia/leo_missao.png",
		"texto": "A vovó Lúcia ficou muito feliz. Agora todo mundo pode aprender sobre os animais da Amazônia.\nVocê fez %d pontos!"},
]

## Legenda do mapa (cada caractere = 16x16 pixels):
##   #  chão          ~  água           =  plataforma de tronco
##   P  início do Léo O  onça           .  vazio
##   C  cobra (fica pendurada no tronco "=" logo acima)
##   F  piranha (fica no rio "~" logo abaixo e pula de vez em quando)
##   1-8  letras da palavra (o jogo embaralha a ordem)   x  letra errada (distração)
const MAPA := [
	"................................................................................",
	"................................................................................",
	"................................................................................",
	".......................................4........................................",
	"................................................................................",
	".........2............................===..............................6........",
	"...................7...........................x................................",
	"........===..................3....===...............===...............===.......",
	"..P...1..............x..O....F.....C...................O.5.....F...x....C....8..",
	"##############..############~~~###############...############~~~################",
	"##############..############~~~###############...############~~~################",
	"##############..############~~~###############...############~~~################",
]

var estado := "menu"  # "menu" ou "jogo"
var nivel := 0
var letras: Array[String] = []     # letras da palavra, na ordem certa
var faltando: Array[String] = []   # letras que ainda não foram coletadas
var coletadas: Array[String] = []  # letras na ordem em que o Léo pegou
var montando := false
var respondendo := false      # está no desafio Verdadeiro ou Falso
var desafio_feito := false    # já respondeu o desafio desta fase
var espera_confirmar := 0.0
var vidas := 3
var pontos := 0
var fim_de_fase := false
var inicio := Vector2.ZERO

var mundo: Node2D
var jogador: Player
var hud: Hud
var audio: Audio
var titulo: Titulo
var montagem: Montagem
var vf: VerdadeiroFalso
var historia: Historia
var tutorial: Tutorial
var efeitos: Efeitos
var tutorial_concluido := false  # depois de passar pela parte do tutorial, ele não volta ao recomeçar a fase
var camadas: Array[Parallax2D] = []
var faixas_menu: Array[Sprite2D] = []
var letras_menu: Array[Node2D] = []
var tempo_menu := 0.0

var tex_ground: Texture2D = load("res://assets/ground.png")
var tex_dirt: Texture2D = load("res://assets/dirt.png")
var tex_log: Texture2D = load("res://assets/log.png")
var tex_water: Texture2D = load("res://assets/water.png")
var tex_lily: Texture2D = load("res://assets/lily.png")
var tex_bush: Texture2D = load("res://assets/bush.png")
var tex_heliconia: Texture2D = load("res://assets/heliconia.png")


func _ready() -> void:
	_configurar_controles()
	_criar_fundo()
	efeitos = Efeitos.new()
	add_child(efeitos)
	hud = Hud.new()
	hud.layer = 2  # acima da vinheta/cor do cenário (camada 1)
	add_child(hud)
	audio = Audio.new()
	add_child(audio)
	titulo = Titulo.new()
	titulo.audio = audio
	titulo.efeitos = efeitos
	titulo.layer = 2
	titulo.jogar.connect(iniciar_jogo)
	add_child(titulo)
	montagem = Montagem.new()
	montagem.audio = audio
	montagem.concluido.connect(_ao_montar)
	add_child(montagem)
	vf = VerdadeiroFalso.new()
	vf.audio = audio
	vf.concluido.connect(_ao_responder)
	add_child(vf)
	historia = Historia.new()
	add_child(historia)
	tutorial = Tutorial.new()
	tutorial.audio = audio
	add_child(tutorial)
	mostrar_menu()
	audio.tocar_musica()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("som"):
		var mudo := audio.alternar_mudo()
		if estado == "jogo":
			hud.mensagem("Som desligado" if mudo else "Som ligado", 1.0)
	if Input.is_action_just_pressed("retro"):
		var ligado := efeitos.alternar_retro()
		titulo.atualizar_botao_retro()
		if estado == "jogo":
			hud.mensagem("Modo retrô ligado" if ligado else "Modo retrô desligado", 1.5)

	if estado == "menu" or estado == "historia":
		_animar_menu(delta)  # a história aparece por cima da animação do menu
		return
	if efeitos.em_transicao:
		return

	espera_confirmar = maxf(espera_confirmar - delta, 0.0)
	if Input.is_action_just_pressed("voltar"):
		mostrar_menu()
		return
	if fim_de_fase and espera_confirmar <= 0.0 and Input.is_action_just_pressed("confirmar"):
		# depois de montar a palavra vem o Verdadeiro ou Falso; depois dele, a próxima fase
		if not desafio_feito:
			_abrir_desafio()
			return
		if nivel == PALAVRAS.size() - 1:
			efeitos.transicao(_mostrar_final)
		else:
			efeitos.transicao(carregar_nivel.bind(nivel + 1))


# ---------------------------------------------------------------- controles

func _configurar_controles() -> void:
	var teclas := {
		"esquerda": [KEY_LEFT, KEY_A],
		"direita": [KEY_RIGHT, KEY_D],
		"pular": [KEY_SPACE, KEY_UP, KEY_W],
		"confirmar": [KEY_ENTER, KEY_KP_ENTER],
		"voltar": [KEY_ESCAPE],
		"som": [KEY_M],
		"retro": [KEY_R],
		"desfazer": [KEY_BACKSPACE],
	}
	for acao in teclas:
		if not InputMap.has_action(acao):
			InputMap.add_action(acao)
		for tecla in teclas[acao]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla
			InputMap.action_add_event(acao, ev)


# ---------------------------------------------------------------- fundo

func _criar_fundo() -> void:
	_camada("res://assets/bg_far.png", 0.15)
	_camada("res://assets/bg_mid.png", 0.4)
	_camada("res://assets/bg_canopy.png", 0.8)


func _camada(caminho: String, escala: float) -> void:
	var p := Parallax2D.new()
	p.scroll_scale = Vector2(escala, 1.0)
	p.repeat_size = Vector2(640, 0)
	p.repeat_times = 3
	var s := Sprite2D.new()
	s.texture = load(caminho)
	s.centered = false
	p.add_child(s)
	add_child(p)
	camadas.append(p)


# ---------------------------------------------------------------- tela inicial

func mostrar_menu() -> void:
	estado = "menu"
	fim_de_fase = false
	montando = false
	respondendo = false
	montagem.fechar()
	vf.fechar()
	tutorial.parar()
	historia.fechar()
	hud.esconder_painel()
	hud.visible = false
	_novo_mundo()
	faixas_menu.clear()
	letras_menu.clear()
	tempo_menu = 0.0

	# o fundo anda sozinho, dando a impressão de que o Léo está correndo
	var velocidades := [6.0, 16.0, 32.0]
	for i in camadas.size():
		camadas[i].scroll_offset = Vector2.ZERO
		camadas[i].autoscroll = Vector2(-velocidades[i], 0)

	faixas_menu.append(_faixa(tex_ground, Vector2(0, 9 * TILE), 336, TILE))
	faixas_menu.append(_faixa(tex_dirt, Vector2(0, 10 * TILE), 336, TILE * 2))

	var leo := AnimatedSprite2D.new()
	leo.sprite_frames = Util.frames("res://assets/leo.png", 12, 16, {"andando": [[0, 1], 8.0]})
	leo.position = Vector2(236, 9 * TILE - 8)
	leo.play("andando")
	mundo.add_child(leo)

	var onca := AnimatedSprite2D.new()
	onca.sprite_frames = Util.frames("res://assets/onca.png", 20, 9, {"andando": [[0, 1], 8.0]})
	onca.position = Vector2(70, 9 * TILE - 4.5)
	onca.flip_h = true
	onca.play("andando")
	mundo.add_child(onca)

	var texto := "AMAZONIA"
	for i in texto.length():
		var l := Letra.new()
		l.letra = texto[i]
		l.position = Vector2(20 + i * 45, 128)
		mundo.add_child(l)
		letras_menu.append(l)

	for k in 2:
		var arara := Arara.new()
		arara.position = Vector2(40 + k * 160, 0)
		arara.base_y = 72 + k * 10
		mundo.add_child(arara)

	var cam := Camera2D.new()
	cam.position = Vector2(160, 90)
	mundo.add_child(cam)
	cam.make_current()

	titulo.mostrar()


func _animar_menu(delta: float) -> void:
	tempo_menu += delta
	for f in faixas_menu:
		f.region_rect.position.x = fmod(tempo_menu * 40.0, 16.0)
	for l in letras_menu:
		l.position.x -= 40.0 * delta
		if l.position.x < -12.0:
			l.position.x += 360.0


func iniciar_jogo() -> void:
	if efeitos.em_transicao:
		return
	audio.tocar("comecar")
	efeitos.transicao(_abrir_historia_inicio)


func _abrir_historia_inicio() -> void:
	titulo.esconder()
	estado = "historia"
	historia.mostrar(HISTORIA_INICIO, efeitos.transicao.bind(_comecar_primeira_fase))


func _comecar_primeira_fase() -> void:
	historia.fechar()
	for c in camadas:
		c.autoscroll = Vector2.ZERO
		c.scroll_offset = Vector2.ZERO
	estado = "jogo"
	hud.visible = true
	pontos = 0
	tutorial_concluido = false
	carregar_nivel(0)


func _mostrar_final() -> void:
	var paginas := HISTORIA_FIM.duplicate(true)
	paginas[-1]["texto"] = paginas[-1]["texto"] % pontos
	mostrar_menu()
	estado = "historia"
	titulo.esconder()
	historia.mostrar(paginas, efeitos.transicao.bind(mostrar_menu), "voltar ao menu")


# ---------------------------------------------------------------- fase

func carregar_nivel(i: int) -> void:
	nivel = i % PALAVRAS.size()
	_novo_mundo()

	fim_de_fase = false
	montando = false
	respondendo = false
	desafio_feito = false
	montagem.fechar()
	vf.fechar()
	vidas = 3
	var palavra: String = PALAVRAS[nivel]["palavra"]
	letras.clear()
	faltando.clear()
	coletadas.clear()
	for c in palavra:
		letras.append(c)
		faltando.append(c)

	var rng := RandomNumberGenerator.new()
	rng.seed = 2026 + nivel
	# as letras são espalhadas pelo mapa fora de ordem
	var embaralhadas := _embaralhada(letras, rng)
	var largura := 0

	# 0) cobras e piranhas vêm antes dos blocos para ficarem atrás do tronco e da água
	for y in MAPA.size():
		var linha: String = MAPA[y]
		for x in linha.length():
			if linha[x] == "C":
				var cobra := Cobra.new()
				cobra.position = Vector2(x * TILE + 8, y * TILE - 8)  # embaixo do tronco (8 px de altura)
				mundo.add_child(cobra)
			elif linha[x] == "F":
				var piranha := Piranha.new()
				piranha.position = Vector2(x * TILE + 8, 0)
				piranha.superficie = (y + 1) * TILE + 4
				mundo.add_child(piranha)

	# 1) blocos: chão, água e plataformas
	for y in MAPA.size():
		var linha: String = MAPA[y]
		largura = maxi(largura, linha.length())
		var x := 0
		while x < linha.length():
			var ch := linha[x]
			if ch in ["#", "~", "="]:
				var ini := x
				while x < linha.length() and linha[x] == ch:
					x += 1
				_criar_bloco(ch, ini, x - ini, y)
			else:
				x += 1

	# 2) plantas decorando o chão
	for x in largura:
		if _tile(x, 9) == "#" and _tile(x, 8) == "." and rng.randf() < 0.3:
			var tex := tex_bush if rng.randf() < 0.65 else tex_heliconia
			var planta := Sprite2D.new()
			planta.texture = tex
			planta.centered = false
			planta.position = Vector2(x * TILE + 8 - tex.get_width() / 2.0, 9 * TILE - tex.get_height() + 1)
			mundo.add_child(planta)

	# 3) araras no céu
	for k in 2:
		var arara := Arara.new()
		arara.position = Vector2(60 + k * 170, 0)
		arara.base_y = 38 + k * 16
		mundo.add_child(arara)

	# 4) letras, onças e o Léo
	for y in MAPA.size():
		var linha: String = MAPA[y]
		for x in linha.length():
			var ch := linha[x]
			var centro := Vector2(x * TILE + 8, y * TILE + 8)
			match ch:
				"P":
					inicio = centro
				"O":
					_criar_onca(x, y)
				"x":
					_criar_letra(centro, _letra_errada(rng, palavra))
				"1", "2", "3", "4", "5", "6", "7", "8":
					var idx := int(ch) - 1
					if idx < embaralhadas.size():
						_criar_letra(centro, embaralhadas[idx])

	# paredes invisíveis nas bordas
	_corpo_solido(Vector2(-TILE, 0), Vector2(TILE, ALTURA_TELA), false)
	_corpo_solido(Vector2(largura * TILE, 0), Vector2(TILE, ALTURA_TELA), false)

	jogador = Player.new()
	jogador.position = inicio
	jogador.caiu.connect(_ao_cair)
	jogador.machucado.connect(_ao_machucar)
	jogador.pulou.connect(audio.tocar.bind("pulo"))
	jogador.pulou.connect(tutorial.ao_pular)
	mundo.add_child(jogador)

	# a fase 1 ensina a jogar (até a pessoa passar pela parte do tutorial)
	if nivel == 0 and not tutorial_concluido:
		tutorial.iniciar(jogador, inicio)
	else:
		tutorial.parar()

	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = largura * TILE
	cam.limit_bottom = ALTURA_TELA
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	jogador.add_child(cam)
	cam.make_current()

	_atualizar_hud()
	hud.mensagem("Fase %d: %s" % [nivel + 1, PALAVRAS[nivel]["dica"]], 3.5)


func _novo_mundo() -> void:
	if mundo:
		mundo.queue_free()
	mundo = Node2D.new()
	add_child(mundo)


func _tile(x: int, y: int) -> String:
	if y < 0 or y >= MAPA.size():
		return "."
	var linha: String = MAPA[y]
	if x < 0 or x >= linha.length():
		return "."
	return linha[x]


func _criar_bloco(tipo: String, x: int, n: int, y: int) -> void:
	var pos := Vector2(x * TILE, y * TILE)
	var w := n * TILE
	var topo := _tile(x, y - 1) != tipo
	match tipo:
		"#":
			_faixa(tex_ground if topo else tex_dirt, pos, w, TILE)
			_corpo_solido(pos, Vector2(w, TILE), false)
		"=":
			_faixa(tex_log, pos, w, 8)
			_corpo_solido(pos, Vector2(w, 8), true)
		"~":
			if topo:
				_faixa(tex_water, pos + Vector2(0, 4), w, TILE - 4)
				var lily := Sprite2D.new()
				lily.texture = tex_lily
				lily.centered = false
				lily.position = pos + Vector2(w / 2.0 - 8, 1)
				mundo.add_child(lily)
				var perigo := Area2D.new()
				perigo.position = pos + Vector2(w / 2.0, 12)
				perigo.add_child(Util.retangulo(Vector2(w, 8)))
				perigo.body_entered.connect(_ao_entrar_agua)
				mundo.add_child(perigo)
			else:
				_faixa(tex_water, pos, w, TILE)


func _faixa(tex: Texture2D, pos: Vector2, largura_px: float, altura_px: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, largura_px, altura_px)
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.position = pos
	mundo.add_child(s)
	return s


func _corpo_solido(pos: Vector2, tam: Vector2, so_por_cima: bool) -> void:
	var corpo := StaticBody2D.new()
	corpo.position = pos + tam / 2.0
	var forma := Util.retangulo(tam)
	forma.one_way_collision = so_por_cima
	corpo.add_child(forma)
	mundo.add_child(corpo)


func _criar_letra(centro: Vector2, letra: String) -> void:
	var l := Letra.new()
	l.letra = letra
	l.position = centro
	l.coletada.connect(_ao_coletar)
	mundo.add_child(l)


func _letra_errada(rng: RandomNumberGenerator, palavra: String) -> String:
	var alfabeto := "ABCDEFGHIJLMNOPRSTUVZ"
	var c := alfabeto[rng.randi_range(0, alfabeto.length() - 1)]
	while palavra.contains(c):
		c = alfabeto[rng.randi_range(0, alfabeto.length() - 1)]
	return c


func _criar_onca(x: int, y: int) -> void:
	# a onça anda sobre o trecho de chão logo abaixo dela
	var esq := x
	while _tile(esq - 1, y + 1) == "#":
		esq -= 1
	var dir := x
	while _tile(dir + 1, y + 1) == "#":
		dir += 1
	var onca := Onca.new()
	onca.position = Vector2(x * TILE + 8, (y + 1) * TILE - 4.5)
	onca.limite_esq = esq * TILE + 10
	onca.limite_dir = (dir + 1) * TILE - 10
	mundo.add_child(onca)


# ---------------------------------------------------------------- regras

func _ao_coletar(letra: String, no: Area2D) -> void:
	if fim_de_fase or montando or respondendo or estado != "jogo":
		return
	no.queue_free()
	var idx := faltando.find(letra)
	if idx >= 0:
		faltando.remove_at(idx)
		coletadas.append(letra)
		pontos += 10
		audio.tocar("letra")
		hud.mensagem("+10  Letra %s!" % letra, 1.5)
		tutorial.ao_coletar(true)
		if faltando.is_empty():
			_abrir_montagem()
	else:
		pontos = maxi(0, pontos - 5)
		audio.tocar("erro")
		hud.mensagem("Ops! A letra %s não está na palavra." % letra, 3.0)
		tutorial.ao_coletar(false)
	_atualizar_hud()


func _abrir_montagem() -> void:
	montando = true
	jogador.travado = true
	tutorial.esconder()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# se por acaso o Léo pegou na ordem certa, embaralha de novo
	var pecas: Array[String] = []
	pecas.assign(coletadas)
	if pecas == letras:
		pecas = _embaralhada(letras, rng)
	var info: Dictionary = PALAVRAS[nivel]
	var tex: Texture2D = load(info["imagem"])
	montagem.abrir(info["palavra"], pecas, info["dica"], info["fato"], tex)


func _ao_montar(tentativas: int) -> void:
	# 50 pontos de primeira, 35 na segunda tentativa, e assim por diante
	pontos += maxi(10, 50 - (tentativas - 1) * 15)
	montando = false
	fim_de_fase = true
	desafio_feito = false
	espera_confirmar = 0.4
	_atualizar_hud()


func _abrir_desafio() -> void:
	montagem.fechar()
	fim_de_fase = false
	respondendo = true
	var info: Dictionary = PALAVRAS[nivel]
	vf.abrir(_sortear_perguntas(info["perguntas"], 3), load(info["imagem"]),
		nivel == PALAVRAS.size() - 1)


func _ao_responder(acertos: int) -> void:
	pontos += acertos * VerdadeiroFalso.PONTOS
	respondendo = false
	desafio_feito = true
	fim_de_fase = true
	espera_confirmar = 0.4
	_atualizar_hud()


## Sorteia `quantas` afirmações, garantindo pelo menos uma verdadeira e uma falsa.
func _sortear_perguntas(todas: Array, quantas: int) -> Array:
	var verdadeiras := todas.filter(func(p): return p[1])
	var falsas := todas.filter(func(p): return not p[1])
	verdadeiras.shuffle()
	falsas.shuffle()
	var escolhidas := []
	if not verdadeiras.is_empty():
		escolhidas.append(verdadeiras.pop_back())
	if not falsas.is_empty():
		escolhidas.append(falsas.pop_back())
	var resto := verdadeiras + falsas
	resto.shuffle()
	while escolhidas.size() < quantas and not resto.is_empty():
		escolhidas.append(resto.pop_back())
	escolhidas.shuffle()
	return escolhidas


## Devolve uma cópia embaralhada que, se possível, é diferente da original.
func _embaralhada(original: Array[String], rng: RandomNumberGenerator) -> Array[String]:
	var copia: Array[String] = []
	for c in original:
		copia.append(c)
	for tentativa in 10:
		for i in range(copia.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := copia[i]
			copia[i] = copia[j]
			copia[j] = tmp
		if copia != original:
			break
	return copia


func _ao_entrar_agua(corpo: Node2D) -> void:
	if corpo == jogador:
		jogador.cair()


func _ao_machucar(quem: String) -> void:
	audio.tocar("dano")
	_perder_vida("Cuidado com %s!" % quem)


func _ao_cair() -> void:
	audio.tocar("caiu")
	_perder_vida.call_deferred("Ops! Caiu!", true)


func _perder_vida(texto: String, voltar_ao_inicio := false) -> void:
	if fim_de_fase or montando or respondendo or estado != "jogo" or efeitos.em_transicao:
		return
	# no tutorial da fase 1, errar não tira vida: o Léo volta para logo antes do obstáculo
	if tutorial.protege(jogador.global_position.x):
		hud.mensagem("Tudo bem! Tente de novo." if voltar_ao_inicio else texto, 2.0)
		if voltar_ao_inicio:
			jogador.reaparecer(tutorial.ponto_seguro)
		return
	if tutorial.ativo:
		tutorial_concluido = true
	vidas -= 1
	if vidas <= 0:
		_atualizar_hud()
		jogador.travado = true
		efeitos.transicao(_recomecar_fase)
		return
	hud.mensagem(texto)
	if voltar_ao_inicio:
		jogador.reaparecer(inicio)
	_atualizar_hud()


func _recomecar_fase() -> void:
	carregar_nivel(nivel)
	hud.mensagem("Tente de novo!", 2.0)


func _atualizar_hud() -> void:
	hud.atualizar(coletadas, letras.size(), PALAVRAS[nivel]["dica"], vidas, pontos)
