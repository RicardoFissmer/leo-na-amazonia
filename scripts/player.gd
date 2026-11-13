extends CharacterBody2D
## O Léo: anda, pula e pode se machucar.
## Sprite de 16x24 (assets/leo.png, gerado por tools/gerar_leo.py) com animações de parado, corrida,
## pulo, queda, dano e comemoração. O corpo estica no pulo, achata ao aterrissar e levanta poeira.

signal caiu        ## caiu num buraco ou na água
signal machucado(quem: String)  ## encostou num bicho perigoso
signal pulou

const Util = preload("res://scripts/util.gd")

const VELOCIDADE := 90.0
const PULO := -265.0
const GRAVIDADE := 700.0
const QUEDA_MAXIMA := 400.0
const COYOTE := 0.1        # tempo extra para pular logo depois de sair da beirada
const BUFFER_PULO := 0.12  # apertar o pulo um pouco antes de tocar o chão também vale
const PES := 12.0          # distância do centro do Léo até a sola do tênis

var travado := false
var comemorando := false   # fica de braços para cima (ex.: juntou todas as letras)
var sprite: AnimatedSprite2D
var tempo_no_ar := 0.0
var pulo_guardado := 0.0
var invencivel := 0.0
var empurrao := 0.0
var espera_inicio := 0.2
var caido := false
var estava_no_chao := true
var velocidade_queda := 0.0
var tempo_poeira := 0.0


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Util.frames("res://assets/leo.png", 16, 24, {
		# respira devagar e pisca de vez em quando
		"parado": [[0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 2], 4.0],
		"andando": [[3, 4, 5, 6, 7, 8], 12.0],
		"pulando": [[9], 1.0],
		"caindo": [[10], 1.0],
		"machucado": [[11], 1.0],
		"comemorando": [[12, 0], 3.0],
	})
	add_child(sprite)
	sprite.play("parado")

	var forma := Util.retangulo(Vector2(10, 21))
	forma.position = Vector2(0, PES - 10.5)
	add_child(forma)


func _physics_process(delta: float) -> void:
	espera_inicio = maxf(espera_inicio - delta, 0.0)
	pulo_guardado = maxf(pulo_guardado - delta, 0.0)

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
		velocidade_queda = velocity.y

	var dir := 0.0
	if not travado and espera_inicio <= 0.0:
		dir = Input.get_axis("esquerda", "direita")
		if Input.is_action_just_pressed("pular"):
			pulo_guardado = BUFFER_PULO
		if pulo_guardado > 0.0 and tempo_no_ar < COYOTE:
			_pular()
		# soltar o botão cedo = pulo mais baixo
		if Input.is_action_just_released("pular") and velocity.y < -80.0:
			velocity.y = -80.0

	if empurrao > 0.0:
		empurrao -= delta
	else:
		velocity.x = dir * VELOCIDADE

	move_and_slide()

	# aterrissou: achata e levanta poeira (mais forte se caiu de alto)
	var no_chao := is_on_floor()
	if no_chao and not estava_no_chao:
		var forca := clampf(velocidade_queda / QUEDA_MAXIMA, 0.3, 1.0)
		_esticar(Vector2(1.0 + 0.25 * forca, 1.0 - 0.25 * forca))
		_poeira(int(4 + 6 * forca), 30.0)
	estava_no_chao = no_chao

	# poeirinha dos pés enquanto corre
	tempo_poeira -= delta
	if no_chao and dir != 0.0 and tempo_poeira <= 0.0:
		tempo_poeira = 0.25
		_poeira(2, 15.0, -signf(dir))

	_animar(dir)
	# o corpo volta ao normal aos poucos depois de esticar/achatar
	sprite.scale = sprite.scale.lerp(Vector2.ONE, minf(1.0, delta * 14.0))
	sprite.position.y = PES * (1.0 - sprite.scale.y)

	if global_position.y > 200.0:
		cair()


func _pular() -> void:
	velocity.y = PULO
	tempo_no_ar = COYOTE
	pulo_guardado = 0.0
	_esticar(Vector2(0.8, 1.2))
	_poeira(5, 25.0)
	pulou.emit()


func _esticar(escala: Vector2) -> void:
	sprite.scale = escala


## Nuvem de poeira saindo dos pés. `lado` = 0 espalha para os dois lados.
func _poeira(quantidade: int, velocidade: float, lado := 0.0) -> void:
	if not is_inside_tree() or get_parent() == null:
		return
	var p := CPUParticles2D.new()
	p.position = position + Vector2(0, PES - 1)
	p.one_shot = true
	p.emitting = true
	p.amount = quantidade
	p.lifetime = 0.45
	p.explosiveness = 0.9
	p.direction = Vector2(lado, -0.6) if lado != 0.0 else Vector2(0, -1)
	p.spread = 35.0 if lado != 0.0 else 80.0
	p.initial_velocity_min = velocidade * 0.5
	p.initial_velocity_max = velocidade
	p.gravity = Vector2(0, 40)
	p.damping_min = 30.0
	p.damping_max = 50.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	var cores := Gradient.new()
	cores.set_color(0, Color(0.93, 0.86, 0.72, 0.9))
	cores.set_color(1, Color(0.93, 0.86, 0.72, 0.0))
	p.color_ramp = cores
	get_parent().add_child(p)
	p.finished.connect(p.queue_free)


func cair() -> void:
	if caido:
		return
	caido = true
	caiu.emit()


func _animar(dir: float) -> void:
	if dir != 0.0:
		sprite.flip_h = dir < 0.0
	var anim := "parado"
	if comemorando:
		anim = "comemorando"
	elif empurrao > 0.0:
		anim = "machucado"
	elif not is_on_floor():
		anim = "pulando" if velocity.y < 0.0 else "caindo"
	elif dir != 0.0:
		anim = "andando"
	if sprite.animation != anim:
		sprite.play(anim)


## Chamado pela onça, cobra ou piranha. Retorna true se o Léo realmente se machucou.
func machucar(origem_x: float, quem := "a onça") -> bool:
	if invencivel > 0.0 or travado:
		return false
	invencivel = 1.2
	empurrao = 0.3
	var lado := signf(global_position.x - origem_x)
	if lado == 0.0:
		lado = -1.0
	velocity = Vector2(lado * 120.0, -160.0)
	sprite.flip_h = lado > 0.0  # vira o rosto para o bicho que o machucou
	_esticar(Vector2(1.2, 0.85))
	machucado.emit(quem)
	return true


func reaparecer(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	caido = false
	invencivel = 1.0
	espera_inicio = 0.2
	estava_no_chao = true
