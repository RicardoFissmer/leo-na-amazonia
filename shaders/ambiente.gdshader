shader_type canvas_item;
render_mode unshaded;

// Vinheta e cor um pouco mais viva por cima do cenário.
// Fica numa camada abaixo do HUD e das telas de texto, então os textos não são afetados.
// Usa módulos do VesperaFX (MPL-2.0), em shaders/vesperafx/.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;

#include "res://shaders/vesperafx/include/crt.gdshaderinc"
#include "res://shaders/vesperafx/include/rendering.gdshaderinc"

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;

	if (u_rendering_saturation != 1.0) {
		color = adjust_saturation(color, u_rendering_saturation);
	}
	if (u_rendering_contrast != 1.0) {
		color = adjust_contrast(color, u_rendering_contrast);
	}
	color = apply_crt_vignette(color, SCREEN_UV);

	COLOR = vec4(color, 1.0);
}
