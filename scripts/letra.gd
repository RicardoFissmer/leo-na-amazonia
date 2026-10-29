extends Area2D
## Uma letra flutuando que o Léo pode coletar.

signal coletada(letra: String, no: Area2D)

var letra := "A"
var base_y := 0.0
var t := 0.0


func _ready() -> void:
	var moeda := Sprite2D.new()
	moeda.texture = load("res://assets/coin.png")
	add_child(moeda)

	var rotulo := Label.new()
	rotulo.text = letra
	rotulo.add_theme_font_size_override("font_size", 10)
	rotulo.add_theme_color_override("font_color", Color("6b3e00"))
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.position = Vector2(-9, -9)
	rotulo.size = Vector2(18, 18)
	add_child(rotulo)

	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 7.0
	forma.shape = circulo
	add_child(forma)

	body_entered.connect(_ao_encostar)
	base_y = position.y
	t = randf() * TAU


func _process(delta: float) -> void:
	t += delta * 3.0
	position.y = base_y + sin(t) * 2.0


func _ao_encostar(corpo: Node2D) -> void:
	if corpo.has_method("machucar"):
		coletada.emit(letra, self)
