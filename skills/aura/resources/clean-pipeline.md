# AuraKit — CLEAN Pipeline (상세)

> 이 파일은 CLEAN 모드에서만 로딩된다. (Progressive Disclosure)

---

## 원칙

- **안전 우선**: 기능 변경 없이 코드 구조만 개선
- **측정 가능**: 제거 줄 수, 분할 파일 수를 리포트
- **점진적**: 파일별로 검증하며 진행

---

## Step 1: bloat-check.sh 결과 수집

```bash
# 모든 소스 파일 줄 수 확인
find src -name "*.ts" -o -name "*.tsx" -o -name "*.py" | \
  xargs wc -l | sort -rn | head -20
```

출력 예시:
```
  342 src/components/Dashboard.tsx    ← 250줄 초과, 분할 필요
  289 src/app/api/users/route.ts      ← 250줄 초과, 분할 필요
  198 src/lib/utils.ts
  ...
```

---

## Step 2: Scout 에이전트로 중복 코드 탐색

```
Scout 에이전트 실행 (context:fork):
  탐색 대상:
    - 동일/유사 함수 패턴
    - 반복되는 코드 블록 (3회 이상)
    - 미사용 import
    - 미사용 함수/변수
    - 일관성 없는 네이밍
  출력:
    - 중복 코드 위치 목록
    - 미사용 심볼 목록
    - 네이밍 불일치 목록
```

### 중복 감지 패턴

```typescript
// 중복 패턴 예시 (3개 파일에 동일 코드)
const formatDate = (date: Date) => {
  return date.toLocaleDateString('ko-KR')
}

// → src/lib/date.utils.ts 로 추출
export const formatDate = (date: Date): string =>
  date.toLocaleDateString('ko-KR')
```

---

## Step 3: Dead Code 제거

### 3-1. 미사용 import 제거

```typescript
// Before
import { useState, useEffect, useCallback, useMemo } from 'react'
import { Button, Input, Modal, Spinner } from '@/components/ui'
import type { User, Post, Comment } from '@/types'

// After (실제 사용하는 것만)
import { useState, useEffect } from 'react'
import { Button, Input } from '@/components/ui'
import type { User } from '@/types'
```

### 3-2. 미사용 함수/변수 제거

```typescript
// Before
function unusedHelper(x: number): number {
  return x * 2
}

const UNUSED_CONSTANT = 'hello'

export function usedFunction() {
  // unusedHelper와 UNUSED_CONSTANT를 사용하지 않음
  return 'result'
}

// After
export function usedFunction() {
  return 'result'
}
```

### 3-3. 주석 처리된 코드 제거

```typescript
// Before
// const oldImplementation = async () => {
//   const res = await fetch('/old-api')
//   return res.json()
// }

// After
// (삭제)
```

### 3-4. 콘솔 로그 정리

```typescript
// Before (개발용 로그)
console.log('DEBUG:', data)
console.log('user:', user)

// After (프로덕션 정리)
// 개발 환경에서만 로깅 필요 시:
if (process.env.NODE_ENV === 'development') {
  console.debug('[Auth] user logged in:', user.id)
}
```

---

## Step 4: 250줄 초과 파일 분할

### 분할 전략

```
컴포넌트 파일 분할 (React):
  Dashboard.tsx (342줄)
  → Dashboard.tsx (메인, ~100줄)
  → DashboardStats.tsx (통계 섹션)
  → DashboardChart.tsx (차트 섹션)
  → useDashboard.ts (커스텀 훅)
  → dashboard.types.ts (타입 정의)

API 라우트 분할 (Next.js):
  users/route.ts (289줄)
  → users/route.ts (엔드포인트, ~50줄)
  → users/users.service.ts (비즈니스 로직)
  → users/users.repository.ts (DB 쿼리)
  → users/users.schema.ts (zod 스키마)

유틸리티 분할:
  utils.ts (200줄 이상)
  → date.utils.ts
  → string.utils.ts
  → array.utils.ts
  → format.utils.ts
```

