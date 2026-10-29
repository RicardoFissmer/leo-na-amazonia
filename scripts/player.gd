extends CharacterBody2D
## O Léo: anda, pula e pode se machucar.

signal caiu        ## caiu num buraco ou na água
signal machucado(quem: String)  ## encostou num bicho perigoso
signal pulou

const Util = preload("res://scripts/util.gd")

const VELOCIDADE := 90.0
const PULO := -265.0
const GRAVIDADE := 700.0
const QUEDA_MAXIMA := 400.0
const COYOTE := 0.1  # tempo extra para pular logo depois de sair da beirada

var travado := false
var sprite: AnimatedSprite2D
var tempo_no_ar := 0.0
var invencivel := 0.0
var empurrao := 0.0
var espera_inicio := 0.2
var caido := false


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Util.frames("res://assets/leo.png", 12, 16, {
		"parado": [[0], 1.0],
		"andando": [[0, 1], 8.0],
		"pulando": [[2], 1.0],
	})
	add_child(sprite)
	sprite.play("parado")

	var forma := Util.retangulo(Vector2(8, 15))
	forma.position = Vector2(0, 0.5)
	add_child(forma)


func _physics_process(delta: float) -> void:
	espera_inicio = maxf(espera_inicio - delta, 0.0)

	# piscar enquanto está invencível
	if invencivel > 0.0:
		invencivel -= delta
		sprite.visible = invencivel <= 0.0 or int(invencivel * 20.0) % 2 == 0

	# gravidade
	if is_on_floor():
		tempo_no_ar = 0.0
	else:
		velocity.y = minf(velocity.y + GRAVIDADE * delta, QUEDA_MAXIMA)
		tempo_no_ar += delta

	var dir := 0.0
	if not travado and espera_inicio <= 0.0:
		dir = Input.get_axis("esquerda", "direita")
		if Input.is_action_just_pressed("pular") and tempo_no_ar < COYOTE:
			velocity.y = PULO
			tempo_no_ar = COYOTE
			pulou.emit()
		# soltar o botão cedo = pulo mais baixo
		if Input.is_action_just_released("pular") and velocity.y < -80.0:
			velocity.y = -80.0

	if empurrao > 0.0:
		empurrao -= delta
	else:
		velocity.x = dir * VELOCIDADE

	move_and_slide()
	_animar(dir)

	if global_position.y > 200.0:
		cair()


func cair() -> void:
	if caido:
		return
	caido = true
	caiu.emit()


func _animar(dir: float) -> void:
	if dir != 0.0:
		sprite.flip_h = dir < 0.0
	if not is_on_floor():
		sprite.play("pulando")
	elif dir != 0.0:
		sprite.play("andando")
	else:
		sprite.play("parado")


## Chamado pela onça, cobra ou piranha. Retorna true se o Léo realmente se machucou.
func machucar(origem_x: float, quem := "a onça") -> bool:
	if invencivel > 0.0 or travado:
		return false
	invencivel = 1.2
	empurrao = 0.25
	var lado := signf(global_position.x - origem_x)
	if lado == 0.0:
		lado = -1.0
	velocity = Vector2(lado * 120.0, -160.0)
	machucado.emit(quem)
	return true


func reaparecer(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	caido = false
	invencivel = 1.0
	espera_inicio = 0.2
