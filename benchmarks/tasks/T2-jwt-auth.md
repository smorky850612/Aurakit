# T2 — JWT Refresh Token Flow

## Task
Implement a complete JWT refresh token system:
- `POST /api/auth/refresh` — issue new access token using refresh token
- `POST /api/auth/logout` — invalidate refresh token
- Refresh token stored in DB (revocable)
- Access token: 15min TTL, httpOnly cookie
- Refresh token: 7d TTL, httpOnly cookie, `sameSite: strict`
- Blacklist invalidated tokens on logout

Target stack: TypeScript + Express + Redis (token blacklist) + PostgreSQL

## Measurement
- Token usage: input + output
- Time to first file: seconds
- Files created/modified: count
- Security issues: count
- V1 build pass: yes/no

## Success Criteria
- Refresh endpoint returns new access token
- Logout invalidates refresh token in Redis
- Expired/invalid tokens return 401
- No tokens in response body (cookies only)
- Build passes
