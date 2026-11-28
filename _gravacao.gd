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
var duracoes := {}  # duração de cada fala da apresentação (só na cena "live")
var ultima_fala := ""


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
	if duracoes.has(nome):
		ultima_fala = nome
	if cena == "live" and is_instance_valid(main.jogador):
		print("    col=%.2f passo=%d coletadas=%s pontos=%d nivel=%d" % [main.jogador.global_position.x / 16.0,
			main.tutorial.passo, str(main.coletadas), main.pontos, main.nivel])


## Espera a última fala marcada terminar (mais uma folguinha) antes de seguir.
func _fim_fala(folga := 0.4) -> void:
	if ultima_fala == "":
		return
	var alvo: int = marcas[ultima_fala] + int((float(duracoes[ultima_fala]) + folga) * 30.0)
	while Engine.get_process_frames() - quadro0 < alvo:
		await get_tree().process_frame


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


# ---------------------------------------------------------------- live (apresentação final)
# Uma tomada contínua: menu -> história -> tutorial -> fase inteira -> montagem -> quiz -> fase 2.
# Cada _marca("xNN") marca onde a fala de mesmo id do roteiro da apresentação começa.

func _ate_chao() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var t := 0.0
	while not main.jogador.is_on_floor() and t < 3.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0


func _andar_ate(col: float) -> void:
	var direita: bool = main.jogador.global_position.x < col * 16.0
	Input.action_press("direita" if direita else "esquerda")
	var t := 0.0
	while t < 15.0:
		var x: float = main.jogador.global_position.x
		if (direita and x >= col * 16.0) or (not direita and x <= col * 16.0):
			break
		await get_tree().physics_frame
		t += 1.0 / 60.0
	Input.action_release("direita")
	Input.action_release("esquerda")
	await _ate_chao()


func _pular_parado() -> void:
	Input.action_press("pular")
	await _esperar(0.32)
	Input.action_release("pular")
	await _ate_chao()


## Pulo alto andando para a direita até a coluna `col`; depois cai na vertical.
func _pular_para(col: float) -> void:
	Input.action_press("direita")
	Input.action_press("pular")
	var t := 0.0
	var soltou := false
	while main.jogador.global_position.x < col * 16.0 and t < 3.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if not soltou and t >= 0.34:
			Input.action_release("pular")
			soltou = true
	Input.action_release("direita")
	Input.action_release("pular")
	await _ate_chao()


## Pulo andando para a direita até passar por cima de `no`.
func _pular_sobre(no: Node2D) -> void:
	Input.action_press("direita")
	Input.action_press("pular")
	var t := 0.0
	var soltou := false
	while main.jogador.global_position.x < no.global_position.x + 16.0 and t < 2.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if not soltou and t >= 0.34:
			Input.action_release("pular")
			soltou = true
	Input.action_release("direita")
	Input.action_release("pular")
	await _ate_chao()


func _esperar_dica(passo: int, limite := 6.0) -> void:
	var t := 0.0
	while not (main.tutorial.passo == passo and main.tutorial.mostrando) and t < limite:
		await get_tree().process_frame
		t += get_process_delta_time()


func _piloto_ate(col: float, limite := 20.0) -> void:
	piloto = true
	await _ate_coluna(col, limite)
	_parar_piloto()
	await _ate_chao()


func _colocar_letra(letra: String) -> void:
	for p in main.montagem.pecas:
		if not p.disabled and p.text == letra:
			main.montagem._colocar(p)
			return


