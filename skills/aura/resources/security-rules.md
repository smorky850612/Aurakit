# AuraKit — Security Rules (보안 L2 인라인 규칙)

> 코드 생성 시 항상 이 규칙을 적용한다. (BUILD/FIX 모드에서 로딩)
> 총 보안 규칙: 130+ | 레이어: 6중 보안 (L1~L6) | 언어: TS/Python/Go/Java/Rust

---

## 레이어 구조 (6중 보안)

```
L1: pre-session.js      → 세션 시작 시 .env/.gitignore 검사
L2: security-rules.md   → 코드 생성 시 인라인 적용 (이 파일)
L3: Worker 에이전트     → 구현 후 OWASP 보안 스캔 (격리 서브에이전트)
L4: security-scan.js    → 커밋 전 시크릿 패턴 감지
L5: convention-check.sh → CONV-001~005 코딩 컨벤션 (HIGH 위반 차단)
L6: Agent 격리          → disallowed-tools + bash-guard + Worktree
```

---

## 1. 입력 검증 (Input Validation)

### 필수 규칙

```typescript
// ✅ zod 스키마 검증 (권장)
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email('유효한 이메일 주소를 입력하세요').max(255),
  password: z.string()
    .min(8, '비밀번호는 8자 이상이어야 합니다')
    .max(128, '비밀번호는 128자 이내여야 합니다')
    .regex(/[A-Z]/, '대문자를 포함해야 합니다')
    .regex(/[0-9]/, '숫자를 포함해야 합니다'),
  name: z.string().min(1).max(100).trim(),
  age: z.number().int().min(0).max(150).optional(),
})

// 사용
const result = CreateUserSchema.safeParse(body)
if (!result.success) {
  return Response.json(
    { success: false, error: 'VALIDATION_ERROR', details: result.error.flatten() },
    { status: 400 }
  )
}
const validatedData = result.data
```

```typescript
// ✅ 수동 검증 (zod 없을 때)
function validateEmail(email: unknown): string {
  if (typeof email !== 'string') throw new Error('이메일은 문자열이어야 합니다')
  if (email.length > 255) throw new Error('이메일이 너무 깁니다')
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailRegex.test(email)) throw new Error('유효하지 않은 이메일 형식입니다')
  return email.toLowerCase().trim()
}
```

### 검증 대상

```
모든 사용자 입력 검증 필수:
  - req.body (POST/PUT/PATCH)
  - req.query / searchParams (GET)
  - req.params / route params (동적 라우트)
  - 파일 업로드 (type, size, name)
  - 헤더 값 (Authorization, Content-Type 등)
```

### 검증 항목

```
타입 검증:  typeof 확인 또는 zod 타입
길이 검증:  문자열 min/max, 배열 길이
형식 검증:  이메일, URL, UUID, 날짜 형식
범위 검증:  숫자 min/max
허용값 검증: enum, allowlist
```

---

## 2. SQL 인젝션 방지 (SQL Injection Prevention)

```typescript
// ✅ Parameterized Query
const user = await db.query(
  'SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL',
  [email]
)

// ✅ Named Parameters
const user = await db.query(
  'SELECT * FROM users WHERE email = :email',
  { email }
)

// ✅ Prisma (자동 안전)
const user = await prisma.user.findFirst({
  where: {
    email,
    deletedAt: null,
  }
})

// ✅ Knex Query Builder
const user = await db('users')
  .where({ email, deleted_at: null })
  .first()

// ❌ 절대 금지 패턴들
// 문자열 연결
db.query(`SELECT * FROM users WHERE email = '${email}'`)

// 템플릿 리터럴 삽입
db.query(`SELECT * FROM users WHERE id = ${userId}`)

// 동적 테이블명/컬럼명 (필요시 allowlist 검증 필수)
const tableName = userInput  // ❌ 위험
// ✅ allowlist로 검증
const ALLOWED_TABLES = ['users', 'products', 'orders'] as const
if (!ALLOWED_TABLES.includes(tableName)) throw new Error('Invalid table')
```

---

## 3. XSS 방지 (Cross-Site Scripting Prevention)

```typescript
// ❌ 절대 금지
element.innerHTML = userInput
document.write(userInput)
eval(userInput)
new Function(userInput)()
setTimeout(userInput, 0)  // 문자열 형태

// ❌ React에서 금지
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// ✅ React의 기본 이스케이프 활용
<div>{userInput}</div>  // React가 자동 이스케이프

// ✅ HTML 이스케이프 함수 (필요시)
function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
}

// ✅ 마크다운 렌더링 시 sanitize 라이브러리 사용
import DOMPurify from 'dompurify'
const cleanHtml = DOMPurify.sanitize(markdownToHtml(userContent))
```

---

