extends CanvasLayer
## Desafio "Verdadeiro ou falso?": depois de montar a palavra, o jogador lê
## algumas afirmações sobre o animal da fase e diz se são verdadeiras ou falsas.

signal concluido(acertos: int)

const PONTOS := 20  # pontos por resposta certa
const COR_V := Color("2f9e44")
const COR_F := Color("c92a2a")
const COR_SLOT := Color(0.05, 0.2, 0.12)

var audio  # referência ao nó de áudio (definida pelo main.gd)

var perguntas: Array = []  # cada uma: [texto, é verdade?, explicação]
var atual := 0
var acertos := 0
var respondida := false
var sessao := 0
var rodape_final := ""

var titulo: Label
var contador: Label
var imagem: TextureRect
var texto: Label
var linha_botoes: HBoxContainer
var botao_v: Button
var botao_f: Button
var retorno: Label
var botao_continuar: Button
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
	var estilo := _estilo(Color("163d28"), Color("ffd21f"), 2)
	estilo.set_corner_radius_all(6)
	caixa.add_theme_stylebox_override("panel", estilo)
	add_child(caixa)

	titulo = _label(caixa, Vector2(0, 3), Vector2(288, 15), 11, Color("ffd21f"))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contador = _label(caixa, Vector2(234, 3), Vector2(46, 15), 8, Color("9fd9b5"))
	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var moldura := Panel.new()
	moldura.position = Vector2(10, 20)
	moldura.size = Vector2(100, 76)
	moldura.add_theme_stylebox_override("panel", _estilo(Color("2a6b41"), Color("0e3322")))
	caixa.add_child(moldura)
	imagem = TextureRect.new()
	imagem.position = Vector2(2, 2)
	imagem.size = Vector2(96, 72)
	moldura.add_child(imagem)

	texto = _label(caixa, Vector2(118, 20), Vector2(160, 76), 10, Color.WHITE)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	linha_botoes = HBoxContainer.new()
	linha_botoes.position = Vector2(0, 102)
	linha_botoes.size = Vector2(288, 22)
	linha_botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	linha_botoes.add_theme_constant_override("separation", 12)
	caixa.add_child(linha_botoes)
	botao_v = _botao("VERDADEIRO", Vector2(100, 22), 10)
	botao_v.pressed.connect(_responder.bind(true))
	linha_botoes.add_child(botao_v)
	botao_f = _botao("FALSO", Vector2(100, 22), 10)
	botao_f.pressed.connect(_responder.bind(false))
	linha_botoes.add_child(botao_f)

	retorno = _label(caixa, Vector2(10, 127), Vector2(268, 24), 8, Color.WHITE)
	retorno.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	retorno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var linha_continuar := HBoxContainer.new()
	linha_continuar.position = Vector2(0, 152)
	linha_continuar.size = Vector2(288, 14)
	linha_continuar.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa.add_child(linha_continuar)
	botao_continuar = _botao("Próxima", Vector2(70, 14), 8)
	_pintar(botao_continuar, COR_SLOT, Color("ffd21f"))
	# margens internas pequenas para o botão caber na caixa
	for estado in ["normal", "hover", "pressed", "disabled", "focus"]:
		var e: StyleBoxFlat = botao_continuar.get_theme_stylebox(estado)
		e.set_content_margin_all(0)
	botao_continuar.pressed.connect(_proxima)
	linha_continuar.add_child(botao_continuar)

	rodape = _label(caixa, Vector2(0, 154), Vector2(288, 12), 7, Color("9fd9b5"))
	rodape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Abre o desafio com as afirmações sorteadas para o animal da fase.
func abrir(lista: Array, tex: Texture2D, ultima: bool) -> void:
	sessao += 1
	perguntas = lista
	atual = 0
	acertos = 0
	imagem.texture = tex
	rodape_final = ("Você completou todas as palavras! ENTER: menu" if ultima
		else "Aperte ENTER para a próxima fase")
	visible = true
	_mostrar_pergunta()


func fechar() -> void:
	sessao += 1
	visible = false
	get_viewport().gui_release_focus()


# ---------------------------------------------------------------- ações