func live() -> void:
	# o modo retrô é ligado e desligado no menu; no fim volta a configuração salva de antes
	var cfg := ConfigFile.new()
	cfg.load(main.efeitos.ARQUIVO_CONFIG)
	var retro_antes: bool = cfg.get_value("efeitos", "retro", false)
	var roteiro = JSON.parse_string(FileAccess.get_file_as_string("res://video/apresentacao/roteiro_apresentacao.json"))
	for fala in (roteiro["falas"] if roteiro is Dictionary else roteiro):
		duracoes[fala["id"]] = fala["dur"]
	# --- menu (abertura e proposta usam esta parte parada)
	await _esperar(40.0)
	await _fim_fala()
	_marca("m01")
	await _esperar(11.5)
	await _fim_fala()
	_marca("m02")
	await _esperar(1.0)
	await _tecla(KEY_DOWN)
	await _esperar(2.5)
	await _tecla(KEY_UP)
	await _esperar(5.0)
	await _fim_fala()
	_marca("m03")
	await _tecla(KEY_DOWN)
	await _esperar(0.6)
	await _tecla(KEY_DOWN)
	await _esperar(2.0)
	await _tecla(KEY_ENTER)  # liga o modo retrô
	await _esperar(5.0)
	await _tecla(KEY_ENTER)  # desliga
	await _esperar(4.5)
	await _fim_fala()
	_marca("m04")
	await _tecla(KEY_UP)
	await _esperar(0.8)
	await _tecla(KEY_ENTER)  # Como jogar
	await _esperar(11.0)
	await _fim_fala()
	_marca("m05")
	await _tecla(KEY_ESCAPE)
	await _esperar(3.0)
	await _fim_fala()
	_marca("jogar")
	await _tecla(KEY_ENTER)  # Jogar (o foco volta para Jogar ao fechar a ajuda)

	# --- história (o texto de cada página aparece no ritmo normal)
	await _esperar(0.7)
	for pagina in [["h01", 15.5], ["h02", 9.5], ["h03", 12.5]]:
		await _fim_fala()
		_marca(pagina[0])
		await _esperar(pagina[1])
		if pagina[0] == "h03":
			await _fim_fala()
			_marca("h04")
			await _esperar(8.5)
		if main.historia.texto.visible_characters >= 0:
			main.historia._avancar()  # termina de mostrar o texto
			await _esperar(0.3)
		main.historia._avancar()

	# --- tutorial
	await _esperar_dica(0, 8.0)
	_sem_dano()
	var onca = null
	for n in main.mundo.get_children():
		if n.get_script() == main.Onca and n.position.x < 30 * 16:
			onca = n
	onca.set_meta("coreografada", true)  # aqui a onça anda do jeito normal
	var t := 0.0
	await _fim_fala()
	_marca("t01")
	await _esperar(13.0)
	await _andar_ate(4.0)
	await _esperar_dica(1)
	await _fim_fala()
	_marca("t02")
	await _esperar(13.5)
	await _andar_ate(6.7)
	await _fim_fala()
	_marca("t03")
	await _esperar(7.0)
	await _esperar_dica(3)
	await _fim_fala()
	_marca("t04")
	await _esperar(10.5)
	await _andar_ate(7.3)
	await _pular_para(9.3)
	await _esperar(0.4)
	await _pular_parado()
	await _fim_fala()
	_marca("t05")
	await _esperar(11.5)
	await _andar_ate(11.6)
	await _esperar_dica(4)
	await _fim_fala()
	_marca("t06")
	await _esperar(5.0)
	# espera a onça estar indo para o fundo do trecho dela; assim ela volta na direção do Léo durante a fala
	t = 0.0
	while not (onca.direcao > 0.0 and onca.global_position.x > 22.5 * 16.0) and t < 14.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
	print("    esperou a onça %.1f s" % t)
	await _piloto_ate(17.3)
	await _esperar_dica(5)
	await _fim_fala()
	_marca("t07")
	print("    onca col=%.2f dir=%.0f lim=%.1f..%.1f" % [onca.global_position.x / 16.0, onca.direcao, onca.limite_esq / 16.0, onca.limite_dir / 16.0])
	# espera a onça vir na direção do Léo e pula por cima dela
	t = 0.0
	while t < 14.0:
		var dx: float = onca.global_position.x - main.jogador.global_position.x
		if dx < 0.0 or (dx < 34.0 and onca.direcao < 0.0) or dx < 22.0:
			break
		await get_tree().physics_frame
		t += 1.0 / 60.0
	if onca.global_position.x > main.jogador.global_position.x:
		await _pular_sobre(onca)
	# daqui em diante a onça só patrulha atrás do Léo (para não atravessar o Léo parado)
	onca.limite_dir = minf(onca.limite_dir, maxf(onca.position.x, onca.limite_esq + 4.0))
	await _esperar(1.0)
	await _fim_fala()
	_marca("t08")
	print("    onca col=%.2f dir=%.0f" % [onca.global_position.x / 16.0, onca.direcao])
	await _esperar(2.0)
	if main.jogador.global_position.x < 21.6 * 16.0:
		await _andar_ate(21.6)  # pega a letra errada de propósito
	await _esperar(3.0)
	await _fim_fala(-0.8)
	await _andar_ate(28.05)  # beirada do rio
	await _esperar_dica(6)
	await _fim_fala()
	_marca("t09")
	await _esperar(10.3)
	var caiu := [false]
	main.jogador.caiu.connect(func(): caiu[0] = true)
	# dá só um passo para fora da beirada e cai reto (sem pegar a letra que fica em cima do rio)
	Input.action_press("direita")
	t = 0.0
	while main.jogador.is_on_floor() and t < 2.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
	Input.action_release("direita")
	t = 0.0
	while not caiu[0] and t < 5.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _fim_fala()
	_marca("t10")
	await _esperar(14.0)
	await _fim_fala()
	_marca("t11")
	await _esperar(1.0)
	await _andar_ate(28.05)
	var piranha = null
	for n in main.mundo.get_children():
		if n.get_script() == main.Piranha and n.position.x < 35 * 16:
			piranha = n
	t = 0.0
	while piranha and not (piranha.fase == "pulando" and piranha.vel_y > 40.0) and t < 10.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
	caiu[0] = false
	await _pular_rio(0.16, caiu)
	await _andar_ate(32.4)
	await _esperar(2.0)
	await _esperar_dica(7)
	await _fim_fala()
	_marca("t12")
	await _esperar(9.0)
	# espera a cobra estar escondida para subir no tronco
	var cobra = null
	for n in main.mundo.get_children():
		if n.get_script() == main.Cobra and n.position.x < 40 * 16:
			cobra = n
	t = 0.0
	while cobra and not (cobra.fase == "escondida" and cobra.tempo < 0.6) and t < 6.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	await _fim_fala()
	_marca("t13")
	await _esperar(1.0)
	await _andar_ate(33.4)
	await _pular_para(35.0)
	await _esperar(0.4)
	await _andar_ate(36.3)
	await _pular_para(39.8)
	await _esperar(0.4)
	await _pular_parado()
	await _fim_fala()
	_marca("t14")
	await _esperar(11.0)

	# --- resto da fase
	await _fim_fala()
	_marca("f01")
	await _piloto_ate(45.4)  # para um pouco antes do segundo buraco
	await _esperar(2.2)
	await _piloto_ate(56.5, 25.0)
	t = 0.0
	while not main.montando and t < 8.0:
		piloto = true
		await get_tree().process_frame
		t += get_process_delta_time()
	_parar_piloto()
	await _fim_fala()
	_marca("f02")
	await _esperar(5.0)

	# --- montar a palavra (erra de propósito, depois acerta)
	await _fim_fala()
	_marca("w01")
	await _esperar(11.0)
	await _fim_fala()
	await _desafios()
	cfg.load(main.efeitos.ARQUIVO_CONFIG)
	cfg.set_value("efeitos", "retro", retro_antes)
	cfg.save(main.efeitos.ARQUIVO_CONFIG)


