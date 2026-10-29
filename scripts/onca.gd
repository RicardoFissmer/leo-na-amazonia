extends Area2D
## A onça-pintada anda de um lado para o outro. Encostar nela tira uma vida.

const Util = preload("res://scripts/util.gd")

var limite_esq := 0.0
var limite_dir := 0.0
var velocidade := 28.0
var direcao := -1.0
var sprite: AnimatedSprite2D


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Util.frames("res://assets/onca.png", 20, 9, {
		"andando": [[0, 1], 6.0],
	})
	add_child(sprite)
	sprite.play("andando")
	add_child(Util.retangulo(Vector2(16, 7)))


func _physics_process(delta: float) -> void:
	position.x += direcao * velocidade * delta
	if position.x < limite_esq:
		position.x = limite_esq
		direcao = 1.0
	elif position.x > limite_dir:
		position.x = limite_dir
		direcao = -1.0
	sprite.flip_h = direcao > 0.0  # o desenho olha para a esquerda

	for corpo in get_overlapping_bodies():
		if corpo.has_method("machucar"):
			corpo.call("machucar", global_position.x, "a onça")
