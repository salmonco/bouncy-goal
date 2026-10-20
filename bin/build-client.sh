#!/usr/bin/env bash
# 플레이어에게 나눠줄 클라이언트(macOS, Windows) 빌드를 만듭니다.
#
#   사용법: ./build-client [-s|--skip-tests] [macos|windows ...]
#     플랫폼을 안 주면 둘 다. 배포용 zip 이 build/ 에 생깁니다.  (./build-client 는 이 스크립트의 단축 실행기)
#     -s: 테스트를 건너뜁니다.
#     예)  ./build-client            # build/bouncy-goal-macos.zip, build/bouncy-goal-windows.zip
#          ./build-client windows
#
# 내보낸 빌드는 project.godot 의 network/server_address.template 서버로 접속합니다 (에디터에서는 localhost).
# macOS, Windows 내보내기 템플릿이 필요합니다 (편집기 > 내보내기 템플릿 관리).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# godot_bin 을 설정합니다 (bin/test.sh, bin/run.sh 와 공유).
source "$ROOT/bin/_godot.sh"
source "$ROOT/bin/_export.sh"

skip_tests=false
platforms=()

while [[ $# -gt 0 ]]; do
	case "$1" in
		-s|--skip-tests) skip_tests=true; shift ;;
		-h|--help)
			# -E (ERE) 필요: BSD sed 는 BRE 의 \? 를 지원하지 않아 조용히 실패합니다.
			sed -n '2,8p' "${BASH_SOURCE[0]}" | sed -E 's/^# ?//'
			exit 0
			;;
		macos|windows) platforms+=("$1"); shift ;;
		*)
			echo "알 수 없는 인자: $1" >&2
			echo "사용법: ./build-client [-s|--skip-tests] [macos|windows ...]" >&2
			exit 2
			;;
	esac
done

# bash 3.2 + set -u 에서 빈 배열 전개가 죽으므로 길이로 먼저 봅니다.
if [[ ${#platforms[@]} -eq 0 ]]; then
	platforms=(macos windows)
fi

run_tests_or_exit "$skip_tests" "./build-client -s"

for platform in "${platforms[@]}"; do
	case "$platform" in
		macos)
			# macOS 프리셋은 .app 을 zip 으로 묶어서 내보내므로 그대로 씁니다.
			export_preset_or_exit "macOS" "$ROOT/build/bouncy-goal-macos.zip"
			;;
		windows)
			# Windows 프리셋은 exe 로 내보내므로 zip 으로 묶고 exe 는 지웁니다. build/ 에는 macOS 처럼 zip 만 남습니다.
			exe="$ROOT/build/windows/bouncy-goal.exe"
			export_preset_or_exit "Windows" "$exe"
			rm -f "$ROOT/build/bouncy-goal-windows.zip"
			(cd "$(dirname "$exe")" && zip -q -j "$ROOT/build/bouncy-goal-windows.zip" "$(basename "$exe")")
			rm -rf "$ROOT/build/windows"
			;;
	esac
done

echo ""
echo "빌드 완료:"
for platform in "${platforms[@]}"; do
	du -h "$ROOT/build/bouncy-goal-$platform.zip"
done