### 분할 시 주의사항

```
✅ 분할 후 확인:
  - 기존 import 경로 업데이트
  - 순환 의존성 없는지 확인
  - 테스트 파일 경로 업데이트
  - barrel export (index.ts) 업데이트

❌ 분할 금지 케이스:
  - 강하게 결합된 로직 (억지 분리 금지)
  - 분리 후 더 복잡해지는 경우
```

---

## Step 5: 코드 일관성 정리

### 5-1. 네이밍 통일

```typescript
// 컴포넌트: PascalCase
UserProfile.tsx ✅
userProfile.tsx ❌
user_profile.tsx ❌

// 함수/변수: camelCase
const getUserById = () => {}  ✅
const get_user_by_id = () => {}  ❌

// 상수: UPPER_SNAKE_CASE
const MAX_RETRY_COUNT = 3  ✅
const maxRetryCount = 3  ❌ (일반 변수와 혼동)

// 타입/인터페이스: PascalCase
type UserProfile = {}  ✅
interface IUserProfile {}  ❌ (I 접두사 불필요)

// 파일명: kebab-case
user-profile.utils.ts  ✅
userProfile.utils.ts  ✅ (기존 규칙 따름)
UserProfile.utils.ts  ❌
```

### 5-2. 포맷 통일

```
일관성 확인 항목:
  - 따옴표: single vs double (프로젝트 ESLint 설정 따름)
  - 세미콜론: 있음 vs 없음
  - 들여쓰기: 2칸 vs 4칸 (프로젝트 설정 따름)
  - trailing comma: 있음 vs 없음
  - 화살표 함수 vs function 선언 (일관성)
```

---

## Step 6: 스냅샷 업데이트

`.aura/snapshots/current.md` 업데이트:

```markdown
# AuraKit Snapshot
- Timestamp: 2025-01-15T16:00:00Z
- Mode: CLEAN
- Original Request: 코드 정리해줘

## Completed
- [x] Dashboard.tsx → 4개 파일로 분할 (-142줄)
- [x] 미사용 import 제거 (12개 파일)
- [x] 중복 formatDate → lib/date.utils.ts 추출

## Remaining
- (없음)

## Last Verification
- Build: Pass
- Security: Pass
- Tests: 18/18 Pass

## Key Decisions
- Dashboard 분할: 컴포넌트 + 훅 + 타입 분리 패턴
- 유틸리티는 도메인별로 분리

## Next Action
- /aura review 로 최종 품질 점검
```

---

## Step 7: 3중 검증

```
V1: tsc --noEmit (분할 후 import 오류 없는지)
V2: Worker → 코드 리뷰 (context:fork)
V3: Worker → 전체 테스트 실행 (context:fork) — 기능 변화 없는지 확인
```

---

## Step 8: Conventional Commit

```bash
git add [변경된 파일들]
git commit -m "refactor(scope): 설명"

# 예시 (분리해서 커밋)
git commit -m "refactor(ui): split Dashboard into sub-components"
git commit -m "refactor(utils): extract shared date utilities"
git commit -m "refactor(cleanup): remove unused imports and dead code"
```

---

## Step 9: 정리 리포트

```
🧹 CLEAN 완료

제거:
  - 미사용 import: 47개 제거
  - dead code: 83줄 제거
  - 콘솔 로그: 12개 제거

분할:
  - Dashboard.tsx (342줄) → 4개 파일 (평균 85줄)
  - users/route.ts (289줄) → 4개 파일 (평균 72줄)

추출:
  - formatDate × 5곳 → lib/date.utils.ts
  - validateEmail × 3곳 → lib/validation.utils.ts

총 효과:
  - 제거된 줄: 130줄
  - 분할된 파일: 2개 → 8개
  - 평균 파일 길이: 312줄 → 79줄

검증:
  V1 Build:    ✅ Pass
  V2 Quality:  ✅ Pass
  V3 Tests:    ✅ 18/18 Pass (기능 변화 없음 확인)
```
