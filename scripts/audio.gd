extends Node
## Música e efeitos sonoros do jogo.

const EFEITOS := ["pulo", "letra", "erro", "dano", "caiu", "vitoria", "menu", "comecar"]

var efeitos := {}
var musica: AudioStreamPlayer


func _ready() -> void:
	for nome in EFEITOS:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://sons/%s.wav" % nome)
		p.volume_db = -4.0
		add_child(p)
		efeitos[nome] = p

	musica = AudioStreamPlayer.new()
	var stream: AudioStreamOggVorbis = load("res://sons/musica.ogg")
	stream.loop = true
	musica.stream = stream
	musica.volume_db = -10.0
	add_child(musica)


func tocar(nome: String) -> void:
	if not efeitos.has(nome):
		return
	var p: AudioStreamPlayer = efeitos[nome]
	# pequena variação no tom para o pulo não ficar repetitivo
	p.pitch_scale = randf_range(0.94, 1.06) if nome == "pulo" else 1.0
	p.play()


func tocar_musica() -> void:
	if not musica.playing:
		musica.play()


## Liga/desliga todo o som. Retorna true se ficou mudo.
func alternar_mudo() -> bool:
	var mudo := not AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, mudo)
	return mudo
