# AuraKit — Framework Patterns

> 프레임워크별 베스트 프랙티스 패턴. BUILD 모드에서 Framework 필드 기반 자동 적용.
> project-profile.md의 Framework 필드로 자동 선택.

---

## Next.js App Router (상세 → build-pipeline.md 2-11)

### 파일 구조 패턴
```
app/
  (auth)/              ← Route Group (URL 영향 없음)
    login/page.tsx
    register/page.tsx
  (dashboard)/
    layout.tsx         ← 공유 레이아웃
    page.tsx           ← Server Component 기본
    loading.tsx        ← Suspense fallback (자동)
    error.tsx          ← Error Boundary (자동)
  api/
    [resource]/
      route.ts         ← REST API
```

### 데이터 페칭 계층
```typescript
// Server Component에서 직접 (권장)
export default async function Page() {
  const data = await db.item.findMany()  // DB 직접 접근
  return <List items={data} />
}

// 외부 API 페칭
export default async function Page() {
  const res = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 }  // 1시간 캐시
  })
  const data = await res.json()
  return <View data={data} />
}
```

### Metadata API
```typescript
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const product = await getProduct(params.id)
  return {
    title: product.name,
    description: product.description,
    openGraph: {
      images: [product.imageUrl],
    },
  }
}
```

---

## FastAPI (Python)

### 프로젝트 구조
```
app/
  main.py             ← FastAPI 앱 + 라우터 등록
  core/
    config.py         ← Pydantic Settings
    security.py       ← JWT / 인증 로직
    database.py       ← SQLAlchemy 세션
  models/             ← SQLAlchemy ORM 모델
  schemas/            ← Pydantic 요청/응답 스키마
  routers/            ← APIRouter 모듈
  services/           ← 비즈니스 로직
  dependencies.py     ← Depends() 공통 의존성
```

### 표준 라우터 패턴
```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.user import UserCreate, UserResponse
from app.services import user_service

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user),
):
    if user_service.get_by_email(db, user_data.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )
    return user_service.create(db, user_data)
```

### Pydantic Settings (설정 관리)
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000"]

    class Config:
        env_file = ".env"

settings = Settings()
```

---

## Django (Python)

### 프로젝트 구조
```
config/
  settings/
    base.py           ← 공통 설정
    development.py    ← 개발 환경
    production.py     ← 운영 환경
  urls.py
  wsgi.py
apps/
  users/
    models.py
    views.py
    serializers.py    ← DRF
    urls.py
    admin.py
    tests/
```

### Django REST Framework 표준 뷰
```python
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.contrib.auth import get_user_model

User = get_user_model()

class UserDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user  # 본인 정보만 수정 가능

class PostListCreateView(generics.ListCreateAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return Post.objects.select_related('author').filter(
            is_published=True
        ).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)
```

### 설정 분리
```python
# config/settings/production.py
from .base import *
import os

DEBUG = False
SECRET_KEY = os.environ['DJANGO_SECRET_KEY']
ALLOWED_HOSTS = os.environ['ALLOWED_HOSTS'].split(',')
DATABASES = {'default': dj_database_url.config()}

# 보안 헤더
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

---

## Spring Boot (Java)

### 프로젝트 구조
```
src/main/java/com/example/app/
  controller/         ← REST 컨트롤러
  service/            ← 비즈니스 로직 인터페이스 + 구현
  repository/         ← JPA 리포지토리
  domain/             ← 엔티티
  dto/                ← 요청/응답 DTO
  config/             ← 설정 클래스
  exception/          ← 예외 클래스 + GlobalExceptionHandler
  security/           ← Spring Security 설정
```

### 표준 컨트롤러
```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUser(
            @PathVariable @Positive Long id,
            @AuthenticationPrincipal UserDetails currentUser) {
        return ResponseEntity.ok(userService.findById(id));
    }

    @PostMapping
    public ResponseEntity<UserResponse> createUser(
            @Valid @RequestBody UserCreateRequest request) {
        UserResponse response = userService.create(request);
        URI location = ServletUriComponentsBuilder
            .fromCurrentRequest()
            .path("/{id}")
            .buildAndExpand(response.getId())
            .toUri();
        return ResponseEntity.created(location).body(response);
    }
}
```

### 전역 예외 처리
```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(NotFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("NOT_FOUND", e.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException e) {
        Map<String, String> errors = e.getBindingResult()
            .getFieldErrors().stream()
            .collect(Collectors.toMap(
                FieldError::getField,
                FieldError::getDefaultMessage
            ));
        return ResponseEntity.badRequest()
            .body(new ValidationErrorResponse("VALIDATION_ERROR", errors));
    }
}
```

---

## Laravel (PHP)

### 표준 API 패턴
```php
// Routes: routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('posts', PostController::class);
    Route::get('user', [UserController::class, 'me']);
});

// Controller (Form Request로 검증)
class PostController extends Controller
{
    public function store(StorePostRequest $request): JsonResponse
    {
        $post = Post::create([
            ...$request->validated(),
            'user_id' => $request->user()->id,
        ]);
        return response()->json(new PostResource($post), 201);
    }
}

// Form Request (입력 검증)
class StorePostRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'content' => ['required', 'string'],
            'published' => ['boolean'],
        ];
    }
}
```

---

## 프레임워크 감지 → 자동 패턴 적용

```
BUILD 모드 Step 2 실행 시:
  project-profile.md: Framework: Next.js  → Next.js App Router 패턴 적용
  project-profile.md: Framework: FastAPI  → FastAPI 표준 패턴 적용
  project-profile.md: Framework: Django   → Django/DRF 패턴 적용
  project-profile.md: Framework: Spring   → Spring Boot 패턴 적용
  project-profile.md: Framework: Laravel  → Laravel 패턴 적용
  미감지 → 언어 기반 일반 패턴 적용
```

---

*AuraKit Framework Patterns — Next.js · FastAPI · Django · Spring Boot · Laravel*