## 4. 인증/인가 (Authentication & Authorization)

### 토큰 저장

```typescript
// ✅ httpOnly Cookie (서버에서 설정)
const cookieOptions = {
  httpOnly: true,   // JS에서 접근 불가
  secure: process.env.NODE_ENV === 'production',  // HTTPS만
  sameSite: 'strict' as const,  // CSRF 방지
  maxAge: 60 * 60 * 24,  // 24시간
  path: '/',
}
res.setHeader('Set-Cookie', serialize('token', jwt, cookieOptions))

// ❌ 금지
localStorage.setItem('access_token', jwt)
sessionStorage.setItem('token', jwt)
```

### 인증 미들웨어

```typescript
// middleware.ts (Next.js)
import { NextRequest, NextResponse } from 'next/server'
import { verifyJWT } from '@/lib/auth'

const PROTECTED_ROUTES = ['/dashboard', '/profile', '/api/protected']

export async function middleware(req: NextRequest) {
  const isProtected = PROTECTED_ROUTES.some(route =>
    req.nextUrl.pathname.startsWith(route)
  )
  if (!isProtected) return NextResponse.next()

  const token = req.cookies.get('token')?.value
  if (!token) {
    return NextResponse.redirect(new URL('/login', req.url))
  }

  try {
    const payload = await verifyJWT(token)
    const res = NextResponse.next()
    res.headers.set('x-user-id', payload.userId)
    return res
  } catch {
    return NextResponse.redirect(new URL('/login', req.url))
  }
}
```

### 권한 검사 (Authorization)

```typescript
// ✅ 리소스 소유권 확인
async function deletePost(postId: string, requestUserId: string) {
  const post = await prisma.post.findUnique({ where: { id: postId } })
  if (!post) throw new NotFoundError('게시글을 찾을 수 없습니다')

  // 소유권 검사 필수
  if (post.authorId !== requestUserId) {
    throw new ForbiddenError('삭제 권한이 없습니다')
  }

  return prisma.post.delete({ where: { id: postId } })
}

// ❌ 소유권 검사 없음 (IDOR 취약점)
async function deletePost(postId: string) {
  return prisma.post.delete({ where: { id: postId } })
}
```

### CSRF 보호

```typescript
// SameSite=Strict 쿠키로 기본 CSRF 방지
// 추가 보호가 필요한 경우:
import { randomBytes } from 'crypto'

// CSRF 토큰 생성
const csrfToken = randomBytes(32).toString('hex')

// 쿠키에 저장 (httpOnly: false — JS에서 읽어야 함)
res.setHeader('Set-Cookie', serialize('csrf_token', csrfToken, {
  httpOnly: false,
  secure: true,
  sameSite: 'strict',
}))

// 검증 (서버에서)
const clientToken = req.headers['x-csrf-token']
const cookieToken = req.cookies.csrf_token
if (clientToken !== cookieToken) throw new Error('CSRF 토큰 불일치')
```

---

## 5. 시크릿 관리 (Secret Management)

```typescript
// ✅ 환경변수 접근 (서버사이드)
const apiKey = process.env.OPENAI_API_KEY
if (!apiKey) throw new Error('OPENAI_API_KEY is not set')

// ✅ 클라이언트 공개 가능한 변수만 NEXT_PUBLIC_ 사용
const publicApiUrl = process.env.NEXT_PUBLIC_API_URL  // 공개 OK

// ❌ 클라이언트에 시크릿 노출
const secret = process.env.NEXT_PUBLIC_SECRET_KEY  // ❌ 위험

// ❌ 하드코딩 금지 패턴들
const apiKey = 'sk-proj-abc123...'  // ❌
const dbPassword = 'mypassword123'  // ❌
const webhookSecret = 'whsec_...'   // ❌
const awsKey = 'AKIAIOSFODNN7...'   // ❌
```

> **자동 감지**: `security-scan.js` (L4 hook) 가 커밋 전 전체 파일 스캔 → API 키 패턴 7종 자동 차단 (OpenAI, GitHub PAT, AWS, GCP, Stripe, Twilio, PEM).
> **프롬프트 방어**: `/aura` 대화에서 시크릿 언급 감지 시 → 저장 차단 + 경고 (instinct-auto-save.js 민감 패턴 필터).

---

## 6. 네트워크 보안 (Network Security)

### CORS

```typescript
// ✅ Origin 화이트리스트
const ALLOWED_ORIGINS = new Set([
  'https://myapp.com',
  'https://www.myapp.com',
  process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : null,
].filter(Boolean))

function corsMiddleware(req: Request, res: Response) {
  const origin = req.headers.get('origin')
  if (origin && ALLOWED_ORIGINS.has(origin)) {
    res.headers.set('Access-Control-Allow-Origin', origin)
    res.headers.set('Vary', 'Origin')
  }
  // Allow-Credentials: true 시 * 사용 불가
}

// ❌ 와일드카드 금지
res.headers.set('Access-Control-Allow-Origin', '*')
```

