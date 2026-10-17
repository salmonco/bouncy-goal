shader_type spatial;

// 경기장 잔디와 라인을 그립니다. 크기는 FieldView 가 코어(Game, Goal) 상수로 넣어줍니다.
// PlaneMesh 의 UV(0~1)를 경기장 좌표(가운데가 원점)로 바꿔서 계산합니다.

uniform vec2 field_size = vec2(800.0, 2000.0);
uniform float goal_width = 250.0;
uniform float line_width = 5.0;
// 잔디를 깎은 줄무늬 한 칸의 길이입니다.
uniform float stripe_length = 125.0;
uniform float center_circle_radius = 100.0;
uniform float penalty_margin = 110.0;
uniform float penalty_depth = 200.0;
uniform float goal_area_margin = 35.0;
uniform float goal_area_depth = 70.0;
// 눈 행성 위에서도 흰 공이 묻히지 않도록, 눈 대신 옅은 민트빛 잔디로 둡니다.
uniform vec3 grass_light : source_color = vec3(0.58, 0.84, 0.70);
uniform vec3 grass_dark : source_color = vec3(0.49, 0.77, 0.64);
uniform vec3 line_color : source_color = vec3(1.0, 1.0, 1.0);

// 선까지의 거리(d)가 선 두께 안이면 1. fwidth 로 가장자리를 부드럽게 해서 멀리서도 계단이 지지 않게 합니다.
float stroke(float d) {
	float aa = fwidth(d);
	return 1.0 - smoothstep(line_width * 0.5 - aa, line_width * 0.5 + aa, abs(d));
}

// 사각형 테두리까지의 부호 있는 거리입니다.
float box(vec2 p, vec2 center, vec2 half_size) {
	vec2 q = abs(p - center) - half_size;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

void fragment() {
	vec2 p = (UV - 0.5) * field_size;
	vec2 half_field = field_size * 0.5;

	float stripe = mod(floor((p.y + half_field.y) / stripe_length), 2.0);
	vec3 grass = mix(grass_dark, grass_light, stripe);

	float line = stroke(box(p, vec2(0.0), half_field - line_width * 0.5));
	line = max(line, stroke(p.y));
	line = max(line, stroke(length(p) - center_circle_radius));
	// 센터 스팟은 속이 찬 점입니다.
	line = max(line, stroke(max(length(p) - line_width * 0.5, 0.0)));
	for (float end = -1.0; end <= 1.0; end += 2.0) {
		vec2 penalty_half = vec2(goal_width * 0.5 + penalty_margin, penalty_depth * 0.5);
		line = max(line, stroke(box(p, vec2(0.0, end * (half_field.y - penalty_half.y)), penalty_half)));
		vec2 goal_area_half = vec2(goal_width * 0.5 + goal_area_margin, goal_area_depth * 0.5);
		line = max(line, stroke(box(p, vec2(0.0, end * (half_field.y - goal_area_half.y)), goal_area_half)));
	}

	ALBEDO = mix(grass, line_color, line);
	ROUGHNESS = 0.95;
}
