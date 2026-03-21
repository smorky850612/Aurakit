# AuraKit — Mode Reference (상세 레퍼런스)

> 다국어 명령, 티어 선택, 오케스트레이션 패턴, 호환 스택 상세.
> `/aura status`, `/aura config:`, 또는 사용자가 참조 요청 시 로딩.

---

## 다국어 슬래시 명령 (8개 언어 · 56개 명령)

### 기본 / BUILD / FIX / CLEAN / DEPLOY / REVIEW / COMPACT

| 언어 | 기본 | 빌드 | 수정 | 정리 | 배포 | 리뷰 | 컴팩트 |
|------|------|------|------|------|------|------|--------|
| 🇺🇸 EN | `/aura` | `/aura build:` | `/aura fix:` | `/aura clean:` | `/aura deploy:` | `/aura review:` | `/aura-compact` |
| 🇰🇷 KR | `/아우라` | `/아우라빌드` | `/아우라수정` | `/아우라정리` | `/아우라배포` | `/아우라리뷰` | `/아우라컴팩트` |
| 🇯🇵 JP | `/オーラ` | `/オーラビルド` | `/オーラ修正` | `/オーラ整理` | `/オーラデプロイ` | `/オーラレビュー` | `/オーラコンパクト` |
| 🇨🇳 ZH | `/奥拉` | `/奥拉构建` | `/奥拉修复` | `/奥拉清理` | `/奥拉部署` | `/奥拉审查` | `/奥拉压缩` |
| 🇪🇸 ES | `/aura-es` | `/aura-construir` | `/aura-arreglar` | `/aura-limpiar` | `/aura-desplegar` | `/aura-revisar` | `/aura-compactar` |
| 🇫🇷 FR | `/aura-fr` | `/aura-construire` | `/aura-corriger` | `/aura-nettoyer` | `/aura-deployer` | `/aura-reviser` | `/aura-compresser` |
| 🇩🇪 DE | `/aura-de` | `/aura-bauen` | `/aura-beheben` | `/aura-aufraeumen` | `/aura-deployen` | `/aura-pruefen` | `/aura-komprimieren` |
| 🇮🇹 IT | `/aura-it` | `/aura-costruire` | `/aura-correggere` | `/aura-pulire` | `/aura-distribuire` | `/aura-rivedere` | `/aura-compattare` |

### 확장 모드 (Namespace 직접 사용)

| 모드 | 명령 예시 |
|------|----------|
| ITERATE | `/aura iterate:로그인 기능` |
| TDD | `/aura tdd:결제 모듈` |
| PM | `/aura pm:소셜 로그인` |
| GAP | `/aura gap:path/to/spec.md` |
| QA | `/aura qa:api` |
| ORCHESTRATE | `/aura orchestrate:swarm review:전체` |
| PLAN | `/aura plan:기능명` |
| DESIGN | `/aura design:기능명` |
| REPORT | `/aura report:기능명` |
| DEBUG | `/aura debug:TypeError at file:45` |
| BRAINSTORM | `/aura brainstorm:주제` |
| BATCH | `/aura batch:A,B,C` |
| FINISH | `/aura finish:브랜치명` |
| ARCHIVE | `/aura archive:기능명` |
| STYLE | `/aura style:learning` |
| SNIPPETS | `/aura snippets:list` |
| MOBILE | `/aura mobile:기능` |
| DESKTOP | `/aura desktop:기능` |
| BAAS | `/aura baas:기능` |
| STATUS | `/aura status` |
| CONFIG | `/aura config:show` |
| PIPELINE | `/aura pipeline:` |
| QUICK | `/aura! 단순수정` |

### IME 역변환 (두벌식)

| 입력 | 변환 | 처리 |
|------|------|------|
| `/채ㅡㅔㅁㅊㅅ` | `/compact` | 두벌식 역변환 |
| `/멱ㅁ` | `/aura` | 두벌식 역변환 |

