# AuraKit — Build Resolvers (언어별 빌드 오류 해결)

> FIX 모드 V1 빌드 실패 시 자동 트리거.
> project-profile.md의 언어/스택 감지 → 해당 Resolver 파일 로딩.

---

## 통합 방식

V1 빌드 실패 시 자동 연동:
```
project-profile.md → 언어 감지
→ 해당 Resolver 파일 로딩
→ 에러 파싱 → 패턴 매칭 → 최소 수정
→ V1 재실행 → Pass 확인
→ 실패 시: 수동 확인 요청
```

명시적 호출:
```bash
/aura fix:go build error      → build-resolvers-go.md
/aura fix:rust borrow error   → build-resolvers-rust.md
/aura fix:java spring error   → build-resolvers-java.md
/aura fix:kotlin type error   → build-resolvers-kotlin.md
/aura fix:cpp linker error    → build-resolvers-cpp.md
/aura fix:swift build error   → build-resolvers-swift.md
/aura fix:python import error → build-resolvers-python.md
```

---

## 언어별 Resolver 파일

| 언어 | 파일 | ECO | PRO | MAX |
|------|------|-----|-----|-----|
| Go | `build-resolvers-go.md` | haiku | haiku | sonnet |
| Rust | `build-resolvers-rust.md` | sonnet | sonnet | opus |
| Java/Spring | `build-resolvers-java.md` | haiku | sonnet | opus |
| Kotlin | `build-resolvers-kotlin.md` | haiku | haiku | sonnet |
| C++ | `build-resolvers-cpp.md` | sonnet | sonnet | opus |
| Swift | `build-resolvers-swift.md` | haiku | haiku | sonnet |
| Python/PyTorch | `build-resolvers-python.md` | haiku | haiku | sonnet |

Rust/C++는 복잡한 에러 패턴으로 sonnet 이상 사용.

---

*Build Resolvers — 언어별 파일 분리 로딩. 전체 1,352줄 → 필요 언어만 로딩.*
