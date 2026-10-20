# 내보내기 공통 함수. 실행하지 말고 source 하세요:  source "$ROOT/bin/_export.sh"
# ROOT 와 godot_bin(bin/_godot.sh) 이 먼저 설정돼 있어야 합니다.
#
# bin/build-server.sh 와 bin/build-client.sh 가 같이 씁니다. 복사해두면 언젠가 한쪽만 고쳐집니다.

# 테스트를 통과해야 내보냅니다. `--export-release` 는 문법이 깨진 .gd 도 그대로 패킹하고
# 0 으로 끝나서, 걸러내는 건 테스트뿐입니다.
#   사용법: run_tests_or_exit <skip_tests:true|false> <건너뛰기 옵션 안내>
run_tests_or_exit() {
	local skip_tests="$1" hint="$2"
	if [[ "$skip_tests" == true ]]; then
		# ./t 를 건너뛰면 전역 클래스 캐시를 갱신해줄 사람이 없습니다. 여기서 직접 합니다.
		echo "테스트 건너뜀. 전역 클래스 캐시 갱신 중 (~4초)..." >&2
		"$godot_bin" --headless --path "$ROOT" --import >/dev/null 2>&1
		return
	fi
	echo "테스트 실행 중..." >&2
	if ! "$ROOT/bin/test.sh" >/dev/null 2>&1; then
		echo "테스트가 실패했습니다. 빌드하지 않습니다." >&2
		echo "  ./t 로 무엇이 깨졌는지 보세요.  (급하면 $hint)" >&2
		exit 1
	fi
}

# export_presets.cfg 의 프리셋으로 내보냅니다. 실패하면 로그를 보여주고 종료합니다.
#   사용법: export_preset_or_exit <프리셋 이름> <출력 경로>
export_preset_or_exit() {
	local preset="$1" out_path="$2"
	if ! grep -q "^name=\"$preset\"" "$ROOT/export_presets.cfg" 2>/dev/null; then
		echo "export_presets.cfg 에 '$preset' 프리셋이 없습니다." >&2
		exit 1
	fi

	mkdir -p "$(dirname "$out_path")"
	rm -f "$out_path"
	local log status
	log="$(mktemp)"

	echo "$preset 빌드 중..." >&2
	set +e
	"$godot_bin" --headless --path "$ROOT" --export-release "$preset" "$out_path" >"$log" 2>&1
	status=$?
	set -e
	# 템플릿이 없을 때 등 내보내기 실패가 종료 코드로 오지 않을 때가 있어 로그도 봅니다.
	if [[ "$status" -ne 0 ]] || grep -qE "ERROR|No export template|Failed to export|Template file not found" "$log"; then
		cat "$log" >&2
		rm -f "$log"
		echo "" >&2
		echo "$preset 빌드 실패. 위 로그의 ERROR 를 보세요." >&2
		echo "  템플릿이 없다는 내용이면: 편집기 > 내보내기 템플릿 관리" >&2
		exit 1
	fi
	rm -f "$log"

	if [[ ! -s "$out_path" ]]; then
		echo "$preset 빌드 실패: $out_path 가 없거나 비어 있습니다." >&2
		exit 1
	fi
}
