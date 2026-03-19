---
name: aura-guard
description: "토큰 예산 모니터. 컨텍스트 사용량 감시 및 컴팩트 방어 시스템 지원. Internal skill — not user-invocable."
user-invocable: false
allowed-tools: Bash
---

# AuraKit Guard — 컴팩트 방어 시스템

> 컨텍스트 창 과부하를 방지하는 자동 방어 레이어.
> 이 스킬은 내부적으로 동작하며 사용자가 직접 호출하지 않는다.

---

## 컴팩트 방어 아키텍처

```
세션 시작
    │
    ▼
컨텍스트 사용량 모니터링
    │
    ├─ 65% 미만 → 정상 작업 계속
    │
    └─ 65% 도달 ─────────────────────────────────────────┐
                                                          │
                                              CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65
                                                          │
                                                          ▼
                                              pre-compact-snapshot.sh (PreCompact hook)
                                              ├─ 현재 스냅샷 백업
                                              ├─ transcript 요약 (claude -p)
                                              └─ .aura/snapshots/current.md 저장
                                                          │
                                                          ▼
                                                   /compact 자동 실행
                                                          │
                                                          ▼
                                              post-compact-restore.sh (PostCompact hook)
                                              ├─ .aura/snapshots/current.md 읽기
                                              └─ 내용을 stdout → Claude 컨텍스트 주입
                                                          │
                                                          ▼
                                              새 컨텍스트에서 이전 상태 복구됨
```

---

## 환경변수 설정

```bash
# ~/.bashrc 또는 ~/.zshrc에 추가 (init.sh가 자동 추가)
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65
```

이 설정으로 컨텍스트 65% 시점에 자동 컴팩트가 트리거된다.
기본값(90%)보다 일찍 압축하여 컨텍스트 손실을 방지한다.

---

## 토큰 사용량 확인 방법

Claude Code에서 `/context` 명령으로 현재 컨텍스트 사용량을 확인할 수 있다.

```
/context  →  현재 토큰 사용량 및 남은 용량 표시
```

---

## Hook 연동

| Hook 이벤트 | 파일 | 동작 |
|------------|------|------|
| PreCompact | pre-compact-snapshot.sh | 스냅샷 저장 |
| PostCompact | post-compact-restore.sh | 스냅샷 복구 + 컨텍스트 주입 |

---

## 스냅샷 파일 관리

```
.aura/snapshots/
├── current.md              ← 가장 최신 스냅샷 (항상 덮어씀)
├── SNAPSHOT-20250115-143022.md  ← 이전 스냅샷 백업
├── SNAPSHOT-20250115-152841.md
└── ...
```

- `current.md`: 현재 작업 상태. PostCompact 후 컨텍스트에 주입됨
- `SNAPSHOT-*.md`: 자동 백업. 수동 복구 시 참조

---

## 토큰 절약 원칙 (AuraKit 전체)

| 원칙 | 절감량 |
|------|--------|
| Hook-First (bash hook으로 검증) | ~60% |
| Context:fork 에이전트 격리 | ~25% |
| Fail-Only 출력 | ~10% |
| Progressive Disclosure | ~5% |

---

*AuraKit — Context Budget Guard: 65% 방어선으로 무손실 작업 보장*
