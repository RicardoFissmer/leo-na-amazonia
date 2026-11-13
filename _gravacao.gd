extends Node
## TEMPORÁRIO (só para gravar o vídeo): joga cenas do jogo sozinho e marca os momentos importantes.
## Uso: Godot --path . --fixed-fps 30 --write-movie video/gravacoes/<cena>/f.png res://_gravacao.tscn -- --cena=<cena>

var main
var cena := "menu"
var quadro0 := 0
var marcas := {}
var piloto := false
var segurando_pulo := 0.0
var tempo_parado := 0.0


func _ready() -> void:
	seed(2026)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cena="):
			cena = a.substr(7)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	quadro0 = Engine.get_process_frames()
	await get_tree().process_frame
	# gravação sempre sem modo retrô e sem a música (a trilha do vídeo é feita à parte)
	main.efeitos.retro = false
	main.efeitos._aplicar_retro()
	main.titulo.atualizar_botao_retro()
	main.audio.musica.stop()
	await call(cena)
	_salvar_marcas()
	get_tree().quit()


func _marca(nome: String) -> void:
	marcas[nome] = Engine.get_process_frames() - quadro0
	print("marca ", nome, " = ", marcas[nome])


func _salvar_marcas() -> void:
	var f := FileAccess.open("res://video/gravacoes/%s/marcas.json" % cena, FileAccess.WRITE)
	f.store_string(JSON.stringify(marcas, "  "))


func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout


