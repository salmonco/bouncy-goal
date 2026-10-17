shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

// 툰 셰이더의 다음 패스로 붙이는 외곽선입니다(inverted hull).
// 모델을 법선 방향으로 살짝 부풀린 뒤 뒷면만 칠해서, 실루엣과 부품이 겹치는 곳에 선이 생깁니다.

uniform float width = 0.35;
uniform vec3 color : source_color = vec3(0.10, 0.08, 0.10);

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = color;
}
