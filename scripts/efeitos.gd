extends Node
## Efeitos de tela feitos com os shaders do VesperaFX (shaders/vesperafx, licença MPL-2.0):
## - ambiente: vinheta e cor um pouco mais viva no cenário, por baixo do HUD (texto não é afetado);
## - transição: a tela vira "pixelões" e escurece ao trocar de tela ou de fase;
## - modo retrô (opcional, tecla R ou botão no menu): linhas de TV antiga, curvatura e vinheta.

const ARQUIVO_CONFIG := "user://config.cfg"
const DURACAO := 0.28   # tempo para pixelar (e o mesmo para voltar ao normal)
const PIXEL_MAX := 10   # tamanho máximo do "pixelão", em pixels do jogo

var retro := false
var em_transicao := false
var mat_ambiente: ShaderMaterial
var mat_tela: ShaderMaterial
var tela: ColorRect


func _ready() -> void:
	var camada_ambiente := CanvasLayer.new()
	camada_ambiente.layer = 1  # acima do cenário, abaixo do HUD (camada 2)
	add_child(camada_ambiente)
	var ambiente := _retangulo("res://shaders/ambiente.gdshader")
	camada_ambiente.add_child(ambiente)
	mat_ambiente = ambiente.material
	mat_ambiente.set_shader_parameter("u_crt_vignette_intensity", 0.35)
	mat_ambiente.set_shader_parameter("u_crt_vignette_smoothness", 0.7)
	mat_ambiente.set_shader_parameter("u_rendering_saturation", 1.1)
	mat_ambiente.set_shader_parameter("u_rendering_contrast", 1.05)

	var camada_tela := CanvasLayer.new()
	camada_tela.layer = 10  # por cima de tudo
	add_child(camada_tela)
	tela = _retangulo("res://shaders/tela.gdshader")
	camada_tela.add_child(tela)
	mat_tela = tela.material

	_carregar_config()
	_aplicar_retro()
	get_viewport().size_changed.connect(_aplicar_retro)


## Troca de tela com efeito: pixela e escurece, chama `meio` e volta ao normal.
func transicao(meio: Callable) -> void:
	if em_transicao:
		return
	em_transicao = true
	tela.visible = true
	mat_tela.set_shader_parameter("u_pixelation_enabled", true)
	var t := create_tween()
	t.tween_method(_progresso, 0.0, 1.0, DURACAO)
	t.tween_callback(meio)
	t.tween_method(_progresso, 1.0, 0.0, DURACAO)
	t.tween_callback(_fim_transicao)


## Liga/desliga o modo retrô e salva a escolha. Retorna true se ficou ligado.
func alternar_retro() -> bool:
	retro = not retro
	_aplicar_retro()
	var cfg := ConfigFile.new()
	cfg.load(ARQUIVO_CONFIG)
	cfg.set_value("efeitos", "retro", retro)
	cfg.save(ARQUIVO_CONFIG)
	return retro


func _progresso(p: float) -> void:
	var tamanho := 1 + int(round(p * (PIXEL_MAX - 1) * _escala()))
	mat_tela.set_shader_parameter("u_pixelation_size", tamanho)
	mat_tela.set_shader_parameter("u_escurecer", p * 0.6)


func _fim_transicao() -> void:
	mat_tela.set_shader_parameter("u_pixelation_enabled", false)
	mat_tela.set_shader_parameter("u_escurecer", 0.0)
	em_transicao = false
	tela.visible = retro


func _aplicar_retro() -> void:
	var escala := _escala()
	mat_tela.set_shader_parameter("u_retro", retro)
	mat_tela.set_shader_parameter("u_crt_scanline_intensity", 0.25 if retro else 0.0)
	# uma linha escura a cada pixel do jogo
	mat_tela.set_shader_parameter("u_crt_scanline_thickness", maxf(1.0, round(escala / 2.0)))
	mat_tela.set_shader_parameter("u_crt_warp_x", 0.06 if retro else 0.0)
	mat_tela.set_shader_parameter("u_crt_warp_y", 0.08 if retro else 0.0)
	mat_tela.set_shader_parameter("u_crt_vignette_intensity", 0.3 if retro else 0.0)
	mat_tela.set_shader_parameter("u_crt_vignette_smoothness", 0.6)
	tela.visible = retro or em_transicao


## Quantos pixels da janela cada pixel do jogo ocupa (a janela é ampliada em números inteiros).
func _escala() -> float:
	return maxf(1.0, floorf(float(get_window().size.y) / 180.0))


func _carregar_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ARQUIVO_CONFIG) == OK:
		retro = cfg.get_value("efeitos", "retro", false)


func _retangulo(caminho: String) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(320, 180)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load(caminho)
	r.material = m
	return r