## Atravessa o rio com um pulo médio (segura o pulo por `h` segundos), que passa pela letra em cima do rio.
func _pular_rio(h: float, caiu: Array) -> void:
	Input.action_press("direita")
	Input.action_press("pular")
	var t := 0.0
	var saiu := false
	while t < 2.0 and not caiu[0]:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if t >= h:
			Input.action_release("pular")
		if not main.jogador.is_on_floor():
			saiu = true
		elif saiu:
			break
	Input.action_release("direita")
	Input.action_release("pular")


func teste_rio() -> void:
	var h := 0.1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--h="):
			h = float(a.substr(4))
	await _fase(0)
	main.jogador.global_position = Vector2(26.5 * 16, 132)
	await _esperar(0.5)
	var caiu := [false]
	main.jogador.caiu.connect(func(): caiu[0] = true)
	await _andar_ate(28.05)
	await _pular_rio(h, caiu)
	await _esperar(0.5)
	print("h=%.3f caiu=%s col=%.2f coletadas=%s" % [h, caiu[0], main.jogador.global_position.x / 16.0, main.coletadas])


func _carregar_duracoes() -> void:
	var roteiro = JSON.parse_string(FileAccess.get_file_as_string("res://video/apresentacao/roteiro_apresentacao.json"))
	for fala in roteiro["falas"]:
		duracoes[fala["id"]] = fala["dur"]


## Trechos curtos para as falas o01-o04 da apresentação: outras fases, dano e vidas, final.
func outras() -> void:
	_carregar_duracoes()
	await _fase(2)
	await _esperar(0.5)
	_marca("o01")
	piloto = true
	await _esperar(5.0)
	_parar_piloto()
	await _fim_fala(0.2)
	main.carregar_nivel(4)
	_sem_dano()
	main.jogador.global_position = Vector2(42 * 16 + 8, 132)
	await _esperar(0.4)
	_marca("o02")
	piloto = true
	await _esperar(5.5)
	_parar_piloto()
	await _fim_fala(0.2)
	# fase da onça com dano de verdade: perde as três vidas e a fase recomeça
	main.carregar_nivel(1)
	main.jogador.global_position = Vector2(18 * 16 + 8, 132)
	await _esperar(0.6)
	_marca("o03")
	await _esperar(1.5)
	Input.action_press("direita")
	var t := 0.0
	while main.vidas > 0 and t < 12.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	Input.action_release("direita")
	await _fim_fala(0.2)
	main.nivel = 4
	main.pontos = 640
	main._mostrar_final()
	await _esperar(0.3)
	_marca("o04")
	await _esperar(5.5)
	main.historia._avancar()
	await _esperar(0.1)
	if main.historia.texto.visible_characters >= 0:
		main.historia._avancar()
	await _fim_fala(0.6)
	_marca("fim")


