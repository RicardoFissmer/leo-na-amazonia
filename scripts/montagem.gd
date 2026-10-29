extends CanvasLayer
## Tela de montar a palavra: mostra o animal e as letras coletadas fora de ordem.
## O jogador clica nas letras (ou usa setas + Enter) para colocá-las na ordem certa.

signal concluido(tentativas: int)

const COR_SLOT := Color(0.05, 0.2, 0.12)
const COR_CERTO := Color("2f9e44")
const COR_ERRADO := Color("c92a2a")

var audio  # referência ao nó de áudio (definida pelo main.gd)

var palavra: Array[String] = []
var slots: Array[Button] = []
var slot_letra: Array[String] = []
var slot_origem: Array[Button] = []
var slot_travado: Array[bool] = []
var pecas: Array[Button] = []
var tentativas := 1
var verificando := false
var sessao := 0
var fato := ""
var rodape_final := ""

var titulo: Label
var imagem: TextureRect
var texto: Label
var linha_slots: HBoxContainer
var linha_pecas: HBoxContainer
var rodape: Label


func _ready() -> void:
	layer = 5
	visible = false

	var escuro := ColorRect.new()
	escuro.color = Color(0, 0, 0, 0.55)
	escuro.size = Vector2(320, 180)
	add_child(escuro)

	var caixa := Panel.new()
	caixa.position = Vector2(16, 4)
	caixa.size = Vector2(288, 172)
	var estilo := _estilo(Color("163d28"), Color("ffd21f"))
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(6)
	caixa.add_theme_stylebox_override("panel", estilo)
	add_child(caixa)

	titulo = _label(caixa, Vector2(0, 3), Vector2(288, 15), 11, Color("ffd21f"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var moldura := Panel.new()
	moldura.position = Vector2(10, 20)
	moldura.size = Vector2(100, 76)
	moldura.add_theme_stylebox_override("panel", _estilo(Color("2a6b41"), Color("0e3322")))
	caixa.add_child(moldura)
	imagem = TextureRect.new()
	imagem.position = Vector2(2, 2)
	imagem.size = Vector2(96, 72)
	moldura.add_child(imagem)

	texto = _label(caixa, Vector2(118, 20), Vector2(160, 76), 8, Color("e8fff0"))
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	linha_slots = HBoxContainer.new()
	linha_slots.position = Vector2(0, 102)
	linha_slots.size = Vector2(288, 26)
	linha_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	linha_slots.add_theme_constant_override("separation", 4)
	caixa.add_child(linha_slots)

	linha_pecas = HBoxContainer.new()
	linha_pecas.position = Vector2(0, 130)
	linha_pecas.size = Vector2(288, 24)
	linha_pecas.alignment = BoxContainer.ALIGNMENT_CENTER
	linha_pecas.add_theme_constant_override("separation", 6)
	caixa.add_child(linha_pecas)

	rodape = _label(caixa, Vector2(0, 154), Vector2(288, 12), 7, Color("9fd9b5"))
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _process(_delta: float) -> void:
	if visible and not verificando and Input.is_action_just_pressed("desfazer"):
		_desfazer()


## Abre a tela. `embaralhadas` são as letras na ordem em que foram coletadas.
func abrir(p: String, embaralhadas: Array[String], dica: String, fato_animal: String,
		tex: Texture2D) -> void:
	sessao += 1
	fato = fato_animal
	rodape_final = "Aperte ENTER para o desafio: Verdadeiro ou Falso!"
	tentativas = 1
	verificando = false
	for filho in linha_slots.get_children() + linha_pecas.get_children():
		filho.free()
	slots.clear()
	slot_letra.clear()
	slot_origem.clear()
	slot_travado.clear()
	pecas.clear()
	palavra.clear()
	for c in p:
		palavra.append(c)

	titulo.text = "Monte a palavra!"
	imagem.texture = tex
	texto.text = "Dica: %s\n\nColoque as letras na ordem certa." % dica
	rodape.text = "Clique nas letras ou use setas + ENTER.  BACKSPACE desfaz."
	linha_pecas.visible = true

	for i in palavra.size():
		var s := Button.new()
		s.custom_minimum_size = Vector2(22, 24)
		s.add_theme_font_size_override("font_size", 14)
		s.add_theme_color_override("font_color", Color.WHITE)
		s.add_theme_color_override("font_disabled_color", Color.WHITE)
		_pintar(s, COR_SLOT, Color("ffd21f"))
		s.pressed.connect(_remover.bind(i))
		linha_slots.add_child(s)
		slots.append(s)
		slot_letra.append("")
		slot_origem.append(null)
		slot_travado.append(false)

	for c in embaralhadas:
		var b := Button.new()
		b.text = c
		b.custom_minimum_size = Vector2(22, 22)
		b.add_theme_font_size_override("font_size", 14)
		for estado in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			b.add_theme_color_override(estado, Color("6b3e00"))
		b.add_theme_color_override("font_disabled_color", Color(0.4, 0.25, 0, 0.35))
		b.add_theme_stylebox_override("normal", _estilo(Color("ffcc00"), Color("9a6b00")))
		b.add_theme_stylebox_override("hover", _estilo(Color("ffe066"), Color("9a6b00")))
		b.add_theme_stylebox_override("pressed", _estilo(Color("ffe066"), Color("9a6b00")))
		b.add_theme_stylebox_override("focus", _estilo(Color(0, 0, 0, 0), Color.WHITE, 2))
		b.add_theme_stylebox_override("disabled", _estilo(Color(1, 0.8, 0, 0.2), Color(0.6, 0.4, 0, 0.3)))
		b.pressed.connect(_colocar.bind(b))
		linha_pecas.add_child(b)
		pecas.append(b)

	visible = true
	if pecas.size() > 0:
		pecas[0].grab_focus()


func fechar() -> void:
	sessao += 1
	visible = false
	get_viewport().gui_release_focus()


# ---------------------------------------------------------------- ações

func _colocar(peca: Button) -> void:
	if verificando or peca.disabled:
		return
	var i := slot_letra.find("")
	if i == -1:
		return
	slot_letra[i] = peca.text
	slot_origem[i] = peca
	slots[i].text = peca.text
	peca.disabled = true
	if audio:
		audio.tocar("menu")
	if slot_letra.has(""):
		_focar_peca_livre()
	else:
		_verificar()


func _remover(i: int) -> void:
	if verificando or slot_travado[i] or slot_letra[i] == "":
		return
	var peca := slot_origem[i]
	peca.disabled = false
	slot_letra[i] = ""
	slot_origem[i] = null
	slots[i].text = ""
	peca.grab_focus()


func _desfazer() -> void:
	for i in range(slot_letra.size() - 1, -1, -1):
		if slot_letra[i] != "" and not slot_travado[i]:
			_remover(i)
			return


func _verificar() -> void:
	verificando = true
	var certo := true
	for i in palavra.size():
		if slot_letra[i] == palavra[i]:
			slot_travado[i] = true
			_pintar(slots[i], COR_CERTO, COR_CERTO.lightened(0.4))
		else:
			certo = false
			_pintar(slots[i], COR_ERRADO, COR_ERRADO.lightened(0.4))

	if certo:
		_sucesso()
		return

	if audio:
		audio.tocar("erro")
	tentativas += 1
	titulo.text = "Quase! As letras verdes estão certas."
	var minha_sessao := sessao
	await get_tree().create_timer(1.0).timeout
	if minha_sessao != sessao:
		return  # a tela foi fechada ou reaberta nesse meio tempo

	for i in palavra.size():
		if not slot_travado[i]:
			slot_origem[i].disabled = false
			slot_letra[i] = ""
			slot_origem[i] = null
			slots[i].text = ""
			_pintar(slots[i], COR_SLOT, Color("ffd21f"))
	titulo.text = "Monte a palavra!"
	verificando = false
	_focar_peca_livre()


func _sucesso() -> void:
	if audio:
		audio.tocar("vitoria")
	titulo.text = "Muito bem!"
	texto.text = fato
	linha_pecas.visible = false
	rodape.text = rodape_final
	for s in slots:
		s.focus_mode = Control.FOCUS_NONE
	get_viewport().gui_release_focus()
	concluido.emit(tentativas)


# ---------------------------------------------------------------- aparência

func _focar_peca_livre() -> void:
	for p in pecas:
		if not p.disabled:
			p.grab_focus()
			return


func _pintar(botao: Button, fundo: Color, borda: Color) -> void:
	for estado in ["normal", "hover", "pressed", "disabled"]:
		botao.add_theme_stylebox_override(estado, _estilo(fundo, borda))
	botao.add_theme_stylebox_override("focus", _estilo(Color(0, 0, 0, 0), Color.WHITE, 2))


func _estilo(fundo: Color, borda: Color, largura := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(largura)
	s.set_corner_radius_all(3)
	return s


func _label(pai: Control, pos: Vector2, tam: Vector2, fonte: int, cor: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = tam
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fonte)
	l.add_theme_color_override("font_color", cor)
	pai.add_child(l)
	return l
