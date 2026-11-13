extends CanvasLayer
## Tela inicial: logo em pixel art, botões de placa de madeira (Jogar / Como jogar / Modo retrô / Sair),
## cursor com a cabeça do Léo e instruções. As imagens são geradas por tools/gerar_ui.py.

signal jogar

const VERSAO := "v1.6"
const COR_TEXTO := Color("fff3d6")
const COR_FOCO := Color("ffe14a")
const COR_CONTORNO := Color("2a150a")

var audio  # referência ao nó de áudio (definida pelo main.gd)
var efeitos  # referência aos efeitos de tela (definida pelo main.gd)
var logo: TextureRect
var subtitulo: Label
var botoes: VBoxContainer
var botao_jogar: Button
var botao_voltar: Button
var botao_retro: Button
var cursor: TextureRect
var painel_ajuda: Panel
var silencioso := false
var t := 0.0
var proximo_brilho := 0.5


func _ready() -> void:
	# faixa escura atrás do logo para ele se destacar do céu
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.22)
	sombra.position = Vector2(0, 0)
	sombra.size = Vector2(320, 88)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sombra)

	logo = TextureRect.new()
	logo.texture = load("res://assets/ui/logo.png")
	logo.position = Vector2((320 - logo.texture.get_width()) / 2.0, 2)
	logo.pivot_offset = logo.texture.get_size() / 2.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	subtitulo = _label("Ajude o Léo a salvar o Livro da Floresta!", 8, Color("e8fff0"),
		Vector2(0, 76), Vector2(320, 11))

	botoes = VBoxContainer.new()
	botoes.position = Vector2(105, 91)
	botoes.size = Vector2(110, 70)
	botoes.add_theme_constant_override("separation", 2)
	add_child(botoes)
	botao_jogar = _botao("Jogar", _ao_jogar)
	_botao("Como jogar", _abrir_ajuda)
	botao_retro = _botao("Modo retrô: não", _alternar_retro)
	_botao("Sair", _sair)
	atualizar_botao_retro()

	cursor = TextureRect.new()
	cursor.texture = load("res://assets/ui/cursor_leo.png")
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cursor)

	_label("M: som     R: modo retrô     ENTER: escolher", 7, Color("c8f0d8"), Vector2(0, 168), Vector2(320, 10))
	var versao := _label(VERSAO, 7, Color("9fd9b5"), Vector2(276, 168), Vector2(40, 10))
	versao.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_criar_ajuda()


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	# o logo "respira" e sobe e desce devagar
	logo.scale = Vector2.ONE * (1.0 + sin(t * 2.0) * 0.02)
	logo.position.y = 2.0 + sin(t * 1.3) * 1.5
	# brilhos aparecendo no logo de vez em quando
	proximo_brilho -= delta
	if proximo_brilho <= 0.0 and logo.visible:
		proximo_brilho = randf_range(0.25, 0.7)
		_brilho()
	_mover_cursor()
	if painel_ajuda.visible and Input.is_action_just_pressed("voltar"):
		_fechar_ajuda()


func mostrar() -> void:
	visible = true
	_fechar_ajuda()


func esconder() -> void:
	visible = false
	get_viewport().gui_release_focus()


func atualizar_botao_retro() -> void:
	if botao_retro and efeitos:
		botao_retro.text = "Modo retrô: sim" if efeitos.retro else "Modo retrô: não"


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


## Placa de madeira esticada como 9-slice (as bordas e os pregos não deformam).
func _placa(caminho: String, escurecer := false) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(caminho)
	s.set_texture_margin_all(6)
	s.set_content_margin_all(1)
	if escurecer:
		s.modulate_color = Color(0.85, 0.85, 0.85)
	return s


func _estilo(fundo: Color, borda: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	return s


func _estilizar(b: Button) -> void:
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_stylebox_override("normal", _placa("res://assets/ui/placa.png"))
	b.add_theme_stylebox_override("hover", _placa("res://assets/ui/placa_foco.png"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("pressed", _placa("res://assets/ui/placa_foco.png", true))
	b.add_theme_color_override("font_color", COR_TEXTO)
	b.add_theme_color_override("font_focus_color", COR_FOCO)
	b.add_theme_color_override("font_hover_color", COR_FOCO)
	b.add_theme_color_override("font_pressed_color", COR_FOCO)
	b.add_theme_color_override("font_outline_color", COR_CONTORNO)
	b.add_theme_constant_override("outline_size", 3)


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(110, 16)
	_estilizar(b)
	b.pressed.connect(acao)
	b.focus_entered.connect(_ao_focar.bind(b))
	b.mouse_entered.connect(b.grab_focus)
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
		"Letras erradas tiram pontos.\n" +
		"Esc: menu    M: som    R: modo retrô")
	texto.position = Vector2(14, 22)
	texto.size = Vector2(232, 98)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_size_override("font_size", 8)
	painel_ajuda.add_child(texto)

	botao_voltar = Button.new()
	botao_voltar.text = "Voltar"
	botao_voltar.position = Vector2(95, 124)
	botao_voltar.size = Vector2(70, 16)
	_estilizar(botao_voltar)
	botao_voltar.pressed.connect(_fechar_ajuda)
	painel_ajuda.add_child(botao_voltar)


# ---------------------------------------------------------------- animações

## A cabeça do Léo fica ao lado do botão selecionado, balançando.
func _mover_cursor() -> void:
	var foco := get_viewport().gui_get_focus_owner()
	cursor.visible = foco is Button and foco.is_visible_in_tree()
	if not cursor.visible:
		return
	var b: Button = foco
	var alvo := b.global_position + Vector2(-cursor.texture.get_width() - 4 + sin(t * 6.0) * 1.5,
		(b.size.y - cursor.texture.get_height()) / 2.0)
	cursor.position = cursor.position.lerp(alvo, 0.35) if cursor.position != Vector2.ZERO else alvo


func _brilho() -> void:
	var b := Control.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tam := logo.texture.get_size()
	b.position = logo.position + Vector2(randf_range(8, tam.x - 8), randf_range(10, tam.y - 14))
	for r in [Rect2(-2, 0, 5, 1), Rect2(0, -2, 1, 5)]:
		var c := ColorRect.new()
		c.color = Color("fffbe0")
		c.position = r.position
		c.size = r.size
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(c)
	add_child(b)
	var tw := b.create_tween()
	tw.tween_property(b, "modulate:a", 0.0, 0.5).from(1.0)
	tw.tween_callback(b.queue_free)


# ---------------------------------------------------------------- ações

func _ao_focar(b: Button) -> void:
	# o botão "pula" um pouquinho quando é selecionado
	b.pivot_offset = b.size / 2.0
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.15).from(Vector2(1.08, 1.08))
	if not silencioso and audio:
		audio.tocar("menu")


func _ao_jogar() -> void:
	jogar.emit()


func _abrir_ajuda() -> void:
	if audio:
		audio.tocar("menu")
	botoes.visible = false
	logo.visible = false
	subtitulo.visible = false
	painel_ajuda.visible = true
	botao_voltar.grab_focus()


func _fechar_ajuda() -> void:
	painel_ajuda.visible = false
	botoes.visible = true
	logo.visible = true
	subtitulo.visible = true
	silencioso = true
	botao_jogar.grab_focus()
	silencioso = false


func _alternar_retro() -> void:
	if efeitos:
		efeitos.alternar_retro()
		atualizar_botao_retro()


func _sair() -> void:
	get_tree().quit()
