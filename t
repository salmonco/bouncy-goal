#!/usr/bin/env bash
# 테스트 단축 실행기. bin/test.sh 로 그대로 넘깁니다.
#
#   ./t                      # 전체
#   ./t __tests__/core       # 디렉터리/파일
#   ./t -w                   # 감시 모드
#   ./t -w -g __tests__/game # 감시 + 창
#   ./t -h                   # 사용법
#
# make 를 쓰지 않는 이유: make 는 `make test -w` 처럼 타깃 뒤에 오는 플래그를
# 자기 옵션으로 해석합니다. -w 는 make 의 실제 옵션(--print-directory)이라
# 에러도 없이 조용히 먹혀서, 감시 모드가 안 켜진 걸 눈치채기 어렵습니다.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin/test.sh" "$@"
