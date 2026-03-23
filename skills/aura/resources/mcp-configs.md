# AuraKit — MCP Configs (서버 사전 설정 가이드)

> `/aura mcp:` 모드. MCP 서버 설치·설정 원클릭.
> Claude Code MCP 통합 관리.

---

## 빠른 시작

```bash
/aura mcp:list               → 사용 가능한 MCP 서버 목록
/aura mcp:setup [server]     → MCP 서버 설치 + 환경변수 설정
/aura mcp:add [server]       → 기존 설정에 MCP 추가
/aura mcp:check              → 현재 설정된 MCP 상태 확인
/aura mcp:remove [server]    → MCP 서버 제거
/aura mcp:setup:all          → .aura/mcp-config.json 기반 일괄 설치
```

---

## MCP 카탈로그 (14종)

### 1. GitHub
버전 관리 + PR/이슈 통합
```bash
claude mcp add github -- npx -y @modelcontextprotocol/server-github
# env: GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx
# 용도: PR 생성/리뷰, 이슈 추적, 코드 검색
```

### 2. Filesystem
프로젝트 외부 파일 접근
```bash
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /path/to/dir
# 용도: 문서 디렉토리 탐색, 다중 루트 작업
```

### 3. PostgreSQL
데이터베이스 직접 쿼리
```bash
claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres "$DATABASE_URL"
# env: DATABASE_URL=postgresql://user:pass@localhost:5432/db
# 용도: 스키마 탐색, 쿼리 실행, 마이그레이션 검토
```

### 4. MySQL
MySQL 데이터베이스 쿼리
```bash
claude mcp add mysql -- npx -y @benborla29/mcp-server-mysql
# env: MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASS, MYSQL_DB
```

### 5. Slack
팀 커뮤니케이션 + 배포 알림
```bash
claude mcp add slack -- npx -y @modelcontextprotocol/server-slack
# env: SLACK_BOT_TOKEN=xoxb-xxx, SLACK_TEAM_ID=T0xxx
# 용도: 채널 메시지, 배포 알림, 스레드 응답
```

### 6. Brave Search
실시간 웹 검색
```bash
claude mcp add brave-search -- npx -y @modelcontextprotocol/server-brave-search
# env: BRAVE_API_KEY=BSAxxxxx
# 용도: 최신 문서 검색, 패키지 버전 확인, 에러 해결법
```

### 7. Linear
이슈 트래킹
```bash
claude mcp add linear -- npx -y @linear/linear-mcp-server
# env: LINEAR_API_KEY=lin_api_xxx
# 용도: 이슈 생성/업데이트, 사이클 계획, 로드맵 조회
```

### 8. Notion
문서 관리 + PRD 동기화
```bash
claude mcp add notion -- npx -y @notionhq/notion-mcp-server
# env: NOTION_API_KEY=secret_xxx
# 용도: 문서 생성/업데이트, 데이터베이스 쿼리
```

### 9. Sentry
에러 모니터링 통합
```bash
claude mcp add sentry -- npx -y @sentry/mcp-server
# env: SENTRY_AUTH_TOKEN=sntryu_xxx, SENTRY_ORG=my-org
# 용도: 에러 조회, 스택 트레이스 분석, 이슈 해결 추적
```

### 10. Docker
컨테이너 관리
```bash
claude mcp add docker -- npx -y @docker/docker-mcp-server
# 용도: 컨테이너 상태 확인, 이미지 관리, Docker Compose
```

### 11. AWS (실험적)
클라우드 인프라
```bash
claude mcp add aws -- npx -y @aws/aws-mcp-server
# env: AWS_PROFILE=default, AWS_REGION=ap-northeast-2
# 용도: Lambda, S3, CloudWatch 로그 분석
```

### 12. Jira
기업 이슈 트래킹
```bash
claude mcp add jira -- npx -y @atlassian/jira-mcp-server
# env: JIRA_HOST, JIRA_EMAIL, JIRA_API_TOKEN
```

### 13. Figma
디자인 시스템 통합
```bash
claude mcp add figma -- npx -y @figma/figma-mcp-server
# env: FIGMA_ACCESS_TOKEN=figd_xxx
# 용도: 컴포넌트 조회, 디자인 토큰 추출
```

### 14. Vercel
배포 관리
```bash
claude mcp add vercel -- npx -y @vercel/mcp-adapter
# env: VERCEL_TOKEN=xxx
# 용도: 배포 상태 확인, 환경변수 관리, 로그 조회
```

---

## 자동 설정 플로우

`/aura mcp:setup [server]` 실행 시:

```
1. 서버 설치
   claude mcp add [server] -- [command]

2. .env.example에 환경변수 템플릿 추가
   # [SERVER] MCP
   [ENV_VAR]=

3. 보안 체크
   .env → .gitignore 포함 확인 (B-2 자동)

4. 설치 확인
   claude mcp list → 등록 상태 확인
```

---

## 팀 설정 공유

```json
// .aura/mcp-config.json (민감 정보 제외, 팀 공유 가능)
{
  "servers": ["github", "linear", "slack"],
  "required_env": {
    "github": ["GITHUB_PERSONAL_ACCESS_TOKEN"],
    "linear": ["LINEAR_API_KEY"],
    "slack": ["SLACK_BOT_TOKEN", "SLACK_TEAM_ID"]
  }
}
```

팀원이 `/aura mcp:setup:all` 실행 → 위 목록 자동 설치 + env 템플릿 생성.

---

## 보안 규칙 (필수)

```
□ MCP 토큰 → 반드시 .env에 저장 (하드코딩 절대 금지)
□ .env → .gitignore 포함 (B-2에서 자동 검사)
□ 최소 권한 원칙 — 필요한 스코프만 요청
□ 개발/프로덕션 토큰 분리
□ 토큰 주기적 갱신 (90일 권장)
□ MCP 서버 버전 고정 (프로덕션 환경)
```

---

*MCP Configs — 14종 서버 · 원클릭 설치 · 팀 공유 · 보안 필수 규칙*
