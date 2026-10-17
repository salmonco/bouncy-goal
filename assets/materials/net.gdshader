shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// 골대 그물입니다. 마름모 그물코의 밧줄을 그리고, 판 가운데가 처지도록 정점을 밀어냅니다.
// 그물 판은 잘게 나눈 PlaneMesh 이고, 가장자리(골대 틀에 묶인 곳)는 움직이지 않습니다.

uniform vec3 color : source_color = vec3(1.0);
// 그물코 한 칸의 크기와 밧줄 굵기(월드 단위)입니다.
uniform float cell = 11.0;
uniform float rope_width = 0.9;
uniform float rope_alpha = 0.9;
// 판마다 처지는 정도입니다. 판의 법선 방향으로 밀어내며, 음수면 반대쪽으로 처집니다.
instance uniform float sag = 0.0;

// 처지기 전의 위치로 그물코를 그려야, 처져도 그물코가 일정하게 보입니다.
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	VERTEX += NORMAL * sag * sin(PI * UV.x) * sin(PI * UV.y);
}

void fragment() {
	// 판 위의 2차원 좌표를 고릅니다. 판의 법선과 나란한 축은 버립니다.
	vec3 n = abs(world_normal);
	vec2 p = n.z > 0.5 ? world_position.xy : (n.x > 0.5 ? world_position.zy : world_position.xz);
	// 45도 돌려 마름모 그물코로 만듭니다.
	vec2 diamond = vec2(p.x + p.y, p.x - p.y) * 0.70710678 / cell;
	vec2 to_rope = abs(fract(diamond - 0.5) - 0.5) * cell;
	vec2 aa = fwidth(to_rope);
	vec2 rope = 1.0 - smoothstep(rope_width * 0.5 - aa, rope_width * 0.5 + aa, to_rope);
	ALBEDO = color;
	ALPHA = max(rope.x, rope.y) * rope_alpha;
}
