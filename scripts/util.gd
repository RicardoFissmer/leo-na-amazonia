extends RefCounted
## Funções de apoio usadas por vários scripts.

## Cria um SpriteFrames a partir de uma folha de sprites em linha.
## anims = { "nome": [[quadro0, quadro1, ...], fps] }
static func frames(caminho: String, larg: int, alt: int, anims: Dictionary) -> SpriteFrames:
	var tex: Texture2D = load(caminho)
	var sf := SpriteFrames.new()
	for nome in anims:
		var info: Array = anims[nome]
		sf.add_animation(nome)
		sf.set_animation_speed(nome, info[1])
		sf.set_animation_loop(nome, true)
		for q in info[0]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(q * larg, 0, larg, alt)
			sf.add_frame(nome, at)
	return sf


static func retangulo(tam: Vector2) -> CollisionShape2D:
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = tam
	forma.shape = ret
	return forma