### 보안 헤더

```typescript
// next.config.js / vercel.json에 설정
const securityHeaders = [
  { key: 'X-DNS-Prefetch-Control', value: 'on' },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
  {
    key: 'Content-Security-Policy',
    value: [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline'",  // Next.js 요구사항
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "font-src 'self'",
      "connect-src 'self' https://api.myapp.com",
    ].join('; ')
  },
]
```

### Rate Limiting

```typescript
// ✅ rate-limiter-flexible 또는 upstash/ratelimit 사용
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),  // 10초당 10회
  analytics: true,
})

export async function POST(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? '127.0.0.1'
  const { success, limit, reset, remaining } = await ratelimit.limit(ip)

  if (!success) {
    return Response.json(
      { success: false, error: 'RATE_LIMIT_EXCEEDED', message: '너무 많은 요청입니다' },
      {
        status: 429,
        headers: {
          'X-RateLimit-Limit': limit.toString(),
          'X-RateLimit-Remaining': remaining.toString(),
          'X-RateLimit-Reset': new Date(reset).toISOString(),
        }
      }
    )
  }
  // ... 요청 처리
}
```

---

## 7. 의존성 보안 (Dependency Security)

```bash
# 새 패키지 설치 전 취약점 확인
npm audit
# 또는
pip audit

# 심각도 high 이상만 표시
npm audit --audit-level=high

# 자동 수정 (minor 이슈)
npm audit fix

# 패키지 출처 확인 (타이포스쿼팅 방지)
npm info [패키지명]  # 다운로드 수, 저자 확인
```

### 금지 패키지 패턴

```
설치 전 확인:
  - 주간 다운로드 1000 미만 → 신중하게 검토
  - 최근 업데이트 1년 이상 없음 → 대안 탐색
  - npm 공식 페이지에서 저자 확인
  - 비슷한 이름의 악성 패키지 주의 (colors → kolors 등)
```

---

## 8. Python 보안 규칙 (v5.0 신규)

```python
# ❌ 절대 금지
subprocess.call(f"rm -rf {user_input}", shell=True)  # Command Injection
yaml.load(data)          # → yaml.safe_load(data)
pickle.loads(user_data)  # 신뢰할 수 없는 데이터에 금지
eval(user_expression)    # Code Injection

# ✅ 올바른 패턴
subprocess.run(["rm", "-rf", safe_path], shell=False, check=True)
import secrets; token = secrets.token_urlsafe(32)  # 안전한 난수

# SQL (SQLAlchemy)
result = db.execute(
    text("SELECT * FROM users WHERE email = :email"),
    {"email": email}
)

# 파일 경로 검증 (Path Traversal 방지)
import os
def safe_path(base_dir: str, filename: str) -> str:
    safe = os.path.realpath(os.path.join(base_dir, filename))
    if not safe.startswith(os.path.realpath(base_dir)):
        raise ValueError("Path traversal detected")
    return safe
```

---

## 9. Go 보안 규칙 (v5.0 신규)

```go
// ❌ 금지
db.Query("SELECT * FROM users WHERE name = " + name)  // SQL Injection
exec.Command("sh", "-c", userInput).Run()              // Command Injection
math/rand.Int()  // 보안 난수 아님

// ✅ 올바른 패턴
// SQL Parameterized
db.QueryContext(ctx, "SELECT * FROM users WHERE name = $1", name)

// 안전한 난수
import "crypto/rand"
buf := make([]byte, 32)
_, err := rand.Read(buf)

// 파일 Path Traversal 방지
func safePath(baseDir, userPath string) (string, error) {
    cleaned := filepath.Clean(filepath.Join(baseDir, userPath))
    if !strings.HasPrefix(cleaned, filepath.Clean(baseDir)+string(os.PathSeparator)) {
        return "", errors.New("invalid path")
    }
    return cleaned, nil
}

// TLS 최소 버전 강제
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
}
```

---

## 10. Java/Spring 보안 규칙 (v5.0 신규)

```java
// ❌ 금지
stmt.execute("SELECT * FROM users WHERE id = " + userId);  // SQL Injection
Runtime.getRuntime().exec(userInput);  // Command Injection

// ✅ PreparedStatement
PreparedStatement pstmt = conn.prepareStatement(
    "SELECT * FROM users WHERE id = ?"
);
pstmt.setString(1, userId);

// XXE 방지 (XML 파싱)
DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
factory.setFeature("http://xml.org/sax/features/external-general-entities", false);

// Spring Security CORS 설정
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("https://myapp.com"));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
    config.setAllowCredentials(true);
    // config.addAllowedOrigin("*");  // ❌ 절대 금지
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);
    return source;
}
```

