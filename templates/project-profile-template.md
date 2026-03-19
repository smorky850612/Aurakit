# AuraKit Project Profile
# Scout 에이전트가 자동으로 채우는 프로젝트 프로필 템플릿.
# 자동 감지 실패 시 직접 수정하세요.

Generated At: YYYY-MM-DDTHH:MM:SSZ
Last Updated: YYYY-MM-DDTHH:MM:SSZ

---

## Core Stack

- Framework: (예: Next.js 14 App Router / React + Vite / Express.js / FastAPI)
- Language: (예: TypeScript 5.3 / JavaScript ES2022 / Python 3.12)
- Runtime: (예: Node.js 20 / Python 3.12 / Deno 1.x)
- Package Manager: (예: pnpm 8.x / npm 10.x / yarn 4.x / pip)

## Styling

- Styling: (예: Tailwind CSS v3.4 / CSS Modules / Styled Components / Emotion)
- UI Library: (예: shadcn/ui / MUI / Mantine / Chakra UI / Ant Design / 없음)
- Icon Library: (예: lucide-react / heroicons / react-icons / 없음)
- CSS Variables: (예: Available — .aura/design-system.md 참조 / Not Available)

## Data Layer

- Database: (예: PostgreSQL / MySQL / MongoDB / SQLite / Supabase / PlanetScale)
- ORM: (예: Prisma 5.x / Drizzle ORM / Mongoose / SQLAlchemy / 없음)
- Cache: (예: Redis (Upstash) / Memcached / In-Memory / 없음)
- File Storage: (예: AWS S3 / Cloudflare R2 / Vercel Blob / 없음)

## Authentication

- Auth: (예: NextAuth.js v5 / Lucia / Clerk / Supabase Auth / 직접 구현 / 없음)
- Providers: (예: Email/Password, Google, GitHub / 없음)
- Session: (예: httpOnly Cookie / Database Session / JWT Cookie)

## Testing

- Test Runner: (예: Vitest / Jest / pytest / Go test / 없음)
- UI Testing: (예: React Testing Library / 없음)
- E2E: (예: Playwright / Cypress / 없음)
- Coverage Target: (예: 80% / 없음)

## Key Dependencies

### Data Fetching
- (예: @tanstack/react-query v5 / SWR / axios / fetch API)

### Forms
- (예: react-hook-form + zod / Formik / 없음)

### State Management
- (예: Zustand / Jotai / Redux Toolkit / Context API)

### Utilities
- (예: date-fns / dayjs / lodash / zod)

### Email
- (예: Resend / Nodemailer / SendGrid / 없음)

### Payment
- (예: Stripe / Toss Payments / 없음)

## Directory Structure

- Source Root: (예: src/)
- App Directory: (예: src/app/)
- API Directory: (예: src/app/api/)
- Components: (예: src/components/)
- Lib/Utils: (예: src/lib/)
- Types: (예: src/types/)
- Hooks: (예: src/hooks/)
- Stores: (예: src/stores/ / 없음)
- Styles: (예: src/styles/)

## Build & Deploy

- Build Tool: (예: Turbopack / Webpack / Vite / esbuild)
- Build Command: (예: pnpm build / npm run build / python -m build)
- Dev Command: (예: pnpm dev / npm run dev / uvicorn main:app --reload)
- Type Check: (예: pnpm typecheck / npx tsc --noEmit)
- Lint: (예: pnpm lint / eslint / ruff)
- Format: (예: pnpm format / prettier / black)

## Deployment Target

- Platform: (예: Vercel / Railway / AWS / Docker / 미정)
- Region: (예: ICN1 (서울) / IAD1 (US East) / 미정)
- CI/CD: (예: GitHub Actions / Vercel 자동 배포 / 없음)

## Environment Variables (키 이름만, 값 없음)

### Required
- (예: DATABASE_URL)
- (예: NEXTAUTH_SECRET)
- (예: NEXTAUTH_URL)

### Optional
- (예: GOOGLE_CLIENT_ID)
- (예: GOOGLE_CLIENT_SECRET)
- (예: OPENAI_API_KEY)
- (예: STRIPE_SECRET_KEY)

---

## AuraKit 설정

- Security Level: L1 + L2 + L3 + L4 (Full)
- Bloat Threshold: 250 lines
- Compact Trigger: 65% context
- Snapshot Auto-Save: Enabled (PreCompact hook)
- Design System: .aura/design-system.md
