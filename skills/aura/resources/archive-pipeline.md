# AuraKit — Archive Pipeline (G15)

> 이 파일은 `/aura archive:` 명시 시 로딩된다.

---

## Archive 모드 개요

완료된 기능을 `.aura/archive/` 에 정리하고 브랜치를 보관한다.
"삭제"가 아닌 "보관" — 언제든 복구 가능.

```bash
/aura archive:로그인 기능   # 특정 기능 아카이브
/aura archive:all           # 완료된 모든 기능 아카이브
/aura archive:list          # 아카이브 목록 조회
/aura archive:restore:login # 아카이브에서 복구
```

---

## 실행 순서

### Step 1 — 아카이브 대상 식별

```bash
# 완료 표시된 태스크 스캔
grep -r "\[x\]" .aura/snapshots/current.md 2>/dev/null

# 완료된 기능 브랜치 목록
git branch --list "aura/*" --merged main
```

### Step 2 — 아카이브 디렉토리 구성

```
.aura/archive/
├── [기능명]/
│   ├── summary.md          ← 기능 요약 + 완료 날짜
│   ├── snapshot.md         ← 당시 current.md 사본
│   ├── files.txt           ← 생성/수정 파일 목록
│   └── commit.txt          ← 관련 커밋 해시
└── index.md                ← 아카이브 전체 인덱스
```

### Step 3 — 아카이브 실행

```bash
FEATURE_NAME="$1"
ARCHIVE_DIR=".aura/archive/${FEATURE_NAME}"
mkdir -p "$ARCHIVE_DIR"

# 스냅샷 복사
cp .aura/snapshots/current.md "$ARCHIVE_DIR/snapshot.md" 2>/dev/null || true

# 관련 커밋 수집
git log --oneline --all | grep -i "$FEATURE_NAME" > "$ARCHIVE_DIR/commit.txt" 2>/dev/null || true

# 요약 생성
cat > "$ARCHIVE_DIR/summary.md" << EOF
# ${FEATURE_NAME} — 아카이브

- 아카이브 날짜: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- 상태: ✅ 완료
- 관련 브랜치: aura/${FEATURE_NAME}

## 파일 목록
$(git diff --name-only main...aura/${FEATURE_NAME} 2>/dev/null || echo "(브랜치 없음)")

## 주요 변경사항
$(git log --oneline main...aura/${FEATURE_NAME} 2>/dev/null | head -5 || echo "(없음)")
EOF

echo "✅ ${FEATURE_NAME} 아카이브 완료: ${ARCHIVE_DIR}"
```

### Step 4 — 인덱스 업데이트

```markdown
# .aura/archive/index.md

| 기능명 | 완료일 | 파일 수 | 커밋 |
|--------|--------|---------|------|
| login  | 2025-03-15 | 5 | abc1234 |
```

### Step 5 — 브랜치 정리 (선택)

```bash
# 로컬 브랜치 삭제 (원격은 유지)
git branch -d "aura/${FEATURE_NAME}" 2>/dev/null || true

# 원격 아카이브 태그 생성
git tag "archive/${FEATURE_NAME}/$(date +%Y%m%d)" "aura/${FEATURE_NAME}" 2>/dev/null || true
```

### Step 6 — 스냅샷 갱신

```bash
# current.md에서 완료 항목 제거 → archived.md로 이동
sed -i '/\[x\]/d' .aura/snapshots/current.md
```

---

## archive:list

```bash
ls .aura/archive/ | grep -v index.md | sort

# 상세 목록
cat .aura/archive/index.md
```

---

## archive:restore

```bash
FEATURE_NAME="$1"
ARCHIVE_DIR=".aura/archive/${FEATURE_NAME}"

if [ ! -d "$ARCHIVE_DIR" ]; then
  echo "❌ 아카이브 없음: ${FEATURE_NAME}"
  exit 1
fi

# 아카이브 태그에서 브랜치 복구
git checkout -b "aura/${FEATURE_NAME}/restored" "archive/${FEATURE_NAME}/${TAG}" 2>/dev/null || \
  echo "⚠️  태그 없음 — commit.txt 확인 필요"

cat "$ARCHIVE_DIR/summary.md"
echo "✅ 복구 완료. 브랜치: aura/${FEATURE_NAME}/restored"
```

---

## AuraKit Archive 규칙

```
ARCHIVE 규칙:
  삭제 금지 — 모든 아카이브는 .aura/archive/ 에 보관
  브랜치 삭제 전 반드시 태그 생성 (git tag archive/*)
  current.md 완료 항목은 archived.md로 이동 (삭제 금지)
  복구 경로 항상 문서화
```
