shader_type canvas_item;

// 2026-08-04：敵の彩度を落として白銀寄りにする。強さのランクは色ではなく発光/ディテール密度で表現し、
// 色相は天敵ウォード（属性色のリング、BattleScene.gdの_attach_predator_ring）専用に空けるための処置。
uniform float desaturate : hint_range(0.0, 1.0) = 1.0;
uniform vec3 tint : source_color = vec3(1.2, 1.2, 1.25);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float gray = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 gray_col = clamp(vec3(gray) * tint, 0.0, 1.0);
	COLOR = vec4(mix(tex.rgb, gray_col, desaturate), tex.a);
}
