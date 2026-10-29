extends Node2D
## Arara voando no céu (só enfeite).

const Util = preload("res://scripts/util.gd")

var velocidade := 30.0
var base_y := 40.0
var t := 0.0


func _ready() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = Util.frames("res://assets/arara.png", 12, 8, {
		"voando": [[0, 1], 6.0],
	})
	add_child(sprite)
	sprite.play("voando")
	t = randf() * TAU


func _process(delta: float) -> void:
	t += delta
	position.x += velocidade * delta
	position.y = base_y + sin(t * 2.0) * 4.0
	var cam := get_viewport().get_camera_2d()
	if cam and position.x > cam.get_screen_center_position().x + 180.0:
		position.x = cam.get_screen_center_position().x - 180.0
