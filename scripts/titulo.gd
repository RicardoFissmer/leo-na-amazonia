extends CanvasLayer
## Tela inicial: título, botões Jogar / Como jogar / Sair e instruções.

signal jogar

var audio  # referência ao nó de áudio (definida pelo main.gd)
var titulo: Label
var botoes: VBoxContainer
var botao_jogar: Button
var botao_voltar: Button
var painel_ajuda: Panel
var silencioso := false
var t := 0.0


func _ready() -> void:
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.25)
	sombra.position = Vector2(0, 4)
	sombra.size = Vector2(320, 62)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)

	_label("LÉO NA", 14, Color("fff3c4"), Vector2(0, 5), Vector2(320, 18))
	titulo = _label("AMAZÔNIA", 30, Color("ffd21f"), Vector2(0, 18), Vector2(320, 36))
	titulo.pivot_offset = Vector2(160, 18)
	_label("Colete as letras e forme palavras!", 8, Color("e8fff0"), Vector2(0, 52), Vector2(320, 12))

	botoes = VBoxContainer.new()
	botoes.position = Vector2(110, 69)
	botoes.size = Vector2(100, 54)
	botoes.add_theme_constant_override("separation", 3)
	add_child(botoes)
	botao_jogar = _botao("Jogar", _ao_jogar)
	_botao("Como jogar", _abrir_ajuda)
	_botao("Sair", _sair)

	_label("M: liga/desliga o som", 7, Color("c8f0d8"), Vector2(0, 168), Vector2(320, 10))
	_criar_ajuda()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	titulo.scale = Vector2.ONE * (1.0 + sin(t * 2.0) * 0.03)
	if painel_ajuda.visible and Input.is_action_just_pressed("voltar"):
		_fechar_ajuda()


func mostrar() -> void:
	visible = true
	_fechar_ajuda()


func esconder() -> void:
	visible = false
	get_viewport().gui_release_focus()


# ---------------------------------------------------------------- montagem

func _label(texto: String, fonte: int, cor: Color, pos: Vector2, tam: Vector2) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.size = tam
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fonte)
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color("0e3322"))
	l.add_theme_constant_override("outline_size", maxi(3, fonte / 4))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _estilo(fundo: Color, borda: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	return s


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(100, 16)
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_stylebox_override("normal", _estilo(Color(0.05, 0.2, 0.12, 0.85), Color("2f8a34")))
	b.add_theme_stylebox_override("hover", _estilo(Color(0.1, 0.32, 0.18, 0.95), Color("ffd21f")))
	b.add_theme_stylebox_override("focus", _estilo(Color(0, 0, 0, 0), Color("ffd21f")))
	b.add_theme_stylebox_override("pressed", _estilo(Color("ffd21f"), Color("ffd21f")))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color("ffd21f"))
	b.add_theme_color_override("font_hover_color", Color("ffd21f"))
	b.add_theme_color_override("font_pressed_color", Color("163d28"))
	b.pressed.connect(acao)
	b.focus_entered.connect(_ao_focar)
	botoes.add_child(b)
	return b


func _criar_ajuda() -> void:
	painel_ajuda = Panel.new()
	painel_ajuda.position = Vector2(30, 18)
	painel_ajuda.size = Vector2(260, 146)
	var estilo := _estilo(Color("163d28"), Color("ffd21f"))
	estilo.set_border_width_all(2)
	painel_ajuda.add_theme_stylebox_override("panel", estilo)
	painel_ajuda.visible = false
	add_child(painel_ajuda)

	var cab := Label.new()
	cab.text = "COMO JOGAR"
	cab.position = Vector2(0, 6)
	cab.size = Vector2(260, 14)
	cab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cab.add_theme_font_size_override("font_size", 11)
	cab.add_theme_color_override("font_color", Color("ffd21f"))
	painel_ajuda.add_child(cab)

	var texto := Label.new()
	texto.text = ("Setas ou A/D: andar.  Espaço ou W: pular.\n" +
		"Leia a dica e pegue as letras. Estão fora de ordem!\n" +
		"Depois, monte a palavra na ordem certa\n" +
		"e responda: verdadeiro ou falso?\n" +
		"Cuidado com a onça, a cobra, a piranha e o rio!\n" +
		"Letras erradas tiram pontos.   Esc: menu   M: som")
	texto.position = Vector2(14, 22)
	texto.size = Vector2(232, 98)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", 8)
	painel_ajuda.add_child(texto)

	botao_voltar = Button.new()
	botao_voltar.text = "Voltar"
	botao_voltar.position = Vector2(95, 124)
	botao_voltar.size = Vector2(70, 16)
	botao_voltar.add_theme_font_size_override("font_size", 9)
	var normal := _estilo(Color(0.05, 0.2, 0.12), Color("2f8a34"))
	botao_voltar.add_theme_stylebox_override("normal", normal)
	botao_voltar.add_theme_stylebox_override("hover", _estilo(Color(0.1, 0.32, 0.18), Color("ffd21f")))
	botao_voltar.add_theme_stylebox_override("focus", _estilo(Color(0, 0, 0, 0), Color("ffd21f")))
	botao_voltar.add_theme_stylebox_override("pressed", _estilo(Color("ffd21f"), Color("ffd21f")))
	botao_voltar.pressed.connect(_fechar_ajuda)
	painel_ajuda.add_child(botao_voltar)


# ---------------------------------------------------------------- ações

func _ao_focar() -> void:
	if not silencioso and audio:
		audio.tocar("menu")


func _ao_jogar() -> void:
	jogar.emit()


func _abrir_ajuda() -> void:
	if audio:
		audio.tocar("menu")
	botoes.visible = false
	painel_ajuda.visible = true
	botao_voltar.grab_focus()


func _fechar_ajuda() -> void:
	painel_ajuda.visible = false
	botoes.visible = true
	silencioso = true
	botao_jogar.grab_focus()
	silencioso = false


func _sair() -> void:
	get_tree().quit()
