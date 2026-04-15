# AuraKit — Rust Build Resolver

> FIX 모드 V1 빌드 실패 시 Rust 프로젝트에서 자동 트리거.

---

## Rust Resolver

### Borrow Checker 패턴

```
error[E0382]: borrow of moved value: `x`
→ 원인: 소유권 이동 후 사용
→ 수정 옵션:
  // 1. clone()
  let y = x.clone(); use(x); use(y);
  // 2. 참조 사용
  let y = &x;

error[E0502]: cannot borrow `x` as mutable ... also borrowed as immutable
→ 원인: 가변/불변 참조 동시 존재
→ 수정: 참조 범위 분리 (블록으로 감싸기)

error[E0106]: missing lifetime specifier
→ 원인: 라이프타임 명시 필요
→ 수정:
  fn foo<'a>(x: &'a str) -> &'a str { x }

error[E0308]: mismatched types
→ 원인: 반환 타입 불일치
→ 수정: 명시적 타입 변환 또는 반환값 수정

error[E0277]: the trait bound `[T]: [Trait]` is not satisfied
→ 원인: 트레이트 미구현
→ 수정: impl Trait for T 추가 또는 where 절 수정
```

### 자동 수정 명령

```bash
cargo check                      # 빠른 체크 (링킹 없음)
cargo fix --allow-dirty          # 자동 수정
cargo clippy -- -D warnings      # 클리피 경고 → 에러
cargo fmt                        # 포맷 수정
```

---
