#!/usr/bin/env bash
# TDD 루프의 심장.
#
#   사용법: ./t [-w|--watch] [-g|--gui] [경로]     (./t 는 이 스크립트의 단축 실행기)
#     경로 없으면 __tests__/ 전체.  -w: 파일 바뀔 때마다 자동 재실행.  -g: 창 띄워서 실행.
#     예)  ./t __tests__/core/foo_test.gd
#          ./t -w                       # 감시 모드
#          ./t -w -g __tests__/game     # 감시 + 창 (입력 이벤트 테스트)
#          ./t --clean                  # reports/ 와 .godot/ 캐시 삭제
#
# [중요] headless 모드에서는 Godot이 InputEvent를 전달하지 않습니다.
# 즉 runner.simulate_key_pressed(...) 같은 "입력 시뮬레이션" 테스트는 headless에서
# 조용히 아무 일도 안 한 채 통과/실패할 수 있습니다. 그런 테스트만 --gui로 돌리세요.
# 프레임 시뮬레이션(simulate_frames)과 순수 로직 테스트는 headless에서 정상 동작합니다.
#
# 애초에 입력에 직접 의존하는 테스트를 최소화하는 게 낫습니다.
# "키 입력 → 의도(Intent)" 변환만 얇게 두고, 규칙은 src/core/ 의 순수 객체에서
# 의도를 받아 처리하게 하면 대부분의 테스트가 headless로 남습니다.
#
# 실패 시 non-zero로 종료하므로 CI에 그대로 물릴 수 있습니다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# godot_bin 을 설정합니다 (bin/run.sh 와 공유).
source "$ROOT/bin/_godot.sh"

gui=false
watch=false
target="__tests__"

while [[ $# -gt 0 ]]; do
	case "$1" in
		-w|--watch) watch=true; shift ;;
		-g|--gui)   gui=true;   shift ;;
		--clean)
			rm -rf "$ROOT/reports" "$ROOT/.godot"
			echo "reports/ 와 .godot/ 삭제됨 (다음 실행 때 캐시가 다시 만들어집니다)"
			exit 0
			;;
		-h|--help)
			# -E (ERE) 를 써야 합니다. BSD sed 는 BRE 의 \? 를 지원하지 않아 조용히 실패합니다.
			sed -n '2,9p' "${BASH_SOURCE[0]}" | sed -E 's/^# ?//'
			exit 0
			;;
		-*)
			echo "알 수 없는 옵션: $1" >&2
			echo "사용법: ./t [-w|--watch] [-g|--gui] [--clean] [경로]" >&2
			exit 2
			;;
		*) target="$1"; shift ;;
	esac
done

# --watch 는 감시 루프에 위임합니다. watch.sh 는 이 스크립트를 --watch 없이 다시 부릅니다.
#
# [주의] macOS 기본 bash 는 3.2 이고, 거기선 `set -u` 아래에서 빈 배열을 "${arr[@]}" 로
# 전개하면 "unbound variable" 로 죽습니다 (bash 4.4+ 에서 고쳐진 동작).
# 그래서 배열이 비는 경우를 아예 만들지 않도록 분기해서 씁니다.
if [[ "$watch" == true ]]; then
	if [[ "$gui" == true ]]; then
		exec "$ROOT/bin/watch.sh" --gui "$target"
	else
		exec "$ROOT/bin/watch.sh" "$target"
	fi
fi

# --- 전역 클래스 캐시 자동 갱신 -------------------------------------------------
#
# `class_name Foo` 는 .godot/global_script_class_cache.cfg 라는 "이름 → 스크립트 경로"
# 대응표에 등록돼야만 컴파일러가 인식합니다. 이 표는 --import 가 만듭니다.
# 평소엔 Godot 에디터가 저장할 때마다 갱신해주지만, 에디터 없이 헤드리스로 돌리는
# 우리 환경에서는 아무도 갱신해주지 않습니다.
# 갱신을 빠뜨리면 `Identifier "Foo" not declared` 라는 엉뚱한 파싱 에러가 납니다.
#
# --import 는 이 프로젝트에서 ~4초(대부분 gdUnit4의 190여 개 스크립트를 훑는 비용)이고
# 테스트는 ~1.3초입니다. 매번 돌리면 루프가 4배 느려지므로, 표가 실제로 바뀔 때만 돌립니다.
# 표가 바뀌는 경우 = 파일이 추가/삭제되거나 class_name 선언이 바뀔 때.
# 기존 파일의 본문만 고칠 때는 건너뜁니다.
class_fingerprint() {
	find src __tests__ scenes -type f -name '*.gd' 2>/dev/null | sort
	# class_name 이 하나도 없으면 grep 이 1 로 끝나고, set -e + pipefail 이 스크립트를 조용히 죽입니다.
	grep -rh '^class_name' src __tests__ scenes 2>/dev/null | sort || true
}

fingerprint_file="$ROOT/.godot/.class_fingerprint"
current_fingerprint="$(class_fingerprint)"

if [[ ! -f "$ROOT/.godot/global_script_class_cache.cfg" ]] \
	|| [[ ! -f "$fingerprint_file" ]] \
	|| [[ "$current_fingerprint" != "$(cat "$fingerprint_file")" ]]; then
	echo "class_name 목록이 바뀜 → 전역 클래스 캐시 갱신 중 (~4초)..." >&2
	"$godot_bin" --headless --path "$ROOT" --import >/dev/null 2>&1
	printf '%s' "$current_fingerprint" > "$fingerprint_file"
fi
# ------------------------------------------------------------------------------

# -s: 스크립트 모드, -d: 디버그(어서션 실패 지점 표시), -a: 테스트 대상 경로
# --ignoreHeadlessMode: headless 거부를 끕니다 (위의 InputEvent 주의사항을 이해한 상태)
#
# --remote-debug tcp://127.0.0.1:0 은 반드시 필요합니다.
# 이게 없으면 스크립트 파싱 에러가 났을 때 Godot이 대화형 CLI 디버거('debug>')로 진입하면서
# 종료 코드를 0으로 뭉개버립니다 → CI가 깨진 빌드에 초록불을 줍니다.
# 포트 0은 절대 바인딩되지 않으므로 연결이 항상 거부되고, 디버거가 붙지 않습니다.
#
# -c: fail-fast 끄기. GdUnit4는 기본이 fail-fast라서, 한 테스트가 실패하면 스위트의
# 나머지 테스트를 아예 실행하지 않습니다. 리포트에는 "Executed test cases: (4/4)" 처럼
# *실행된* 수만 찍히므로, 남은 테스트가 조용히 사라진 것처럼 보입니다.
# TDD에서는 실패 전체를 한 번에 보는 게 중요하므로 꺼둡니다.
#
# 인자를 배열 하나에 모읍니다. --gui 일 때 --headless 만 빼는데, 이때 배열이 비지 않도록
# (bash 3.2 + set -u 의 빈 배열 전개 문제) 항상 뒤에 나머지 인자를 채워 넣습니다.
godot_args=()
if [[ "$gui" != true ]]; then
	godot_args+=(--headless)
fi
godot_args+=(
	--path "$ROOT"
	-s -d --remote-debug tcp://127.0.0.1:0
	"res://addons/gdUnit4/bin/GdUnitCmdTool.gd"
	--ignoreHeadlessMode
	-c
	-rc 5
	-a "$target"
)

exec "$godot_bin" "${godot_args[@]}"
