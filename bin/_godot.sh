# Godot 실행 파일을 찾아 godot_bin 에 설정합니다.
# 실행하지 말고 source 하세요:  source "$ROOT/bin/_godot.sh"
#
# 우선순위: GODOT_BIN 환경변수 > PATH > macOS 기본 설치 위치
#
# bin/test.sh 와 bin/run.sh 가 같이 씁니다. 복사해두면 언젠가 한쪽만 고쳐집니다.

if [[ -n "${GODOT_BIN:-}" ]]; then
	godot_bin="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
	godot_bin="$(command -v godot)"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
	godot_bin="/Applications/Godot.app/Contents/MacOS/Godot"
elif [[ -x "/Applications/Godot_mono.app/Contents/MacOS/Godot" ]]; then
	godot_bin="/Applications/Godot_mono.app/Contents/MacOS/Godot"
else
	echo "Godot 실행 파일을 찾을 수 없습니다." >&2
	echo "  brew install --cask godot   또는   export GODOT_BIN=/path/to/godot" >&2
	exit 127
fi