## Montagem (com erro de propósito), verdadeiro ou falso (com erro de propósito) e início da fase 2.
func _desafios() -> void:
	_marca("w02")
	await _esperar(1.0)
	var certa: Array = main.letras.duplicate()
	var errada: Array = certa.duplicate()
	errada.reverse()
	if errada == certa:
		errada = [certa[1], certa[0]] + certa.slice(2)
	for c in errada:
		await _colocar_letra(c)
		await _esperar(0.6)
	await _esperar(8.0)
	await _fim_fala()
	_marca("w03")
	for i in certa.size():
		if not main.montagem.slot_travado[i]:
			await _colocar_letra(certa[i])
			await _esperar(0.6)
	await _esperar(7.5)
	await _fim_fala()
	_marca("w04")
	await _esperar(9.5)

	# --- verdadeiro ou falso (erra a segunda de propósito)
	await _fim_fala()
	_marca("q01")
	main._abrir_desafio()
	await _esperar(10.5)
	var vf = main.vf
	vf._responder(vf.perguntas[0][1])
	await _fim_fala()
	_marca("q02")
	await _esperar(6.5)
	vf._proxima()
	await _esperar(3.0)
	await _fim_fala()
	_marca("q03")
	await _esperar(3.0)
	vf._responder(not vf.perguntas[1][1])
	await _esperar(10.0)
	vf._proxima()
	await _esperar(3.0)
	vf._responder(vf.perguntas[2][1])
	await _esperar(4.0)
	vf._proxima()
	await _fim_fala()
	_marca("q04")
	await _esperar(8.0)
	await _fim_fala()
	_marca("q05")
	await _tecla(KEY_ENTER)
	await _esperar(7.0)
	_marca("fim")


## Só o final da tomada "live" (a partir da fala w02), recriando o mesmo estado do jogo:
## fase 1 com as letras A, R, R, A, A coletadas, 40 pontos e o Léo no fim da fase.
func live_fim() -> void:
	_carregar_duracoes()
	await _fase(0)
	_sem_dano()
	main.jogador.global_position = Vector2(50.5 * 16, 132)  # longe das letras, para não pegar nenhuma sem querer
	await _esperar(0.3)
	var letras: Array = []
	for n in main.mundo.get_children():
		if n.get_script() == main.Letra and main.faltando.has(n.letra):
			letras.append(n)
	# mesma ordem em que o Léo pegou as letras na gravação principal
	for alvo in ["A", "R", "R", "A", "A"]:
		for n in letras:
			if is_instance_valid(n) and n.letra == alvo and not n.has_meta("pega"):
				n.set_meta("pega", true)
				main._ao_coletar(n.letra, n)
				break
		await get_tree().process_frame
	main.jogador.global_position = Vector2(56.88 * 16, 132)
	main.pontos = 40
	main._atualizar_hud()
	print("    coletadas=%s pontos=%d" % [str(main.coletadas), main.pontos])
	await _esperar(4.0)
	await _desafios()


## Fim da fase da capivara: monta a palavra certa de primeira e acerta as três do verdadeiro ou falso.
func capivara() -> void:
	_carregar_duracoes()
	await _fase(4)
	main.pontos = 520
	main.jogador.global_position = Vector2(50.5 * 16, 132)
	await _esperar(0.3)
	main.jogador.global_position = Vector2(56.88 * 16, 132)
	await _esperar(1.2)
	var letras: Array = []
	for n in main.mundo.get_children():
		if n.get_script() == main.Letra and main.faltando.has(n.letra):
			letras.append(n)
	for n in letras:
		if is_instance_valid(n) and main.faltando.has(n.letra) and not main.montando:
			main._ao_coletar(n.letra, n)
			await get_tree().process_frame
	await _esperar(1.0)
	_marca("c01")
	await _esperar(2.5)
	for c in main.letras.duplicate():
		await _colocar_letra(c)
		await _esperar(0.45)
	await _esperar(1.0)
	await _fim_fala()
	_marca("c02")
	await _esperar(6.0)
	await _fim_fala(0.2)
	_marca("c03")
	main._abrir_desafio()
	await _esperar(2.2)
	var vf = main.vf
	for i in 3:
		vf._responder(vf.perguntas[i][1])
		await _esperar(2.2)
		vf._proxima()
		await _esperar(1.2)
	await _fim_fala(0.3)
	_marca("c04")
	await _esperar(1.0)
	await _fim_fala(0.8)
	_marca("fim")
