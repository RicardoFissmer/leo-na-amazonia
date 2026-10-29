extends Area2D
## Piranha que mora no rio. De tempos em tempos aparecem bolhas (aviso)
## e ela pula para fora da água. Encostar nela tira uma vida.

const Util = preload("res://scripts/util.gd")

const GRAVIDADE := 500.0
const PULO := 240.0        # velocidade do pulo (sobe uns 3 blocos e meio)
const AVISO := 0.6
const ESPERA_MIN := 1.4
const ESPERA_MAX := 2.4
const FUNDO := 14.0        # profundidade em que ela fica escondida

var superficie := 0.0      # y da superfície da água (definido pelo main.gd)
var fase := "esperando"
var tempo := 0.0
var espera := 0.0
var vel_y := 0.0
var sprite: AnimatedSprite2D
var bolhas: AnimatedSprite2D


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Util.frames("res://assets/piranha.png", 14, 11, {
		"nadando": [[0, 1], 8.0],
	})
	sprite.play("nadando")
	add_child(sprite)
	add_child(Util.retangulo(Vector2(10, 8)))

	bolhas = AnimatedSprite2D.new()
	bolhas.sprite_frames = Util.frames("res://assets/bolhas.png", 12, 6, {
		"subindo": [[0, 1], 8.0],
	})
	bolhas.play("subindo")
	bolhas.top_level = true  # fica parada na superfície enquanto a piranha se move
	add_child(bolhas)

	position.y = superficie + FUNDO
	espera = randf_range(0.5, ESPERA_MAX)
	_atualizar_visual()


func _physics_process(delta: float) -> void:
	tempo += delta
	match fase:
		"esperando":
			if tempo >= espera:
				_mudar("aviso")
		"aviso":
			if tempo >= AVISO:
				_mudar("pulando")
				vel_y = -PULO
				_respingo()
		"pulando":
			vel_y += GRAVIDADE * delta
			position.y += vel_y * delta
			if vel_y > 0.0 and position.y >= superficie + FUNDO:
				position.y = superficie + FUNDO
				_respingo()
				espera = randf_range(ESPERA_MIN, ESPERA_MAX)
				_mudar("esperando")

	_atualizar_visual()

	if fora_da_agua():
		for corpo in get_overlapping_bodies():
			if corpo.has_method("machucar"):
				corpo.call("machucar", global_position.x, "a piranha")


func fora_da_agua() -> bool:
	return position.y < superficie + 2.0


func _mudar(nova: String) -> void:
	fase = nova
	tempo = 0.0


func _atualizar_visual() -> void:
	sprite.visible = position.y < superficie + 6.0
	# vira para cima quando sobe e para baixo quando cai
	sprite.rotation = clampf(vel_y / PULO, -1.0, 1.0) * PI / 2.0
	bolhas.visible = fase == "aviso"
	bolhas.global_position = Vector2(global_position.x, get_parent().global_position.y + superficie - 1.0)


func _respingo() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(position.x, superficie)
	p.one_shot = true
	p.emitting = true
	p.amount = 10
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 50.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 80.0
	p.gravity = Vector2(0, 300)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color("d6f2ff")
	get_parent().add_child(p)
	p.finished.connect(p.queue_free)
