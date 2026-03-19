# AuraKit — DEPLOY Pipeline (상세)

> 이 파일은 DEPLOY 모드에서만 로딩된다. (Progressive Disclosure)

---

## 원칙

- **보안 우선**: 시크릿이 절대 노출되지 않도록
- **재현 가능**: 동일 환경에서 동일 결과
- **최소 설정**: 필요한 설정만 생성

---

## Step 1: 프레임워크 + 환경 감지

프로젝트 프로필 (`.aura/project-profile.md`) 에서 읽기:

```
감지 대상:
  Framework:
    - Next.js → Vercel 권장
    - React (Vite) → Vercel / Netlify
    - Express / Fastify → Docker / Railway
    - FastAPI / Django → Docker / Railway
    - 정적 HTML → Netlify / GitHub Pages

  인프라 요구사항:
    - DB 필요? → managed DB 서비스 필요
    - 파일 업로드? → S3 / Cloudflare R2 필요
    - Websocket? → Railway / Fly.io 권장

  환경:
    - production: 최적화 빌드
    - preview: PR 자동 배포 (Vercel/Netlify 기본 지원)
```

---

## Step 2: .env.example 생성

```bash
# .env.example — 실제 값 없이 구조만
# 이 파일은 git에 커밋됩니다. 실제 값은 .env에 작성하세요.

# Database
DATABASE_URL="postgresql://user:password@host:5432/dbname"

# Authentication
NEXTAUTH_SECRET="generate-with: openssl rand -base64 32"
NEXTAUTH_URL="http://localhost:3000"

# OAuth (optional)
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"

# Email (optional)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# External APIs (optional)
OPENAI_API_KEY="sk-..."
STRIPE_SECRET_KEY="sk_live_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
```

---

## Step 3: 배포 설정 파일 자동 생성

### 3-A. Next.js → vercel.json

```json
{
  "framework": "nextjs",
  "buildCommand": "next build",
  "devCommand": "next dev",
  "outputDirectory": ".next",
  "regions": ["icn1"],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:;"
        }
      ]
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

### 3-B. 범용 백엔드 → Dockerfile

```dockerfile
# Dockerfile
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json pnpm-lock.yaml* ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Build
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN corepack enable pnpm && pnpm build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 appuser

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1))"

CMD ["node", "dist/index.js"]
```

```yaml
# docker-compose.yml
version: '3.9'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-appuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-appuser}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:
```

### 3-C. 정적 사이트 → netlify.toml

```toml
# netlify.toml
[build]
  command = "npm run build"
  publish = "dist"

[build.environment]
  NODE_VERSION = "20"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

---

## Step 4: 보안 L1 재검사

```bash
# .env가 .gitignore에 포함되어 있는지 확인
if ! grep -q "\.env" .gitignore 2>/dev/null; then
  echo "⚠️  경고: .env가 .gitignore에 없습니다!"
  echo ".env" >> .gitignore
  echo ".env.local" >> .gitignore
  echo ".env.production" >> .gitignore
fi

# .env 파일이 git에 추적되고 있는지 확인
if git ls-files --error-unmatch .env 2>/dev/null; then
  echo "🚨 위험: .env가 git에 추적되고 있습니다!"
  echo "git rm --cached .env 를 실행하세요"
fi
```

---

## Step 5: 배포 명령어 안내

### Vercel

```bash
# 1. Vercel CLI 설치
npm i -g vercel

# 2. 로그인
vercel login

# 3. 프로젝트 연결 (최초 1회)
vercel link

# 4. 환경변수 설정
vercel env add DATABASE_URL
vercel env add NEXTAUTH_SECRET

# 5. 배포
vercel --prod
```

### Docker

```bash
# 1. 이미지 빌드
docker build -t myapp:latest .

# 2. 로컬 테스트
docker-compose up -d

# 3. 헬스체크 확인
curl http://localhost:3000/health

# 4. 레지스트리 푸시 (선택)
docker tag myapp:latest ghcr.io/username/myapp:latest
docker push ghcr.io/username/myapp:latest
```

### Netlify

```bash
# 1. 빌드
npm run build

# 2. Netlify CLI 배포
npx netlify-cli deploy --prod --dir=dist
```

---

## Step 6: Conventional Commit

```bash
git add vercel.json  # 또는 Dockerfile, netlify.toml
git add .env.example
git add docker-compose.yml
git commit -m "chore(deploy): add deployment configuration"
```

---

## Step 7: 배포 체크리스트

```
🚀 DEPLOY 체크리스트

환경변수:
  [ ] .env.example 최신화 완료
  [ ] .env가 .gitignore에 포함
  [ ] 배포 플랫폼에 env 변수 설정 완료

보안:
  [ ] HTTPS 강제 설정
  [ ] 보안 헤더 설정 (X-Frame-Options, CSP, etc.)
  [ ] CORS origin 화이트리스트 설정
  [ ] 시크릿 로테이션 일정 수립

성능:
  [ ] 정적 자산 캐싱 설정
  [ ] 이미지 최적화 설정
  [ ] 번들 사이즈 확인 (npm run build 결과)

모니터링:
  [ ] 헬스체크 엔드포인트 /health 구현
  [ ] 에러 로깅 서비스 연결 (Sentry, etc.)
  [ ] 배포 알림 설정

DB:
  [ ] 마이그레이션 실행 계획 수립
  [ ] 백업 정책 확인
  [ ] Connection pool 설정 확인

배포 완료 후:
  [ ] 주요 기능 스모크 테스트
  [ ] 로그인 플로우 확인
  [ ] 에러 페이지 확인
```
