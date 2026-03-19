# AuraKit Snapshot
# 이 파일은 .aura/snapshots/current.md 에 복사되어 사용된다.
# pre-compact-snapshot.sh와 aura-compact 스킬이 이 포맷을 사용한다.

- Timestamp: YYYY-MM-DDTHH:MM:SSZ
- Mode: BUILD
- Original Request: (사용자의 원래 입력 전문)
- Plan: N files total
- Session ID: (세션 ID — 자동 기입)

---

## Completed

- [x] (완료된 파일 경로 또는 작업)
- [x] (완료된 파일 경로 또는 작업)

---

## Remaining

- [ ] (아직 완료하지 못한 파일 경로 또는 작업)
- [ ] (아직 완료하지 못한 파일 경로 또는 작업)

---

## Last Verification

- Build (V1): Pass / Fail — (오류 내용)
- Security (V2): Pass / VULN-001: (설명) (파일:라인)
- Tests (V3): N/N Pass / N Failed: (테스트명)

---

## Key Decisions

- (중요한 아키텍처 결정: 예) JWT → httpOnly cookie 방식 채택)
- (중요한 기술 선택: 예) zod로 입력 검증 통일)
- (중요한 이슈 해결: 예) Prisma relation 설정 방식)

---

## Next Action

- (다음에 바로 해야 할 구체적인 작업 한 줄)

---

## Context Notes

(컴팩트 후 Claude가 알아야 할 추가 정보)
- (예: 현재 Next.js 14 App Router 사용 중)
- (예: Prisma 마이그레이션 아직 실행 안 함)
- (예: 환경변수 .env.local에 있음)

---

<!--
사용 방법:
1. 자동: pre-compact-snapshot.sh가 컴팩트 전에 자동 생성
2. 수동: /aura-compact 실행 시 생성
3. 복구: post-compact-restore.sh가 컴팩트 후 컨텍스트에 주입

파일 위치:
- 현재: .aura/snapshots/current.md
- 백업: .aura/snapshots/SNAPSHOT-YYYYMMDD-HHMMSS.md
-->