func _tecla(codigo: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = codigo
	ev.keycode = codigo
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var solta := ev.duplicate()
	solta.pressed = false
	Input.parse_input_event(solta)
	await get_tree().process_frame


func _fase(n: int, com_tutorial := false, com_dano := false) -> void:
	main.titulo.esconder()
	main._comecar_primeira_fase()
	if not com_tutorial:
		main.tutorial_concluido = true
		main.tutorial.parar()
	if n != 0:
		main.carregar_nivel(n)
	await _esperar(0.2)
	if not com_dano:
		_sem_dano()


## Só para a gravação: os bichos continuam se mexendo, mas encostar neles não machuca.
func _sem_dano() -> void:
	for n in main.mundo.get_children():
		if n.get_script() in [main.Onca, main.Cobra, main.Piranha]:
			n.collision_mask = 0


# ---------------------------------------------------------------- piloto automático

func _physics_process(delta: float) -> void:
	if not piloto or not is_instance_valid(main.jogador):
		return
	var j = main.jogador
	var x: float = j.global_position.x
	var no_chao: bool = j.is_on_floor()
	var ir := true
	var pular := false
	# buraco ou rio logo à frente
	var col_pe := int(floor((x + 9.0) / 16.0))
	var na_beirada: bool = no_chao and main._tile(col_pe, 9) != "#"
	if na_beirada:
		pular = true
	# coreografia: quando o Léo chega no trecho da onça, ela vem na direção dele para o pulo ficar bonito
	for n in main.mundo.get_children():
		if n.get_script() == main.Onca and not n.has_meta("coreografada") and no_chao:
			var dxo: float = n.global_position.x - x
			if dxo > -40.0 and dxo < 130.0 and x > n.limite_esq - 8.0:
				n.position.x = clampf(x + 80.0, n.limite_esq, n.limite_dir)
				n.direcao = -1.0
				n.set_meta("coreografada", true)
	for n in main.mundo.get_children():
		var s = n.get_script()
		var dx: float = n.global_position.x - x
		if s == main.Onca and dx > 0.0 and absf(n.global_position.y - j.global_position.y) < 20.0:
			# pula quando a onça está perto (mais cedo se ela vem na direção do Léo)
			var perto := 30.0 if n.direcao < 0.0 else 20.0
			if no_chao and dx < perto:
				pular = true
		elif s == main.Letra and no_chao and dx > 4.0 and dx < 16.0 and not main.faltando.has(n.letra) 				and absf(n.global_position.y - j.global_position.y) < 12.0:
			pular = true  # pula por cima das letras erradas
		elif s == main.Cobra and dx > 2.0 and dx < 34.0:
			if n.fase in ["aviso", "descendo", "embaixo"] or (n.fase == "escondida" and n.tempo > n.ESCONDIDA - 0.8):
				ir = false
		elif s == main.Piranha and dx > 0.0 and dx < 52.0 and no_chao:
			# espera a piranha pular e começar a cair de volta; aí atravessa
			if not (n.fase == "pulando" and n.vel_y > 40.0):
				ir = false
				pular = false
	if ir:
		Input.action_press("direita")
	else:
		Input.action_release("direita")
	segurando_pulo -= delta
	if pular and segurando_pulo <= -0.05:
		Input.action_press("pular")
		segurando_pulo = 0.3
	elif segurando_pulo <= 0.0:
		Input.action_release("pular")


func _parar_piloto() -> void:
	piloto = false
	Input.action_release("direita")
	Input.action_release("pular")


func _ate_coluna(col: float, limite := 20.0) -> void:
	var t := 0.0
	while main.jogador.global_position.x < col * 16.0 and t < limite:
		await get_tree().process_frame
		t += get_process_delta_time()


# ---------------------------------------------------------------- cenas

func menu() -> void:
	await _esperar(1.6)
	_marca("baixo")
	await _tecla(KEY_DOWN)
	await _esperar(1.0)
	await _tecla(KEY_UP)
	await _esperar(3.0)
	_marca("fim")


func historia() -> void:
	await _esperar(0.5)
	_marca("jogar")
	main.iniciar_jogo()
	await _esperar(0.6)
	for i in 3:
		_marca("pagina%d" % (i + 1))
		await _esperar(3.4)
		main.historia._avancar()
		await _esperar(0.1)
		if main.historia.texto.visible_characters >= 0:
			main.historia._avancar()
	_marca("jogo")
	await _esperar(1.4)
	_marca("fim")


func fase1() -> void:
	await _fase(0)
	await _esperar(0.6)
	_marca("corre")
	piloto = true
	await _ate_coluna(13.0)
	_marca("buraco")
	await _ate_coluna(19.0)
	_marca("onca")
	await _ate_coluna(25.0)
	_marca("piranha")
	await _ate_coluna(31.5)
	_marca("cobra")
	await _ate_coluna(39.0)
	_marca("fim_cobra")
	await _esperar(0.8)
	_parar_piloto()
	_marca("fim")


func queda() -> void:
	await _fase(0, true)
	# pula direto para a dica da piranha
	main.tutorial.passo = 6
	main.tutorial.mostrando = false
	main.jogador.global_position = Vector2(24 * 16 + 8, 132)
	await _esperar(0.8)
	_marca("anda")
	var caiu := [false]
	main.jogador.caiu.connect(func(): caiu[0] = true)
	Input.action_press("direita")
	# anda até cair no rio, sem pular
	var t := 0.0
	while not caiu[0] and t < 4.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	_marca("caiu")
	Input.action_release("direita")
	await _esperar(1.6)
	_marca("tenta")
	main.jogador.pulou.connect(func():
		if not marcas.has("pulo"):
			_marca("pulo"))
	piloto = true
	await _ate_coluna(32.0, 8.0)
	_marca("conseguiu")
	await _esperar(1.0)
	_parar_piloto()
	_marca("fim")


func dano() -> void:
	await _fase(0, false, true)
	main.jogador.global_position = Vector2(18 * 16 + 8, 132)
	await _esperar(0.6)
	_marca("anda")
	Input.action_press("direita")
	var t := 0.0
	while main.jogador.empurrao <= 0.0 and t < 4.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	Input.action_release("direita")
	_marca("machucou")
	await _esperar(2.0)
	_marca("fim")


func montagem() -> void:
	await _fase(0)
	main.jogador.global_position = Vector2(5 * 16 + 8, 132)
	await _esperar(0.6)
	_marca("letras")
	# pega as letras que faltam (aparecem no alto da tela uma a uma)
	var ordem: Array = []
	for n in main.mundo.get_children():
		if n.get_script() == main.Letra and main.faltando.has(n.letra):
			ordem.append(n)
	for n in ordem:
		if is_instance_valid(n) and main.faltando.has(n.letra) and not main.montando:
			main._ao_coletar(n.letra, n)
			await _esperar(0.35)
	await _esperar(0.8)
	_marca("montar")
	var m = main.montagem
	for c in main.letras:
		for p in m.pecas:
			if not p.disabled and p.text == c:
				m._colocar(p)
				break
		await _esperar(0.5)
	_marca("certo")
	await _esperar(3.6)
	_marca("quiz")
	main._abrir_desafio()
	var vf = main.vf
	for i in 3:
		await _esperar(2.0)
		vf._responder(vf.perguntas[i][1])
		_marca("resposta%d" % (i + 1))
		await _esperar(2.4)
		vf._proxima()
	_marca("resultado")
	await _esperar(2.6)
	_marca("fim")


func fase3() -> void:
	await _fase(2)
	await _esperar(0.4)
	_marca("corre")
	piloto = true
	await _esperar(6.5)
	_parar_piloto()
	_marca("fim")


func fase5() -> void:
	await _fase(4)
	main.jogador.global_position = Vector2(42 * 16 + 8, 132)
	await _esperar(0.4)
	_marca("corre")
	piloto = true
	await _esperar(6.5)
	_parar_piloto()
	_marca("fim")


func final() -> void:
	main.nivel = 4
	main.pontos = 640
	main._mostrar_final()
	await _esperar(0.3)
	_marca("pagina1")
	await _esperar(3.6)
	main.historia._avancar()
	await _esperar(0.1)
	if main.historia.texto.visible_characters >= 0:
		main.historia._avancar()
	_marca("pagina2")
	await _esperar(3.8)
	_marca("fim")
