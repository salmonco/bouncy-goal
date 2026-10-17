shader_type spatial;
// 주변광까지 더하면 밝은 색이 하얗게 날아가므로 끄고, 밝기를 light() 에서 직접 정합니다.
render_mode ambient_light_disabled;

// 캐릭터용 툰 셰이더입니다. 빛 받는 면과 그림자 면을 두 단계로 딱 나눠, 그림처럼 평평한 색으로 칠합니다.
// 빛 받는 면은 albedo 그대로, 그림자 면은 albedo * shade * shade_color 입니다. 빛의 세기와 색은 따르지 않습니다.
// draw_face 를 켜면 얼굴(Face 메시) 앞면에 눈·하이라이트·입·볼터치를 그립니다.
// 얼굴 좌표는 Face 메시의 원점(머리 중심) 기준이고, 앞은 -Z 입니다. tools/blender/character.py 의 머리 크기와 맞춥니다.

uniform vec3 albedo : source_color = vec3(1.0);
// 그림자 면은 원래 색의 이 비율만큼만 밝습니다.
uniform float shade = 0.72;
// 그림자 면에 곱하는 색입니다. 눈처럼 흰 것은 푸르스름하게 주면 회색보다 자연스럽습니다.
uniform vec3 shade_color : source_color = vec3(1.0);
// 빛과 면이 이루는 각도(dot)가 이보다 크면 빛 받는 면입니다.
uniform float shade_threshold = 0.05;

uniform bool draw_face = false;
uniform vec2 eye_center = vec2(3.9, -4.9);
uniform vec2 eye_radius = vec2(1.5, 2.5);
uniform vec3 eye_color : source_color = vec3(0.12, 0.10, 0.14);
// 눈 윗부분을 비스듬히 깎아 눈꼬리가 올라간 의욕 넘치는 눈매를 만듭니다.
// eye_cut_height 는 눈 가운데에서 깎는 높이(눈 세로 반지름에 대한 비율), eye_slant 는 바깥으로 갈수록 올라가는 기울기입니다.
uniform float eye_cut_height = 0.45;
uniform float eye_slant = 0.45;
// 하이라이트는 눈 바깥쪽 위에 둡니다. x 는 눈 바깥 방향 기준입니다.
uniform vec2 shine_offset = vec2(0.35, 0.2);
uniform float shine_radius = 0.55;
// 크게 벌린 입: 윗선은 평평하고 아래는 둥근 반달 모양에, 안쪽 아래에 혀를 그립니다.
uniform vec2 mouth_center = vec2(0.0, -8.4);
uniform vec2 mouth_radius = vec2(1.7, 1.5);
uniform vec3 mouth_color : source_color = vec3(0.35, 0.10, 0.14);
uniform vec3 tongue_color : source_color = vec3(1.0, 0.50, 0.55);
uniform vec2 blush_center = vec2(6.8, -7.8);
uniform vec2 blush_radius = vec2(2.0, 1.1);
uniform vec3 blush_color : source_color = vec3(1.0, 0.68, 0.72);
uniform float blush_strength = 0.3;

varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
}

// 타원 안이면 1, 밖이면 0. 가장자리는 fwidth 로 부드럽게 합니다.
float ellipse(vec2 p, vec2 center, vec2 radius) {
	float d = length((p - center) / radius) - 1.0;
	float aa = fwidth(d);
	return 1.0 - smoothstep(-aa, aa, d);
}

// value 가 limit 보다 작으면 1, 크면 0. 경계는 부드럽게 합니다.
float below(float value, float limit) {
	float aa = fwidth(value);
	return 1.0 - smoothstep(-aa, aa, value - limit);
}

void fragment() {
	vec3 color = albedo;
	if (draw_face && local_position.z < 0.0) {
		vec2 p = local_position.xy;
		// 좌우 대칭이므로 x 를 절댓값으로 접어 한쪽만 계산합니다.
		vec2 mirrored = vec2(abs(p.x), p.y);
		float blush = ellipse(mirrored, blush_center, blush_radius);
		color = mix(color, blush_color, blush * blush_strength);
		// 눈 안쪽(코 쪽)으로 갈수록 낮게 깎여 눈꼬리가 올라갑니다.
		float cut = eye_center.y + eye_radius.y * eye_cut_height + (mirrored.x - eye_center.x) * eye_slant;
		float eye = ellipse(mirrored, eye_center, eye_radius) * below(mirrored.y, cut);
		color = mix(color, eye_color, eye);
		float shine = ellipse(mirrored, eye_center + shine_offset, vec2(shine_radius));
		color = mix(color, vec3(1.0), shine * eye);
		float mouth = ellipse(p, mouth_center, mouth_radius) * below(p.y, mouth_center.y);
		float tongue = ellipse(p, mouth_center - vec2(0.0, mouth_radius.y * 0.8), mouth_radius * vec2(0.6, 0.5));
		color = mix(color, mix(mouth_color, tongue_color, tongue), mouth);
	}
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float lit = smoothstep(shade_threshold - 0.02, shade_threshold + 0.02, dot(NORMAL, LIGHT)) * ATTENUATION;
	DIFFUSE_LIGHT += mix(shade * shade_color, vec3(1.0), lit);
}
