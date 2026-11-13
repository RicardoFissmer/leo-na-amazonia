extends CanvasLayer
## Tutorial da fase 1: dicas que aparecem na hora certa, uma de cada vez,
## e somem quando o jogador faz o que a dica pede.
## Enquanto o Léo está na parte do tutorial, errar não tira vida (tentativa segura):
## ele volta para um ponto logo antes do obstáculo.

const TILE := 16
const CHAO_Y := 132.0      # y do Léo em pé no chão
const FIM_DA_ZONA := 38    # coluna do mapa onde termina a parte protegida

## Cada passo aparece quando o Léo chega na coluna "de" e some quando a condição "ate" acontece:
##   andou  = andou um pouco          letra = pegou uma letra certa (ou passou da coluna "x")
##   pulou  = pulou                   passou = passou da coluna "x"
##   tempo  = some depois de "seg" segundos
## [c]...[/c] destaca a palavra em amarelo.
const PASSOS := [
	{"de": 0, "ate": "andou",
		"texto": "Use as [c]SETAS[/c] ou as teclas [c]A[/c] e [c]D[/c] para andar."},
	{"de": 3, "ate": "letra", "x": 9,
		"texto": "Pegue a [c]moeda com letra[/c]! As letras formam o nome do animal da [c]dica[/c]."},
	{"de": 0, "ate": "tempo", "seg": 3.5,
		"texto": "Muito bem! As letras que você pega aparecem lá no alto da tela."},
	{"de": 6, "ate": "pulou",
		"texto": "Aperte [c]ESPAÇO[/c] para pular. Segure para pular mais alto!"},
	{"de": 11, "ate": "passou", "x": 17,
		"texto": "Um buraco! Chegue perto da beirada e pule por cima."},
	{"de": 17, "ate": "passou", "x": 28,
		"texto": "Uma [c]onça[/c]! Pule por cima dela ou espere ela se afastar."},
	{"de": 26, "ate": "passou", "x": 32,
		"texto": "[c]Bolhas[/c] no rio? A piranha vai pular! Espere ela mergulhar e pule."},
	{"de": 32, "ate": "passou", "x": 38,
		"texto": "A [c]cobra[/c] treme antes de descer. Passe quando ela subir!"},
	{"de": 38, "ate": "tempo", "seg": 4.0,
		"texto": "Agora é com você! Encontre todas as letras da palavra."},
]

var audio  # referência ao nó de áudio (definida pelo main.gd)

var ativo := false
var jogador: Node2D
var passo := 0
var mostrando := false
var tempo := 0.0
var inicio_x := 0.0
var pulou := false
var pegou_letra := false
var ponto_seguro := Vector2.ZERO

var painel: Panel
var rotulo: RichTextLabel


func _ready() -> void:
	layer = 4
	painel = Panel.new()
	painel.position = Vector2(8, 29)
	painel.size = Vector2(304, 24)
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.03, 0.15, 0.08, 0.92)
	estilo.border_color = Color("ffd21f")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)
	painel.add_theme_stylebox_override("panel", estilo)
	add_child(painel)

	rotulo = RichTextLabel.new()
	rotulo.bbcode_enabled = true
	rotulo.scroll_active = false
	rotulo.position = Vector2(4, 2)
	rotulo.size = Vector2(296, 20)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_font_size_override("normal_font_size", 8)
	painel.add_child(rotulo)
	painel.visible = false


## Começa o tutorial do zero com o Léo recém-criado.
func iniciar(novo_jogador: Node2D, inicio: Vector2) -> void:
	jogador = novo_jogador
	ativo = true
	passo = 0
	mostrando = false
	ponto_seguro = inicio
	inicio_x = inicio.x
	painel.visible = false


func parar() -> void:
	ativo = false
	painel.visible = false


func esconder() -> void:
	painel.visible = false


## True quando um erro nesse ponto do mapa não deve tirar vida.
func protege(x: float) -> bool:
	return ativo and x < FIM_DA_ZONA * TILE


func ao_pular() -> void:
	pulou = true


func ao_coletar(certa: bool) -> void:
	if certa:
		pegou_letra = true


func _process(delta: float) -> void:
	if not ativo or not is_instance_valid(jogador) or passo >= PASSOS.size():
		return
	var p: Dictionary = PASSOS[passo]
	var coluna := jogador.global_position.x / TILE
	if not mostrando:
		if coluna >= p["de"]:
			_mostrar(p)
		return

	tempo += delta
	# a borda pisca devagar para chamar a atenção
	var estilo: StyleBoxFlat = painel.get_theme_stylebox("panel")
	estilo.border_color = Color("ffd21f").lerp(Color("fff7c0"), (sin(tempo * 5.0) + 1.0) / 2.0)
	if _cumpriu(p, coluna):
		_concluir()


func _mostrar(p: Dictionary) -> void:
	mostrando = true
	tempo = 0.0
	pulou = false
	pegou_letra = false
	if p["de"] > 0:
		ponto_seguro = Vector2(p["de"] * TILE + 8, CHAO_Y)
	var texto: String = p["texto"]
	rotulo.text = "[center]%s[/center]" % texto.replace("[c]", "[color=#ffd21f]").replace("[/c]", "[/color]")
	painel.visible = true


func _cumpriu(p: Dictionary, coluna: float) -> bool:
	match p["ate"]:
		"andou":
			return absf(jogador.global_position.x - inicio_x) > 20.0
		"letra":
			return pegou_letra or coluna >= p["x"]
		"pulou":
			return pulou
		"passou":
			return coluna >= p["x"]
		"tempo":
			return tempo >= p["seg"]
	return false


func _concluir() -> void:
	var era_tempo: bool = PASSOS[passo]["ate"] == "tempo"
	if audio and not era_tempo:
		audio.tocar("menu")
	passo += 1
	mostrando = false
	painel.visible = false
