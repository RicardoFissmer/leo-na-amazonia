extends Area2D
## Cobra pendurada embaixo de um tronco. Fica escondida, treme um pouco (aviso),
## desce de repente até a altura do Léo e depois sobe de novo.

const Util = preload("res://scripts/util.gd")

const ESCONDIDA := 1.8
const AVISO := 0.6
const DESCENDO := 0.2
const EMBAIXO := 1.0
const SUBINDO := 0.7
const ALTO := -4.0    # posição da cabeça escondida (dentro do tronco)
const BAIXO := 16.0   # posição da cabeça esticada (na altura do Léo)

var fase := "escondida"
var tempo := 0.0
var descida := 0.0  # 0 = escondida, 1 = toda esticada
var corpo: Sprite2D
var cabeca: AnimatedSprite2D
var forma: CollisionShape2D


func _ready() -> void:
	corpo = Sprite2D.new()
	corpo.texture = load("res://assets/cobra_corpo.png")
	corpo.centered = false
	corpo.region_enabled = true
	corpo.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	corpo.position = Vector2(-3, -6)
	add_child(corpo)

	cabeca = AnimatedSprite2D.new()
	cabeca.sprite_frames = Util.frames("res://assets/cobra_cabeca.png", 10, 10, {
		"parada": [[0], 1.0],
		"lingua": [[0, 1], 6.0],
	})
	cabeca.play("parada")
	add_child(cabeca)

	forma = Util.retangulo(Vector2(7, 8))
	add_child(forma)

	# cada cobra começa num momento diferente para não ficarem sincronizadas
	tempo = randf() * ESCONDIDA
	_posicionar(0.0)


func _physics_process(delta: float) -> void:
	tempo += delta
	match fase:
		"escondida":
			descida = 0.0
			if tempo >= ESCONDIDA:
				_mudar("aviso")
		"aviso":
			descida = 0.12
			if tempo >= AVISO:
				_mudar("descendo")
		"descendo":
			descida = minf(tempo / DESCENDO, 1.0)
			if tempo >= DESCENDO:
				_mudar("embaixo")
				cabeca.play("lingua")
		"embaixo":
			descida = 1.0
			if tempo >= EMBAIXO:
				_mudar("subindo")
				cabeca.play("parada")
		"subindo":
			descida = 1.0 - minf(tempo / SUBINDO, 1.0)
			if tempo >= SUBINDO:
				_mudar("escondida")

	# tremidinha durante o aviso
	var tremor := 0.0
	if fase == "aviso":
		tremor = 1.0 if int(tempo * 16.0) % 2 == 0 else -1.0
	_posicionar(tremor)

	# só machuca quando está para fora do tronco
	if descida > 0.4:
		for corpo_tocado in get_overlapping_bodies():
			if corpo_tocado.has_method("machucar"):
				corpo_tocado.call("machucar", global_position.x, "a cobra")


func _mudar(nova: String) -> void:
	fase = nova
	tempo = 0.0


func _posicionar(tremor: float) -> void:
	var y := lerpf(ALTO, BAIXO, descida)
	cabeca.position = Vector2(tremor, y)
	forma.position = Vector2(0, y)
	corpo.region_rect = Rect2(0, 0, 6, maxf(y + 2.0, 0.0))
