# T1 — REST API with JWT Auth

## Task
Implement a REST API endpoint: `POST /api/auth/login`

Requirements:
- Accept `{ email, password }` body
- Validate input (required fields, email format)
- Query user from database
- Verify bcrypt password hash
- Return JWT in httpOnly cookie (not response body)
- Return `{ success: true, user: { id, email, name } }` on success
- Return `401` on invalid credentials (no detail leak)
- Rate limit: 5 requests / minute per IP

Target stack: TypeScript + Express + PostgreSQL + Prisma

## Measurement
- Token usage: input + output (measure via API response headers or proxy)
- Time to first file: seconds
- Files created: count
- Security issues: count (manual review)
- V1 build pass: yes/no

## Success Criteria
- All requirements met
- Build passes (`tsc --noEmit`)
- No hardcoded secrets
- Parameterized queries only
- JWT in httpOnly cookie
