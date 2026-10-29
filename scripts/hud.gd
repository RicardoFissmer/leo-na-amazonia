extends CanvasLayer
## Interface: palavra, dica, vidas, pontos, mensagens e painel de fim de fase.

var rotulo_palavra: RichTextLabel
var rotulo_dica: Label
var rotulo_pontos: Label
var rotulo_msg: Label
var coracoes: Array[TextureRect] = []
var painel: Control
var painel_palavra: Label
var painel_fato: Label
var painel_rodape: Label
var tempo_msg := 0.0


func _ready() -> void:
	var barra := ColorRect.new()
	barra.color = Color(0, 0, 0, 0.55)
	barra.size = Vector2(320, 16)
	add_child(barra)

	var faixa_dica := ColorRect.new()
	faixa_dica.color = Color(0, 0, 0, 0.3)
	faixa_dica.position = Vector2(0, 16)
	faixa_dica.size = Vector2(320, 11)
	add_child(faixa_dica)

	rotulo_palavra = RichTextLabel.new()
	rotulo_palavra.bbcode_enabled = true
	rotulo_palavra.scroll_active = false
	rotulo_palavra.autowrap_mode = TextServer.AUTOWRAP_OFF
	rotulo_palavra.add_theme_font_size_override("normal_font_size", 9)
	rotulo_palavra.position = Vector2(5, 2)
	rotulo_palavra.size = Vector2(200, 14)
	add_child(rotulo_palavra)

	rotulo_dica = _label(Vector2(5, 16), Vector2(310, 11), 7, Color("c8f0d8"))

	var heart: Texture2D = load("res://assets/heart.png")
	for i in 3:
		var c := TextureRect.new()
		c.texture = heart
		c.position = Vector2(228 + i * 10, 5)
		add_child(c)
		coracoes.append(c)

	rotulo_pontos = _label(Vector2(262, 2), Vector2(54, 12), 9, Color("ffd21f"))
	rotulo_pontos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	rotulo_msg = _label(Vector2(0, 40), Vector2(320, 16), 10, Color.WHITE)
	rotulo_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo_msg.add_theme_constant_override("outline_size", 3)
	rotulo_msg.add_theme_color_override("font_outline_color", Color.BLACK)

	_criar_painel()


func _label(pos: Vector2, tam: Vector2, fonte: int, cor: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = tam
	l.add_theme_font_size_override("font_size", fonte)
	l.add_theme_color_override("font_color", cor)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(l)
	return l


func _criar_painel() -> void:
	painel = Control.new()
	painel.size = Vector2(320, 180)
	painel.visible = false
	add_child(painel)

	var escuro := ColorRect.new()
	escuro.color = Color(0, 0, 0, 0.5)
	escuro.size = Vector2(320, 180)
	painel.add_child(escuro)

	var caixa := Panel.new()
	caixa.position = Vector2(40, 30)
	caixa.size = Vector2(240, 120)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("163d28")
	estilo.border_color = Color("ffd21f")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(6)
	caixa.add_theme_stylebox_override("panel", estilo)
	painel.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "Muito bem!"
	titulo.position = Vector2(0, 6)
	titulo.size = Vector2(240, 14)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 10)
	caixa.add_child(titulo)

	painel_palavra = Label.new()
	painel_palavra.position = Vector2(0, 20)
	painel_palavra.size = Vector2(240, 26)
	painel_palavra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	painel_palavra.add_theme_font_size_override("font_size", 20)
	painel_palavra.add_theme_color_override("font_color", Color("ffd21f"))
	caixa.add_child(painel_palavra)

	painel_fato = Label.new()
	painel_fato.position = Vector2(12, 50)
	painel_fato.size = Vector2(216, 46)
	painel_fato.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	painel_fato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	painel_fato.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	painel_fato.add_theme_font_size_override("font_size", 8)
	caixa.add_child(painel_fato)

	painel_rodape = Label.new()
	painel_rodape.position = Vector2(0, 100)
	painel_rodape.size = Vector2(240, 14)
	painel_rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	painel_rodape.add_theme_font_size_override("font_size", 7)
	painel_rodape.add_theme_color_override("font_color", Color("9fd9b5"))
	caixa.add_child(painel_rodape)


func _process(delta: float) -> void:
	if tempo_msg > 0.0:
		tempo_msg -= delta
		rotulo_msg.visible = tempo_msg > 0.0


func atualizar(coletadas: Array[String], total: int, dica: String, vidas: int, pontos: int) -> void:
	var texto := "LETRAS:  "
	for c in coletadas:
		texto += "[color=#ffd21f]%s[/color] " % c
	for i in total - coletadas.size():
		texto += "[color=#8aa39a]_[/color] "
	rotulo_palavra.text = texto
	rotulo_dica.text = "Dica: " + dica
	for i in coracoes.size():
		coracoes[i].visible = i < vidas
	rotulo_pontos.text = str(pontos)


func mensagem(texto: String, duracao := 1.5) -> void:
	rotulo_msg.text = texto
	rotulo_msg.visible = true
	tempo_msg = duracao


func mostrar_painel(palavra: String, fato: String, ultima: bool) -> void:
	painel_palavra.text = palavra
	painel_fato.text = fato
	if ultima:
		painel_rodape.text = "Você completou todas as palavras! ENTER: menu"
	else:
		painel_rodape.text = "Aperte ENTER para a próxima fase"
	painel.visible = true


func esconder_painel() -> void:
	painel.visible = false
