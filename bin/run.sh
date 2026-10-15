#!/usr/bin/env bash
# 게임을 실행합니다.
#
#   사용법: ./run [-e|--editor] [씬 경로]     (./run 은 이 스크립트의 단축 실행기)
#     인자 없으면 project.godot 의 main_scene 을 띄웁니다.
#     -e: 게임 대신 Godot 에디터를 엽니다.
#     예)  ./run                          # 게임 실행
#          ./run scenes/main.tscn        # 특정 씬만 실행
#          ./run -e                       # 에디터 열기
#
# 개발 중에는 에디터(-e)를 띄워두는 게 이득입니다. 코드는 VS Code 에서 쓰더라도,
# 에디터가 켜져 있으면 저장할 때마다 전역 클래스 캐시와 .uid 를 알아서 갱신해줘서
# ./t 의 4초짜리 --import 가 대부분 사라집니다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# godot_bin 을 설정합니다 (bin/test.sh 와 공유).
source "$ROOT/bin/_godot.sh"

editor=false
scene=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		-e|--editor) editor=true; shift ;;
		-h|--help)
			# -E (ERE) 필요: BSD sed 는 BRE 의 \? 를 지원하지 않아 조용히 실패합니다.
			sed -n '2,9p' "${BASH_SOURCE[0]}" | sed -E 's/^# ?//'
			exit 0
			;;
		-*)
			echo "알 수 없는 옵션: $1" >&2
			echo "사용법: ./run [-e|--editor] [씬 경로]" >&2
			exit 2
			;;
		*) scene="$1"; shift ;;
	esac
done

# bash 3.2 + set -u 에서 빈 배열 전개가 죽으므로, 배열이 비지 않게 조립합니다.
godot_args=()
if [[ "$editor" == true ]]; then
	godot_args+=(--editor)
fi
godot_args+=(--path "$ROOT")
if [[ -n "$scene" ]]; then
	godot_args+=("$scene")
fi

exec "$godot_bin" "${godot_args[@]}"
