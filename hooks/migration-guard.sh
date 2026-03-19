#!/bin/bash
# AuraKit - 파괴적 DB 마이그레이션 감지 및 차단
# Hook: PreToolUse (matcher: Write)
# stdin: JSON (tool_input)
# 차단 시 exit 2

set -euo pipefail

# ── JSON 입력 읽기 ─────────────────────────────────────────────────────
INPUT=$(cat)

# file_path 추출
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "${INPUT}" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
  CONTENT=$(echo "${INPUT}" | jq -r '.tool_input.content // ""' 2>/dev/null || echo "")
else
  FILE_PATH=$(echo "${INPUT}" | grep -o '"file_path":"[^"]*"' | sed 's/"file_path":"//;s/"$//' || echo "")
  CONTENT=$(echo "${INPUT}" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//' || echo "")
fi

# 파일 경로가 없으면 스킵
if [ -z "${FILE_PATH}" ]; then
  exit 0
fi

# ── 마이그레이션 파일인지 확인 ────────────────────────────────────────
IS_MIGRATION=false

# 파일 경로에 'migration' 또는 'migrate' 문자열 포함
if echo "${FILE_PATH}" | grep -qiE "migration|migrate|schema.sql|schema_change"; then
  IS_MIGRATION=true
fi

# Prisma 마이그레이션 파일 패턴
if echo "${FILE_PATH}" | grep -qE "prisma/migrations/"; then
  IS_MIGRATION=true
fi

# Alembic 마이그레이션 파일 패턴 (Python)
if echo "${FILE_PATH}" | grep -qE "alembic/versions/"; then
  IS_MIGRATION=true
fi

# Flyway 마이그레이션 패턴
if echo "${FILE_PATH}" | grep -qE "V[0-9]+__.*\.sql"; then
  IS_MIGRATION=true
fi

# 마이그레이션 파일이 아니면 스킵
if [ "${IS_MIGRATION}" = false ]; then
  exit 0
fi

# ── 파괴적 패턴 검사 ──────────────────────────────────────────────────
DANGEROUS_PATTERNS=()
DETECTED_PATTERN=""

# 패턴 1: DROP TABLE
if echo "${CONTENT}" | grep -qiE "DROP\s+TABLE(\s+IF\s+EXISTS)?\s+\w+"; then
  MATCHED=$(echo "${CONTENT}" | grep -iE "DROP\s+TABLE(\s+IF\s+EXISTS)?\s+\w+" | head -1 || echo "DROP TABLE")
  DANGEROUS_PATTERNS+=("DROP TABLE: '${MATCHED}'")
fi

# 패턴 2: DROP COLUMN
if echo "${CONTENT}" | grep -qiE "DROP\s+COLUMN\s+\w+"; then
  MATCHED=$(echo "${CONTENT}" | grep -iE "DROP\s+COLUMN\s+\w+" | head -1 || echo "DROP COLUMN")
  DANGEROUS_PATTERNS+=("DROP COLUMN: '${MATCHED}'")
fi

# 패턴 3: ALTER TABLE ... DROP (컬럼/제약조건 삭제)
if echo "${CONTENT}" | grep -qiE "ALTER\s+TABLE\s+\w+\s+DROP"; then
  MATCHED=$(echo "${CONTENT}" | grep -iE "ALTER\s+TABLE\s+\w+\s+DROP" | head -1 || echo "ALTER TABLE ... DROP")
  DANGEROUS_PATTERNS+=("ALTER TABLE DROP: '${MATCHED}'")
fi

# 패턴 4: TRUNCATE
if echo "${CONTENT}" | grep -qiE "TRUNCATE(\s+TABLE)?\s+\w+"; then
  MATCHED=$(echo "${CONTENT}" | grep -iE "TRUNCATE(\s+TABLE)?\s+\w+" | head -1 || echo "TRUNCATE")
  DANGEROUS_PATTERNS+=("TRUNCATE: '${MATCHED}'")
fi

# 패턴 5: DELETE FROM (WHERE 절 없는 경우)
# DELETE FROM table 다음에 WHERE가 없으면 위험
if echo "${CONTENT}" | grep -qiE "DELETE\s+FROM\s+\w+\s*;"; then
  MATCHED=$(echo "${CONTENT}" | grep -iE "DELETE\s+FROM\s+\w+\s*;" | head -1 || echo "DELETE FROM without WHERE")
  DANGEROUS_PATTERNS+=("DELETE without WHERE: '${MATCHED}'")
fi

# 패턴 6: DROP DATABASE / DROP SCHEMA
if echo "${CONTENT}" | grep -qiE "DROP\s+(DATABASE|SCHEMA)(\s+IF\s+EXISTS)?\s+\w+"; then
  MATCHED=$(echo "${CONTENT}" | grep -iE "DROP\s+(DATABASE|SCHEMA)" | head -1 || echo "DROP DATABASE/SCHEMA")
  DANGEROUS_PATTERNS+=("DROP DATABASE/SCHEMA: '${MATCHED}'")
fi

# 패턴 7: DROP INDEX
if echo "${CONTENT}" | grep -qiE "DROP\s+INDEX(\s+IF\s+EXISTS)?\s+\w+"; then
  MATCHED=$(echo "${CONTENT}" | grep -iE "DROP\s+INDEX" | head -1 || echo "DROP INDEX")
  DANGEROUS_PATTERNS+=("DROP INDEX: '${MATCHED}'")
fi

# ── 결과 처리 ──────────────────────────────────────────────────────────
if [ ${#DANGEROUS_PATTERNS[@]} -gt 0 ]; then
  echo "" >&2
  echo "🛑 AuraKit Migration Guard: 파괴적 마이그레이션이 감지되었습니다!" >&2
  echo "" >&2
  echo "파일: ${FILE_PATH}" >&2
  echo "" >&2
  echo "감지된 패턴:" >&2
  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    echo "  ⚠️  ${pattern}" >&2
  done
  echo "" >&2
  echo "이 마이그레이션은 데이터를 영구적으로 손실시킬 수 있습니다." >&2
  echo "" >&2
  echo "정말 실행하려면:" >&2
  echo "  1. 데이터 백업을 먼저 수행하세요" >&2
  echo "  2. staging 환경에서 먼저 테스트하세요" >&2
  echo "  3. 마이그레이션 파일을 직접 텍스트 에디터로 작성하세요" >&2
  echo "  4. 팀원과 리뷰를 거치세요" >&2
  echo "" >&2
  echo "안전한 대안:" >&2
  echo "  - 데이터 이전 후 컬럼 삭제 (down migration 추가)" >&2
  echo "  - soft delete (deleted_at 컬럼 추가) 고려" >&2
  echo "  - 새 테이블 생성 후 데이터 이전 방식 고려" >&2
  exit 2
fi

exit 0