---

## 11. Rust 보안 규칙 (v5.0 신규)

```rust
// ❌ 금지 패턴
let result = query.execute(&conn);  // 에러 무시 — unwrap() 금지
unsafe { std::mem::transmute::<T, U>(val) }  // transmute 금지

// ✅ SQL (SQLx — Parameterized)
let user = sqlx::query!(
    "SELECT * FROM users WHERE id = $1", id
).fetch_one(&pool).await?;  // ? 연산자 — unwrap() 대신

// ✅ 안전한 난수
use rand::RngCore;
let mut key = [0u8; 32];
rand::thread_rng().fill_bytes(&mut key);

// ✅ Path Traversal 방지
fn safe_path(base: &Path, user_input: &str) -> Result<PathBuf, Error> {
    let path = base.join(user_input).canonicalize()?;
    if !path.starts_with(base.canonicalize()?) {
        return Err(Error::InvalidPath);
    }
    Ok(path)
}

// ✅ TLS 최소 버전 (rustls — safe_defaults = TLS 1.2+)
let config = rustls::ClientConfig::builder()
    .with_safe_defaults()
    .with_root_certificates(roots)
    .with_no_client_auth();
```

보안 체크리스트 (Rust):
```
□ unwrap()/expect() → ? 연산자 또는 명시적 에러 처리
□ unsafe 블록: 최소화 + 반드시 // SAFETY: 주석 작성
□ std::mem::transmute 금지 → 명시적 타입 변환 사용
□ 정수 오버플로우: checked_add / saturating_add 사용 (release 모드 wrapping 주의)
□ Arc<Mutex<T>> 데드락: 락 획득 순서 일관성 유지
□ 환경변수 시크릿: std::env::var + .env (하드코딩 절대 금지)
□ cargo audit: 의존성 취약점 주기적 확인
□ cargo clippy -- -D warnings: 경고 전체 차단
```

---

## 12. 추가 OWASP Top 10 패턴 (v5.0 신규)

### Path Traversal (경로 순회)
```typescript
// ❌ 금지
const filePath = path.join(__dirname, 'uploads', req.query.filename)
fs.readFileSync(filePath)  // ../../../etc/passwd 가능

// ✅ 검증 필수
const filename = path.basename(req.query.filename as string)
const filePath = path.join(__dirname, 'uploads', filename)
if (!filePath.startsWith(path.join(__dirname, 'uploads'))) {
  throw new Error('Invalid path')
}
```

### SSRF (서버사이드 요청 위조)
```typescript
// ❌ 금지
const response = await fetch(req.body.url)  // 내부망 접근 가능

// ✅ URL 검증
const allowedHosts = new Set(['api.example.com', 'cdn.example.com'])
const parsed = new URL(req.body.url)
if (!allowedHosts.has(parsed.hostname)) {
  throw new Error('SSRF: URL not allowed')
}
```

### Open Redirect
```typescript
// ❌ 금지
res.redirect(req.query.returnUrl)  // 외부 사이트로 리다이렉트 가능

// ✅ 상대 경로만 허용
const returnUrl = req.query.returnUrl as string
const safeUrl = returnUrl?.startsWith('/') ? returnUrl : '/dashboard'
res.redirect(safeUrl)
```

### Mass Assignment
```typescript
// ❌ 금지 (isAdmin 같은 필드 덮어쓰기 가능)
await db.user.update({ where: { id }, data: req.body })

// ✅ 허용 필드만 추출
const { name, email, bio } = req.body  // isAdmin, role 등 제외
await db.user.update({ where: { id }, data: { name, email, bio } })
```

---

## 빠른 체크리스트 (코드 작성 전)

```
□ 모든 사용자 입력에 검증 있나?
□ SQL 쿼리에 parameterized 사용했나?
□ innerHTML / dangerouslySetInnerHTML 없나?
□ 토큰을 localStorage에 저장하지 않나?
□ 하드코딩된 시크릿 없나?
□ CORS에 와일드카드 * 없나?
□ 보호 라우트에 인증 미들웨어 있나?
□ 리소스 소유권 확인 있나?
□ 파일 경로에 path.basename() / realpath 검증 있나? (Path Traversal)
□ 외부 URL 요청에 allowedHosts 화이트리스트 있나? (SSRF)
□ 리다이렉트 URL이 상대 경로만 허용하나? (Open Redirect)
□ DB update/patch에 허용 필드만 명시적으로 추출했나? (Mass Assignment)
□ [Rust] unwrap()/unsafe 최소화, cargo audit 통과했나?
□ [Go] _ = err 패턴 없음, context 전파 확인했나?
```
