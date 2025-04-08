shader_type spatial;
render_mode unshaded, depth_draw_never;

uniform float depth_factor: hint_range(0.0, 256.0, 0.1) = 64.0;
uniform float depth_dist: hint_range(0.0, 1.0, 0.1) = 2.7;

uniform sampler2D DEPTH_TEXTURE: hint_depth_texture;

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	float linear_depth = 1.0 / (depth * INV_PROJECTION_MATRIX[2].w + INV_PROJECTION_MATRIX[3].w);
	float val = pow(linear_depth / depth_factor,3.0);
	ALBEDO = vec3(val);
}