func _mostrar_pergunta() -> void:
	respondida = false
	titulo.text = "Verdadeiro ou falso?"
	contador.text = "%d/%d" % [atual + 1, perguntas.size()]
	texto.text = perguntas[atual][0]
	retorno.text = ""
	linha_botoes.visible = true
	_pintar(botao_v, COR_V, COR_V.lightened(0.4))
	_pintar(botao_f, COR_F, COR_F.lightened(0.4))
	# os botões só respondem depois de um instante, para o ENTER que abriu
	# a tela não responder a primeira pergunta sem querer
	botao_v.disabled = true
	botao_f.disabled = true
	botao_continuar.visible = false
	rodape.visible = true
	rodape.text = "Clique na resposta ou use setas + ENTER."
	_depois(0.25, _liberar_resposta)


func _liberar_resposta() -> void:
	botao_v.disabled = false
	botao_f.disabled = false
	botao_v.grab_focus()


func _responder(resposta: bool) -> void:
	if respondida:
		return
	respondida = true
	var p: Array = perguntas[atual]
	var verdade: bool = p[1]
	var certo := resposta == verdade
	if certo:
		acertos += 1
		retorno.text = "Isso mesmo! " + p[2]
		retorno.add_theme_color_override("font_color", Color("9ff0b0"))
		if audio:
			audio.tocar("letra")
	else:
		retorno.text = "Ops! É %s. %s" % ["verdadeiro" if verdade else "falso", p[2]]
		retorno.add_theme_color_override("font_color", Color("ffb3a8"))
		if audio:
			audio.tocar("erro")

	# a resposta certa fica acesa com borda branca; a outra fica apagada
	var botao_certo := botao_v if verdade else botao_f
	var botao_outro := botao_f if verdade else botao_v
	var cor_certa := COR_V if verdade else COR_F
	botao_certo.add_theme_stylebox_override("disabled", _estilo(cor_certa, Color.WHITE, 2))
	botao_outro.add_theme_stylebox_override("disabled", _estilo(Color(0, 0, 0, 0.25), Color(1, 1, 1, 0.15)))
	botao_v.disabled = true
	botao_f.disabled = true

	rodape.visible = false
	botao_continuar.text = "Próxima" if atual < perguntas.size() - 1 else "Resultado"
	_depois(0.3, _mostrar_continuar)


func _mostrar_continuar() -> void:
	botao_continuar.visible = true
	botao_continuar.grab_focus()


func _proxima() -> void:
	if not botao_continuar.visible:
		return
	botao_continuar.visible = false
	atual += 1
	if atual < perguntas.size():
		_mostrar_pergunta()
	else:
		_resultado()


func _resultado() -> void:
	var total := perguntas.size()
	titulo.text = "Fim do desafio!"
	contador.text = ""
	linha_botoes.visible = false
	retorno.text = ""
	var frase := "Tudo bem, da próxima vez você acerta!"
	if acertos == total:
		frase = "Você é especialista em Amazônia!"
	elif acertos > 0:
		frase = "Muito bom!"
	texto.text = "Você acertou %d de %d!\n%s\n+%d pontos" % [acertos, total, frase, acertos * PONTOS]
	rodape.visible = true
	rodape.text = rodape_final
	get_viewport().gui_release_focus()
	if audio:
		audio.tocar("vitoria" if acertos == total else "comecar")
	concluido.emit(acertos)


## Chama `funcao` depois de `seg` segundos, se a tela não tiver sido fechada/reaberta.
func _depois(seg: float, funcao: Callable) -> void:
	var minha_sessao := sessao
	var minha_pergunta := atual
	await get_tree().create_timer(seg).timeout
	if minha_sessao == sessao and minha_pergunta == atual:
		funcao.call()


# ---------------------------------------------------------------- aparência

func _botao(rotulo: String, tam: Vector2, fonte: int) -> Button:
	var b := Button.new()
	b.text = rotulo
	b.custom_minimum_size = tam
	b.size = tam
	b.add_theme_font_size_override("font_size", fonte)
	for estado in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color",
			"font_disabled_color"]:
		b.add_theme_color_override(estado, Color.WHITE)
	return b


func _pintar(botao: Button, fundo: Color, borda: Color) -> void:
	botao.add_theme_stylebox_override("normal", _estilo(fundo, borda))
	botao.add_theme_stylebox_override("hover", _estilo(fundo.lightened(0.15), Color("ffd21f")))
	botao.add_theme_stylebox_override("pressed", _estilo(fundo.lightened(0.25), Color("ffd21f")))
	botao.add_theme_stylebox_override("disabled", _estilo(fundo, borda))
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