**Hook 처리**: `korean-command.js` (UserPromptSubmit) → 두벌식 IME 역변환 → 8개 언어 명령 매핑

---

## 티어 선택 가이드 (상세)

| 티어 | 모델 구성 | 비용 | 품질 | 추천 상황 |
|------|---------|------|------|---------|
| **QUICK** | sonnet (메인만, 프로토콜 생략) | ●○○○ | ●●○○ | 색상 변경, 텍스트 수정, 단순 설정 |
| **ECO** | Scout/V3: haiku, Builder/V2: sonnet | ●●○○ | ●●●○ | 일반 기능 구현, 대부분의 개발 작업 |
| **PRO** | Scout: haiku, Builder: opus, V2: sonnet | ●●●○ | ●●●● | 결제·인증·복잡한 비즈니스 로직 |
| **MAX** | Scout: sonnet, Builder/V2/Security: opus | ●●●● | ●●●● | 보안 감사, 아키텍처 설계, 크리티컬 |

```bash
/aura! 버튼 색상 변경          # QUICK
/aura 로그인 기능 만들어줘      # ECO (기본)
/aura pro 결제 시스템 만들어줘  # PRO
/aura max 마이크로서비스 인증   # MAX
```

---

## 오케스트레이션 패턴 (ORCHESTRATE 모드)

| 패턴 | 구조 | 사용 시점 |
|------|------|---------|
| **Leader** | 1 조율자 + N 실행자 (순차) | 단계적 구현, PRO/MAX 권장 |
| **Swarm** | N 병렬 실행 (독립) | 독립 작업 병렬화, ECO 권장 |
| **Council** | N 검토자 → 종합 결론 | 중요 결정, 아키텍처 설계 |
| **Watchdog** | 감시자 + N 실행자 (반복) | ITERATE, TDD 루프 |

```bash
/aura orchestrate:leader build:결제 시스템    # 지휘자
/aura orchestrate:swarm review:전체           # 떼 (기본)
/aura orchestrate:council design:인증 아키텍처 # 평의회
/aura orchestrate:watchdog iterate:           # 감시자
```

---

## 멀티 피처 STATUS 구조

```
.aura/snapshots/
  feature-login/current.md     ← 로그인 기능 상태
  feature-payment/current.md   ← 결제 기능 상태
  current.md                   ← 현재 활성 기능
```

`/aura status:feature` → 해당 기능 스냅샷 로딩

---

## 호환 스택 (Scout 자동 감지)

| 카테고리 | 지원 스택 |
|---------|---------|
| **Frontend** | React, Next.js, Vue, Svelte, SolidJS, Astro |
| **Backend** | Node.js/Express, Fastify, Python/FastAPI, Django, Go, Rust |
| **DB/ORM** | Prisma, Drizzle, SQLAlchemy, GORM, raw SQL |
| **Deploy** | Vercel, Netlify, Railway, Fly.io, AWS, GCP, Docker |
| **Test** | Jest, Vitest, Pytest, Go test, Playwright |
| **Package** | npm, pnpm, yarn, bun, pip, poetry, go modules |
| **Mobile** | React Native, Expo, Flutter |
| **Desktop** | Electron, Tauri |
| **BaaS** | Supabase, Firebase, bkend.ai |

감지 기준: `package.json`, `go.mod`, `pyproject.toml`, `Dockerfile`, `k8s/`, `prisma/`, `expo.json` 존재 여부.

---

## Tier + 언어 조합 예시

```bash
/아우라 pro 결제 시스템 만들어줘     # KR PRO BUILD
/オーラビルド max 認証システム         # JP MAX BUILD
/奥拉 iterate:登录功能                # ZH ITERATE
/aura-construir pro sistema de pago   # ES PRO BUILD
/aura max pm:마이크로서비스 API        # MAX PM
/aura pro tdd:인증 미들웨어           # PRO TDD
```

---

*AuraKit Mode Reference — 8언어 56명령 · 4패턴 오케스트레이션 · 호환 스택 가이드*
