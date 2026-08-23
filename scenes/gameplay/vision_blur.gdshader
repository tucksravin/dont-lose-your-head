shader_type canvas_item;
// A cheap real Gaussian-ish blur: no hand-written kernel, just reading the
// screen texture at a high mip level (Godot builds the mip chain for us
// because of the filter_linear_mipmap hint below). Sharp inside either
// clear circle (body + optional head). `fade` lifts the blur on win.
// Docs: https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
//
// clear_center/clear_radius_px/edge_softness_px are in this project's usual
// world-px-equals-screen-px convention (fixed camera, no zoom — same
// assumption head.gd's _is_off_screen() relies on): VERTEX in vertex() is
// this rect's own local position, which for a full-rect CanvasLayer child
// the engine keeps in that same logical 640x360 space regardless of
// window/stretch scaling, so no manual transform is needed here — only the
// SCREEN_TEXTURE sample itself needs SCREEN_UV, which Godot already gets
// right per-fragment.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec2 clear_center = vec2(320.0, 180.0);
uniform float clear_radius_px = 90.0;
uniform vec2 clear_center_b = vec2(0.0);
uniform float clear_radius_b_px = 0.0;
uniform float edge_softness_px = 50.0;
uniform float blur_lod : hint_range(0.0, 8.0) = 3.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float t_a = smoothstep(clear_radius_px, clear_radius_px + edge_softness_px, distance(local_pos, clear_center));
	float t_b = 1.0;
	if (clear_radius_b_px > 0.5) {
		t_b = smoothstep(clear_radius_b_px, clear_radius_b_px + edge_softness_px, distance(local_pos, clear_center_b));
	}
	float t = min(t_a, t_b) * fade;
	vec4 sharp = textureLod(screen_texture, SCREEN_UV, 0.0);
	vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_lod);
	COLOR = mix(sharp, blurred, t);
}
