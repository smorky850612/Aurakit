# AuraKit — BaaS Pipeline (Supabase / Firebase / bkend)

> `/aura baas:` 호출 시 로딩. 백엔드 없이 풀스택 앱 구축.

---

## BaaS 선택 가이드

| 기준 | Supabase | Firebase | bkend.ai |
|------|----------|----------|----------|
| DB | PostgreSQL | Firestore (NoSQL) | PostgreSQL |
| 인증 | 내장 (JWT) | Firebase Auth | 내장 (JWT) |
| 실시간 | Realtime | Firestore realtime | — |
| 파일 | Storage | Storage | 프리사인 URL |
| 가격 | 관대한 무료 | 무료 제한 | 요청 기반 |
| 자체 호스팅 | ✅ | ❌ | ❌ |
| SQL | ✅ (RLS) | ❌ | ✅ |

---

## Supabase 패턴

### 클라이언트 초기화

```typescript
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

### 인증

```typescript
// 회원가입
const { data, error } = await supabase.auth.signUp({
  email, password,
  options: { data: { display_name: name } }
});

// 로그인
const { data, error } = await supabase.auth.signInWithPassword({ email, password });

// 소셜 로그인
await supabase.auth.signInWithOAuth({ provider: 'google',
  options: { redirectTo: `${location.origin}/auth/callback` }
});

// 세션 가져오기
const { data: { session } } = await supabase.auth.getSession();
```

### CRUD (RLS 사용)

```typescript
// SELECT (RLS 자동 적용)
const { data, error } = await supabase
  .from('posts')
  .select('id, title, created_at')
  .eq('user_id', session.user.id)
  .order('created_at', { ascending: false })
  .limit(20);

// INSERT
const { data, error } = await supabase
  .from('posts')
  .insert({ title, content, user_id: session.user.id })
  .select()
  .single();
```

### Row Level Security (RLS)

```sql
-- 사용자 본인 데이터만 접근
CREATE POLICY "users_own_data" ON posts
  FOR ALL USING (auth.uid() = user_id);
```

---

## Firebase 패턴

```typescript
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, query, where, getDocs } from 'firebase/firestore';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

// 쿼리
const q = query(collection(db, 'posts'), where('userId', '==', userId));
const snapshot = await getDocs(q);
const posts = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
```

---

## bkend.ai 패턴

```typescript
import { createClient } from '@bknd/client';

const client = createClient({ baseUrl: process.env.BKND_URL! });

// 인증
await client.auth.signIn({ email, password });

// 데이터
const { data } = await client.data('posts').list({ filter: { userId: client.auth.userId } });
const { data: post } = await client.data('posts').create({ title, content });
```

---

## 환경 변수 설정

```bash
# Supabase (.env.local)
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
# 서버 전용 — NEXT_PUBLIC_ 접두사 절대 금지
SUPABASE_SERVICE_ROLE=<service-role-key-server-only>

# Firebase (.env.local)
NEXT_PUBLIC_FIREBASE_API_KEY=<api-key>
NEXT_PUBLIC_FIREBASE_PROJECT_ID=my-project

# bkend (.env.local)
BKND_URL=https://api.bknd.io
BKND_API_KEY=<api-key>
```

---

## 보안 체크리스트

- ✅ RLS/Security Rules 활성화 (BaaS 기본 OFF 주의)
- ✅ Service Role Key는 서버 전용 (NEXT_PUBLIC_ 접두사 금지)
- ✅ `.env.local` → `.gitignore` 포함 확인
- ✅ API 요청에 인증 토큰 포함 (Bearer 헤더)
- ❌ 클라이언트에서 Service Role Key 사용 금지

---

## 검증

```bash
# 환경 변수 확인
node -e "console.log(process.env.NEXT_PUBLIC_SUPABASE_URL ? 'OK' : 'MISSING')"

# Supabase 연결 테스트
curl -s -H "apikey: $ANON_KEY" "$SUPABASE_URL/rest/v1/health" | jq .
```
