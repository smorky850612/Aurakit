# AuraKit — Go Build Resolver

> FIX 모드 V1 빌드 실패 시 Go 프로젝트에서 자동 트리거.

---

## Go Resolver

### 에러 패턴 & 수정

```
undefined: [identifier]
→ 원인: import 누락 또는 타이포
→ 수정: import 추가, go mod tidy

cannot use [type] as [type]
→ 원인: 타입 불일치
→ 수정: 명시적 타입 변환 또는 인터페이스 구현 확인

imported and not used: "[package]"
→ 원인: 미사용 import
→ 수정: 해당 import 제거 (goimports -w 자동)

go: module declares its path as: [X]; but was required as: [Y]
→ 원인: go.mod 경로 불일치
→ 수정: go mod tidy

import cycle not allowed
→ 원인: 순환 의존성
→ 수정: 인터페이스 추출 또는 패키지 구조 재설계

panic: interface conversion: [type] is not [interface]
→ 원인: 타입 단언 실패
→ 수정: ok 패턴으로 안전하게 변환
  val, ok := x.(Type); if !ok { ... }
```

### 자동 수정 명령

```bash
go mod tidy                  # 의존성 정리
goimports -w .               # import 자동 수정 (설치 시)
go vet ./...                 # 정적 분석
gofmt -w .                   # 포맷 수정
go generate ./...            # 코드 생성 (있는 경우)
```

---
