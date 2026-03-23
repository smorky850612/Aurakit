# AuraKit — E2E Pipeline (Playwright)

> `/aura qa:e2e` 또는 QA 모드 E2E 요청 시 로딩.
> Zero-Config Playwright E2E — 설치부터 CI까지 자동.

---

## 빠른 시작

```bash
/aura qa:e2e                   → 전체 E2E 실행
/aura qa:e2e:[url]             → 특정 URL E2E
/aura qa:e2e:auth              → 인증 플로우 집중
/aura qa:e2e:setup             → Playwright 초기 설치
/aura qa:e2e:ci                → CI용 설정 생성
```

---

## Step 1: 설치 감지 + 초기화

```bash
# 설치 여부 확인
[ -f "playwright.config.ts" ] && echo "설치됨" || echo "미설치"

# 미설치 시 자동 설치
npm install -D @playwright/test
npx playwright install --with-deps chromium firefox
```

### playwright.config.ts 기본 템플릿

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html'], ['list']],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox',  use: { ...devices['Desktop Firefox'] } },
    { name: 'mobile',   use: { ...devices['Pixel 5'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
```

---

## Step 2: 핵심 시나리오 자동 생성

프로젝트 타입 감지(project-profile.md) → 시나리오 선택:

### 2.1 인증 플로우 (항상 포함)

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('인증 플로우', () => {
  test('로그인 성공', async ({ page }) => {
    await page.goto('/login');
    await page.fill('[data-testid="email"]', 'test@example.com');
    await page.fill('[data-testid="password"]', 'Password123!');
    await page.click('[data-testid="submit"]');
    await expect(page).toHaveURL('/dashboard');
  });

  test('잘못된 비밀번호 → 에러 표시', async ({ page }) => {
    await page.goto('/login');
    await page.fill('[data-testid="email"]', 'test@example.com');
    await page.fill('[data-testid="password"]', 'wrong');
    await page.click('[data-testid="submit"]');
    await expect(page.locator('[data-testid="error"]')).toBeVisible();
    await expect(page).toHaveURL('/login');
  });

  test('인증 없이 보호 페이지 접근 → /login 리다이렉트', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL('/login');
  });
});
```

### 2.2 핵심 CRUD 플로우

```typescript
// e2e/crud.spec.ts
import { test, expect } from '@playwright/test';

// 로그인 상태 재사용
test.use({ storageState: 'e2e/.auth/user.json' });

test.describe('CRUD', () => {
  test('생성 → 조회 → 수정 → 삭제', async ({ page }) => {
    await page.goto('/items');

    // Create
    await page.click('[data-testid="create-btn"]');
    await page.fill('[data-testid="name-input"]', '테스트 항목');
    await page.click('[data-testid="save-btn"]');
    await expect(page.locator('[data-testid="item"]')).toContainText('테스트 항목');

    // Update
    await page.click('[data-testid="edit-btn"]');
    await page.fill('[data-testid="name-input"]', '수정된 항목');
    await page.click('[data-testid="save-btn"]');
    await expect(page.locator('[data-testid="item"]')).toContainText('수정된 항목');

    // Delete
    await page.click('[data-testid="delete-btn"]');
    await page.click('[data-testid="confirm-delete"]');
    await expect(page.locator('[data-testid="item"]')).not.toBeVisible();
  });
});
```

### 2.3 반응형 테스트

```typescript
// e2e/responsive.spec.ts
import { test, expect } from '@playwright/test';

const viewports = [
  { name: '모바일', width: 375, height: 812 },
  { name: '태블릿', width: 768, height: 1024 },
  { name: '데스크톱', width: 1440, height: 900 },
];

for (const vp of viewports) {
  test(`레이아웃: ${vp.name}`, async ({ page }) => {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto('/');
    await expect(page.locator('nav')).toBeVisible();
    // 오버플로우 없음 확인
    const overflow = await page.evaluate(() => document.body.scrollWidth > window.innerWidth);
    expect(overflow).toBe(false);
  });
}
```

### 2.4 접근성 + 보안 시나리오

```typescript
// e2e/security.spec.ts
test.describe('보안', () => {
  test('XSS 입력 → 이스케이프 확인', async ({ page }) => {
    await page.goto('/search');
    await page.fill('[data-testid="search"]', '<script>alert(1)</script>');
    await page.click('[data-testid="search-btn"]');
    // alert 발생하지 않아야 함
    page.on('dialog', () => { throw new Error('XSS 발생!'); });
    await expect(page.locator('[data-testid="results"]')).toBeVisible();
  });

  test('인증 토큰 없이 API 호출 → 401', async ({ request }) => {
    const res = await request.get('/api/users');
    expect(res.status()).toBe(401);
  });
});
```

---

## Step 3: 실행

```bash
# 기본 실행 (헤드리스)
npx playwright test

# 특정 파일
npx playwright test auth.spec.ts

# UI 모드 (로컬 디버깅)
npx playwright test --ui

# 크로스 브라우저
npx playwright test --project=chromium --project=firefox

# CI 모드
npx playwright test --reporter=github
```

---

## Step 4: 실패 분석

```bash
# HTML 리포트
npx playwright show-report

# 트레이스 뷰어
npx playwright show-trace test-results/*/trace.zip
```

### 실패 패턴 & 수정

```
TimeoutError: Waiting for locator('[data-testid="X"]')
→ 원인: 요소 미존재 또는 지연 로딩
→ 수정: await page.waitForSelector('[data-testid="X"]', {state: 'visible'})

Error: locator.fill: not an input, textarea or contenteditable
→ 원인: 잘못된 셀렉터 (부모 요소 선택됨)
→ 수정: 더 구체적인 셀렉터 사용 (input[name="email"])

AssertionError: expect(received).toHaveURL(expected)
→ 원인: 리다이렉트 미발생
→ 수정: Promise.all로 클릭 + URL 변경 동시 감지
  await Promise.all([
    page.waitForURL('/dashboard'),
    page.click('[data-testid="submit"]'),
  ]);
```

---

## Step 5: CI 통합

### GitHub Actions

```yaml
# .github/workflows/e2e.yml
name: E2E
on: [push, pull_request]
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npx playwright test
        env:
          BASE_URL: http://localhost:3000
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

---

## 에이전트 배정

```
E2E-Coordinator (sonnet/opus(MAX)):
  → 시나리오 계획, 셀렉터 전략

E2E-Writer (haiku/sonnet(MAX)):
  → 테스트 코드 생성

E2E-Runner (haiku):
  → 실행 + 결과 파싱 (Fail-Only Output)

E2E-Analyzer (sonnet/opus(MAX)):
  → 실패 분석 + 수정 제안
```

---

## QA 리포트 통합

E2E 결과가 qa-pipeline.md 리포트에 추가됨:
```
## E2E 테스트
✅ auth.spec.ts     → 3/3 passed (chromium, firefox)
✅ crud.spec.ts     → 4/4 passed
❌ responsive.spec.ts → 2/3 failed
   ↳ 태블릿 레이아웃: nav 가시성 오류 (수정 제안 포함)
```

---

*E2E Pipeline — Playwright · Zero-Config · 크로스 브라우저 · CI 연동 · 접근성 + 보안 시나리오*
