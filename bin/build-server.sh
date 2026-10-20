#!/usr/bin/env bash
# 게임 서버(Linux x86_64, headless) 빌드를 만듭니다.
#
#   사용법: ./build-server [-s|--skip-tests]
#     build/server/bouncy-goal-server.x86_64 로 내보냅니다.  (./build-server 는 이 스크립트의 단축 실행기)
#     -s: 테스트를 건너뜁니다.
#     예)  ./build-server && ./deploy-server
#
# 'Linux Server' 내보내기 프리셋(export_presets.cfg)과 Linux 내보내기 템플릿이 필요합니다.
# 실패 시 non-zero 로 종료하므로 ./build-server && ./deploy-server 로 이어 쓸 수 있습니다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# godot_bin 을 설정합니다 (bin/test.sh, bin/run.sh 와 공유).
source "$ROOT/bin/_godot.sh"
source "$ROOT/bin/_export.sh"

out_path="$ROOT/build/server/bouncy-goal-server.x86_64"
skip_tests=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		-s|--skip-tests) skip_tests=true; shift ;;
		-h|--help)
			# -E (ERE) 필요: BSD sed 는 BRE 의 \? 를 지원하지 않아 조용히 실패합니다.
			sed -n '2,7p' "${BASH_SOURCE[0]}" | sed -E 's/^# ?//'
			exit 0
			;;
		*)
			echo "알 수 없는 옵션: $1" >&2
			echo "사용법: ./build-server [-s|--skip-tests]" >&2
			exit 2
			;;
	esac
done

run_tests_or_exit "$skip_tests" "./build-server -s"
export_preset_or_exit "Linux Server" "$out_path"

# 아키텍처가 틀리면 서버에서 "exec format error" 로만 죽습니다. 여기서 잡습니다.
if ! file "$out_path" | grep -q "ELF 64-bit.*x86-64"; then
	echo "빌드 실패: Linux x86_64 실행 파일이 아닙니다: $(file -b "$out_path")" >&2
	echo "  'Linux Server' 프리셋의 아키텍처를 확인하세요." >&2
	exit 1
fi

echo ""
echo "빌드 완료: build/server/$(basename "$out_path")"
du -h "$out_path"
