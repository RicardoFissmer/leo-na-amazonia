extends CanvasLayer
## Telas da história (começo e fim do jogo): uma imagem e um texto por página.
## O texto aparece aos poucos; ENTER/ESPAÇO/clique mostra tudo ou passa para a próxima página.
## ESC pula a história.

const LETRAS_POR_SEGUNDO := 45.0

var paginas: Array = []  # cada uma: {"titulo": ..., "imagem": caminho, "texto": ...}
var atual := 0
var ao_terminar: Callable
var texto_ultima := "começar"  # o que o ENTER faz na última página
var espera := 0.0
var terminou := false  # já chamou `ao_terminar`; quem chamou fecha a tela (ex.: no meio da transição)
var letras_visiveis := 0.0

var titulo: Label
var imagem: TextureRect
var texto: Label
var contador: Label
var rodape: Label


func _ready() -> void:
	layer = 6
	visible = false

	var escuro := ColorRect.new()
	escuro.color = Color(0, 0, 0, 0.6)
	escuro.size = Vector2(320, 180)
	escuro.gui_input.connect(_ao_clicar)
	add_child(escuro)

	var caixa := Panel.new()
	caixa.position = Vector2(16, 6)
	caixa.size = Vector2(288, 168)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("163d28")
	estilo.border_color = Color("ffd21f")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(6)
	caixa.add_theme_stylebox_override("panel", estilo)
	add_child(caixa)

	titulo = _label(caixa, Vector2(0, 3), Vector2(288, 15), 11, Color("ffd21f"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contador = _label(caixa, Vector2(234, 3), Vector2(46, 15), 8, Color("9fd9b5"))
	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var moldura := Panel.new()
	moldura.position = Vector2(94, 20)
	moldura.size = Vector2(100, 76)
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_moldura := StyleBoxFlat.new()
	estilo_moldura.bg_color = Color("2a6b41")
	estilo_moldura.border_color = Color("0e3322")
	estilo_moldura.set_border_width_all(1)
	estilo_moldura.set_corner_radius_all(3)
	moldura.add_theme_stylebox_override("panel", estilo_moldura)
	caixa.add_child(moldura)
	imagem = TextureRect.new()
	imagem.position = Vector2(2, 2)
	imagem.size = Vector2(96, 72)
	moldura.add_child(imagem)

	texto = _label(caixa, Vector2(12, 99), Vector2(264, 50), 9, Color.WHITE)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	rodape = _label(caixa, Vector2(0, 152), Vector2(288, 12), 7, Color("9fd9b5"))
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Mostra as páginas e chama `fim` quando o jogador terminar (ou pular com ESC).
func mostrar(lista: Array, fim: Callable, acao_final := "começar") -> void:
	paginas = lista
	ao_terminar = fim
	texto_ultima = acao_final
	atual = 0
	terminou = false
	visible = true
	_mostrar_pagina()


func fechar() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible or terminou:
		return
	espera = maxf(espera - delta, 0.0)
	if texto.visible_characters >= 0:
		letras_visiveis += delta * LETRAS_POR_SEGUNDO
		texto.visible_characters = int(letras_visiveis)
		if texto.visible_characters >= texto.get_total_character_count():
			texto.visible_characters = -1
	if espera > 0.0:
		return
	if Input.is_action_just_pressed("voltar"):
		_terminar()
	elif Input.is_action_just_pressed("confirmar") or Input.is_action_just_pressed("pular"):
		_avancar()


func _ao_clicar(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and espera <= 0.0 and not terminou:
		_avancar()


func _mostrar_pagina() -> void:
	var p: Dictionary = paginas[atual]
	titulo.text = p["titulo"]
	imagem.texture = load(p["imagem"])
	texto.text = p["texto"]
	texto.visible_characters = 0
	letras_visiveis = 0.0
	contador.text = "%d/%d" % [atual + 1, paginas.size()]
	var ultima := atual == paginas.size() - 1
	rodape.text = ("ENTER: " + texto_ultima if ultima else "ENTER: continuar") + "     ESC: pular"
	# evita que o ENTER que abriu a tela já passe a primeira página
	espera = 0.4


func _avancar() -> void:
	# primeiro clique com o texto ainda aparecendo: mostra o texto inteiro
	if texto.visible_characters >= 0:
		texto.visible_characters = -1
		espera = 0.15
		return
	atual += 1
	if atual < paginas.size():
		_mostrar_pagina()
	else:
		_terminar()


func _terminar() -> void:
	terminou = true
	if ao_terminar.is_valid():
		ao_terminar.call()


func _label(pai: Control, pos: Vector2, tam: Vector2, fonte: int, cor: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = tam
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fonte)
	l.add_theme_color_override("font_color", cor)
	pai.add_child(l)
	return l
