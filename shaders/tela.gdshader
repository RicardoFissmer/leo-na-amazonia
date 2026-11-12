shader_type canvas_item;
render_mode unshaded;

// Efeitos por cima de tudo (inclusive textos):
// - transição: a imagem vira "pixelões" e escurece (u_pixelation_*, u_escurecer);
// - modo retrô: linhas de TV antiga, tela levemente curva e vinheta (u_retro + uniforms u_crt_*).
// Usa módulos do VesperaFX (MPL-2.0), em shaders/vesperafx/.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "res://shaders/vesperafx/include/pixelation.gdshaderinc"
#include "res://shaders/vesperafx/include/crt.gdshaderinc"

uniform bool u_retro = false;
uniform float u_escurecer : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	if (u_pixelation_enabled) {
		uv = to_pixelated_uv(SCREEN_PIXEL_SIZE, uv, u_pixelation_size);
	}
	if (u_retro) {
		uv = apply_crt_warp(uv);
	}

	// com a tela curva, o que fica fora da imagem vira borda preta
	vec3 color = vec3(0.0);
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		color = texture(screen_texture, uv).rgb;
	}

	if (u_retro) {
		color = apply_crt_scanlines(color, SCREEN_UV, SCREEN_PIXEL_SIZE.y);
		color = apply_crt_vignette(color, SCREEN_UV);
	}
	color *= 1.0 - u_escurecer;

	COLOR = vec4(color, 1.0);
}
