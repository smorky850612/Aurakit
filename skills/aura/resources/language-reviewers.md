# AuraKit — Language-Specific Reviewers

> 프로젝트 언어에 따라 자동 로딩. BUILD/REVIEW/FIX 모드에서 language-specific 검증 실행.
> project-profile.md의 Language 필드로 자동 선택.

---

## 자동 로딩 규칙

```
project-profile.md: Language: TypeScript → typescript-reviewer 로딩
project-profile.md: Language: Python     → python-reviewer 로딩
project-profile.md: Language: Go         → go-reviewer 로딩
project-profile.md: Language: Java       → java-reviewer 로딩
project-profile.md: Language: Kotlin     → kotlin-reviewer 로딩
project-profile.md: Language: Rust       → rust-reviewer 로딩
project-profile.md: Language: C++        → cpp-reviewer 로딩
project-profile.md: Language: Swift      → swift-reviewer 로딩
project-profile.md: Language: PHP        → php-reviewer 로딩
project-profile.md: Language: Perl       → perl-reviewer 로딩

V1 빌드 실패 시: build-resolvers.md → 언어별 Build Resolver 자동 실행
```

---

## TypeScript / JavaScript Reviewer

```
CONV-TS-001: any 타입 금지 → unknown + type narrowing 사용
CONV-TS-002: non-null assertion (!) 최소화 → optional chaining (?.) 선호
CONV-TS-003: Promise 미처리 금지 → void operator 또는 catch 필수
CONV-TS-004: == 대신 === 사용
CONV-TS-005: console.log → 프로덕션 배포 전 제거

체크리스트:
□ strictNullChecks: true 설정 확인
□ 모든 함수 반환 타입 명시
□ enum 대신 const as const 사용 (트리쉐이킹)
□ 비동기 함수: async/await + try-catch
□ 배열 메서드 체인: 가독성 우선 (map→filter→reduce)

금지 패턴:
❌ any 캐스팅: (data as any).property
❌ // @ts-ignore (// @ts-expect-error로 대체 + 이유 주석)
❌ Object.assign() 대신 스프레드 연산자: {...obj, key: val}
```

---

## Python Reviewer

```
CONV-PY-001: 타입 힌트 필수 (Python 3.9+)
CONV-PY-002: f-string 사용 (format() 금지)
CONV-PY-003: comprehension 과용 금지 → 가독성 우선
CONV-PY-004: 예외 처리: 구체적 예외 타입 명시 (except Exception 최소화)
CONV-PY-005: __all__ 정의 (공개 API 명시)

보안 체크:
□ pickle 사용 시 신뢰할 수 없는 데이터 금지
□ subprocess: shell=True 금지 (shlex.split 사용)
□ eval()/exec() 사용자 입력에 절대 금지
□ yaml.load() → yaml.safe_load() 사용
□ SQL: %s 포맷팅 금지 → parameterized query

패턴 권장:
✅ pathlib.Path (os.path 대신)
✅ dataclasses / pydantic (dict 대신 타입 안전 모델)
✅ contextlib.contextmanager (리소스 관리)
✅ logging 모듈 (print 대신)
✅ pytest (unittest 대신)

금지 패턴:
❌ mutable default argument: def fn(lst=[]):
❌ bare except: except:
❌ global 변수 남용
```

---

## Go Reviewer

```
CONV-GO-001: 에러 무시 금지 → _ = err 패턴 차단
CONV-GO-002: goroutine 누수 방지 → context 전파 필수
CONV-GO-003: defer + recover 패닉 처리
CONV-GO-004: interface 최소화 → 구체적 타입 선호
CONV-GO-005: 테이블 드리븐 테스트 패턴

보안 체크:
□ fmt.Sprintf → SQL 쿼리 조합 금지 (db.Query + ? 사용)
□ exec.Command: 사용자 입력 직접 전달 금지
□ math/rand → crypto/rand (보안 난수)
□ TLS 버전: 최소 1.2 강제
□ context.WithTimeout: 모든 외부 호출에 적용

패턴 권장:
✅ errors.Is / errors.As (문자열 비교 금지)
✅ sync.WaitGroup / errgroup (goroutine 조율)
✅ io.Reader/Writer 인터페이스 (유연성)
✅ struct embedding (상속 대신)
✅ functional options pattern (설정 전달)

금지 패턴:
❌ panic() → 비즈니스 로직에서 사용 금지
❌ init() 함수 남용
❌ 긴 함수 (50줄 이상 → 분리 권장)
```

---

## Java Reviewer

```
CONV-JV-001: Optional 남용 금지 → 반환값에만 사용
CONV-JV-002: checked exception 최소화 → RuntimeException 선호
CONV-JV-003: final 변수 우선 (불변성)
CONV-JV-004: 스트림 API: 복잡한 파이프라인은 가독성 고려
CONV-JV-005: 로깅: SLF4J (System.out.println 금지)

보안 체크:
□ PreparedStatement 사용 (Statement 직접 쿼리 금지)
□ 직렬화: readObject() 검증 필수
□ XXE 방지: XML 파서 외부 엔티티 비활성화
□ 의존성: OWASP Dependency-Check 실행
□ Spring Security: CSRF 토큰 활성화

Spring Boot 패턴:
✅ @Validated + @Valid (입력 검증)
✅ @Transactional 경계 명확히
✅ Repository → Service → Controller 계층 분리
✅ DTO / Entity 분리 (노출 최소화)
✅ @ConfigurationProperties (하드코딩 설정 금지)

금지 패턴:
❌ @Autowired 필드 주입 → 생성자 주입 사용
❌ ConcurrentHashMap 없이 멀티스레드 Map 접근
❌ String + 반복 (StringBuilder 사용)
```

---

## Rust Reviewer

```
CONV-RS-001: unwrap() / expect() → 프로덕션 코드 금지
CONV-RS-002: clone() 과용 방지 → 참조 우선
CONV-RS-003: unsafe 블록: 최소화 + 충분한 주석
CONV-RS-004: Arc<Mutex<T>> → 필요성 재검토
CONV-RS-005: 에러 타입: thiserror / anyhow 활용

패턴 권장:
✅ ? 연산자 (unwrap 대신)
✅ impl Trait (동적 디스패치 최소화)
✅ derive 매크로 활용 (Debug, Clone, PartialEq)
✅ cargo clippy 통과 필수
✅ cargo fmt 적용 필수

금지 패턴:
❌ mem::transmute (unsafe 대안 탐색)
❌ std::process::exit() (main에서만 허용)
```

---

## Kotlin Reviewer

```
CONV-KT-001: var 대신 val 우선 (불변성)
CONV-KT-002: data class 활용 (equals/hashCode/toString 자동)
CONV-KT-003: sealed class로 상태 표현 (when 완전 처리)
CONV-KT-004: 확장 함수 남용 금지 → 인터페이스 고려
CONV-KT-005: coroutine: GlobalScope 금지 → CoroutineScope/viewModelScope 사용

보안 체크:
□ Serializable 객체: 역직렬화 검증
□ Android Keystore (민감 데이터 저장)
□ ProGuard/R8: API 키 난독화
□ HTTPS 강제: TrustManager 커스텀 금지 (테스트 코드 제외)

패턴 권장:
✅ 코루틴 Flow (LiveData 대신 — 테스트 용이)
✅ Hilt/Koin (의존성 주입)
✅ Sealed interface (Android UI State)
✅ runCatching { } (예외 처리 간결화)

금지 패턴:
❌ !! (non-null assertion) → ?: 또는 let 사용
❌ Thread.sleep() → delay() 사용
❌ AsyncTask (deprecated) → coroutine 사용
```

---

## C++ Reviewer

```
CONV-CPP-001: raw pointer 금지 → unique_ptr / shared_ptr 사용
CONV-CPP-002: C-style cast 금지 → static_cast / dynamic_cast / reinterpret_cast
CONV-CPP-003: using namespace std 금지 (헤더 파일에서)
CONV-CPP-004: Rule of 0/3/5 준수 (소멸자 있으면 복사/이동 연산자도)
CONV-CPP-005: 함수 크기: 50줄 이내

보안 체크:
□ 버퍼 오버플로우: std::array / std::vector (C 배열 금지)
□ 정수 오버플로우: 명시적 타입 크기 확인
□ Use-after-free: unique_ptr 사용으로 방지
□ 포맷 스트링: printf 직접 사용 시 사용자 입력 금지
□ 동적 메모리: new/delete 대신 RAII 패턴

패턴 권장:
✅ std::optional (nullable 대신)
✅ std::variant (union 대신 타입 안전)
✅ constexpr (컴파일 타임 계산)
✅ range-based for (인덱스 기반 for 대신)
✅ RAII (리소스 자동 해제)

금지 패턴:
❌ malloc/free (new/delete → smart pointer)
❌ gets() → fgets() 또는 std::getline
❌ sprintf() → snprintf() 또는 std::format (C++20)
❌ void* 캐스팅 남용
```

---

## Swift Reviewer

```
CONV-SW-001: var 대신 let 우선 (불변성)
CONV-SW-002: force unwrap (!) 금지 → guard let / if let 사용
CONV-SW-003: 클래스 대신 구조체 (값 타입 — 필요 시 클래스)
CONV-SW-004: async/await (GCD DispatchQueue 대신 — iOS 15+)
CONV-SW-005: @MainActor (UI 업데이트는 메인 스레드)

보안 체크:
□ Keychain (민감 데이터 — UserDefaults 저장 금지)
□ ATS (App Transport Security): HTTP 허용 최소화
□ 코드 서명: entitlements 최소 권한
□ 생체 인증: LocalAuthentication 프레임워크
□ 입력 검증: 모든 외부 데이터에 적용

패턴 권장:
✅ Combine / async-await (클로저 콜백 대신)
✅ @Observable / ObservableObject (상태 관리)
✅ Protocol + extension (믹스인 패턴)
✅ Result<Success, Failure> (에러 처리)
✅ Codable (JSON 직렬화 — 수동 파싱 금지)

금지 패턴:
❌ performSelector:withObject: (type-unsafe)
❌ NSNotificationCenter 과용 (delegate/Combine 선호)
❌ try! (try? 또는 do-catch)
```

---

## PHP Reviewer

```
CONV-PHP-001: 타입 힌트 필수 (PHP 8.0+) — 함수 인자 + 반환 타입 + 프로퍼티
CONV-PHP-002: PDO / 준비된 구문 필수 (mysql_query() 금지)
CONV-PHP-003: password_hash() / password_verify() (md5/sha1 저장 금지)
CONV-PHP-004: htmlspecialchars() — 출력 시 이스케이프 필수
CONV-PHP-005: Composer 의존성 관리 (수동 include/require 최소화)

보안 체크:
□ SQL Injection: PDO prepare() + bindParam() 필수
□ XSS: htmlspecialchars($var, ENT_QUOTES, 'UTF-8') 출력 시 항상 적용
□ CSRF: 폼에 CSRF 토큰 필수 (Laravel: @csrf / Symfony: csrf_token())
□ 파일 업로드: MIME 타입 검증 + 크기 제한 + 저장 경로 웹 루트 외부
□ session_regenerate_id(true) — 로그인 후 세션 ID 갱신
□ eval() 사용자 입력 절대 금지
□ shell_exec() / exec() / system() — 사용자 입력 전달 금지
□ open_basedir / disable_functions 프로덕션 설정 확인
□ error_reporting: 프로덕션에서 display_errors=Off (로그만 기록)

패턴 권장:
✅ PHP 8.1+ enum (상수 그룹 대신 타입 안전 열거형)
✅ readonly 프로퍼티 (PHP 8.1+) / readonly class (PHP 8.2+)
✅ match 표현식 (switch 대신 — 엄격 비교 + 반환값)
✅ named arguments (가독성 향상)
✅ Fiber (비동기 작업 — PHP 8.1+)
✅ null safe operator (?->) — null 체크 체인 간소화
✅ PHPStan / Psalm 정적 분석 (level max 권장)

금지 패턴:
❌ mysql_* 함수 (PHP 7 이후 제거)
❌ $_REQUEST 직접 사용 (명시적 $_GET/$_POST/$_SERVER 사용)
❌ include($_GET['page']) — 경로에 사용자 입력 금지 (LFI/RFI 취약점)
❌ extract($_POST) — 변수 오염 위험
❌ serialize()/unserialize() 사용자 입력에 적용 금지 (객체 주입 공격)
❌ == 비교 (=== 사용 — PHP 타입 저글링 방지)
❌ @ 에러 억제 연산자 (예외 처리로 대체)

성능 팁:
□ OPcache 활성화 (프로덕션 필수)
□ preload (PHP 7.4+): 자주 사용하는 클래스 사전 로딩
□ JIT 컴파일러 (PHP 8.0+): CPU-intensive 작업 시 활성화
□ 배열 대신 SplFixedArray (고정 크기 대량 데이터)
□ Generator (yield) — 대용량 데이터 순회 시 메모리 절약
□ 문자열 연결: . 반복 대신 implode() 또는 sprintf()
□ composer dump-autoload --optimize (프로덕션 배포)
```

---

## PHP Framework Reviewers

### Laravel
```
□ Eloquent ORM (raw DB::statement 최소화)
□ Form Request 클래스로 입력 검증 분리
□ 미들웨어로 인증/인가 처리
□ .env → config() 헬퍼 (환경변수 직접 접근 금지: env() 금지 in code)
□ Artisan 마이그레이션 관리 (수동 SQL 스키마 변경 금지)
□ Route Model Binding 활용 (수동 find/findOrFail 최소화)
□ Policy / Gate (인가 로직 컨트롤러에서 분리)
□ Queue (time-consuming 작업: 이메일, 외부 API 호출)
□ Laravel Sanctum / Passport (API 인증)

금지:
❌ 컨트롤러에 비즈니스 로직 직접 작성 (Service 계층 분리)
❌ N+1 쿼리: with() / load() eager loading 필수
❌ Mass Assignment 취약점: $fillable 또는 $guarded 명시
❌ blade에서 {!! $var !!} — 검증된 HTML만 허용
```

### Symfony
```
□ Doctrine ORM: DQL 또는 QueryBuilder (raw SQL 최소화)
□ Form Component: 입력 검증 + CSRF 자동 처리
□ Voter / Access Decision Manager (인가 로직)
□ .env → parameters.yaml → 서비스 주입 (getenv() 직접 사용 금지)
□ Messenger Component (비동기 메시지 처리)
□ Security Bundle: firewall + authenticator 설정
□ Dependency Injection: autowiring + 인터페이스 바인딩
□ Event Dispatcher: 도메인 이벤트 처리
□ Serializer: normalize/denormalize (수동 JSON 변환 금지)

금지:
❌ 컨트롤러에서 EntityManager 직접 호출 (Repository 패턴 사용)
❌ Twig에서 raw 필터 무분별 사용 (XSS 위험)
❌ kernel.secret: 환경변수 필수 (하드코딩 금지)
❌ Doctrine: lazy loading N+1 → fetch join / batch processing
```

---

## Perl Reviewer

```
CONV-PERL-001: use strict; use warnings; — 모든 스크립트 최상단 필수
CONV-PERL-002: use Modern::Perl 또는 명시적 버전 선언 (use v5.36;)
CONV-PERL-003: DBI placeholders 필수 (문자열 연결/보간 SQL 금지)
CONV-PERL-004: open(my $fh, '<', $file) or croak — 3-arg open + 에러 처리 필수
CONV-PERL-005: Carp 모듈 (croak/carp) — die/warn 대신 (호출자 관점 에러 보고)

보안 체크:
□ SQL: DBI->prepare() + execute(@params) — 문자열 보간 금지
□ 시스템 호출: system(LIST) 형태 (shell 해석 방지) — system($cmd) 금지
□ eval "string": 절대 금지 (블록 eval { } 만 허용)
□ CGI: 에러를 브라우저에 노출하지 않도록 Carp 설정
□ taint 모드: -T 플래그 (CGI/setuid/setgid 스크립트 필수)
□ 정규식: 사용자 입력 직접 삽입 금지 → quotemeta() / \Q...\E 사용
□ File::Temp (임시 파일 안전 생성 — 예측 가능 경로 금지)
□ 역직렬화: Storable::thaw 사용자 입력에 금지 → JSON::XS / Cpanel::JSON::XS 사용

패턴 권장:
✅ Moose / Moo (객체 시스템 — 순수 OOP)
✅ Type::Tiny (타입 제약 — Moose/Moo 통합)
✅ Try::Tiny (예외 처리 — eval {} 래퍼)
✅ Path::Tiny (파일 경로 — 안전하고 간결)
✅ Log::Log4perl / Log::Any (로깅 — print/warn 대신)
✅ namespace::autoclean (네임스페이스 오염 방지)
✅ cpanfile + Carton (의존성 잠금 관리)
✅ Perl::Critic (정적 분석 — severity 1~5)

금지 패턴:
❌ no strict; (디버깅 외 사용 금지)
❌ 2-arg open: open(FH, ">$file") — 경로 주입 위험
❌ 백틱/qx//에 사용자 입력 전달
❌ AUTOLOAD 남용 (명시적 메서드 정의 선호)
❌ goto (절대 금지 — 유지보수 불가)
❌ 심볼릭 레퍼런스: $$var_name (use strict 'refs' 위반)

성능 팁:
□ 정규식: /o 플래그 (변하지 않는 패턴 사전 컴파일)
□ 대용량 파일: readline 또는 while (<$fh>) — slurp 방지
□ 해시 슬라이스: @hash{@keys} (반복 조회 대신 일괄 추출)
□ Benchmark / Devel::NYTProf (성능 프로파일링)
□ Memoize (순수 함수 결과 캐싱)
□ XS 모듈: 성능 병목 시 C 확장 고려 (Inline::C / XS)
□ 문자열: join() (반복적 . 연결 대신)
□ List::Util (sum, max, min — 순수 Perl 루프 대신)
```

---

## Perl Framework Reviewers

### Mojolicious
```
□ Mojolicious::Lite (프로토타입) → 풀 앱 전환 시 Mojolicious 사용
□ 라우팅: $r->get('/path')->to('Controller#action') (명확한 컨트롤러 분리)
□ Mojo::Template: <%= %> (자동 이스케이프) / <%== %> (raw — 검증된 HTML만)
□ Mojo::Pg / Mojo::mysql: 비동기 DB 쿼리 + 마이그레이션
□ Mojo::UserAgent: 비동기 HTTP 클라이언트 (non-blocking I/O)
□ 입력 검증: $c->validation 또는 Mojolicious::Validator
□ 세션: $c->session (서명된 쿠키 — secret 필수 설정)
□ 웹소켓: Mojo::WebSocket (실시간 통신)

금지:
❌ blocking 호출을 non-blocking 컨텍스트에 혼용
❌ $c->param() 미검증 사용 (항상 validation 거쳐야 함)
❌ 앱 secret 미설정 (기본값은 안전하지 않음)
```

### Dancer2
```
□ 라우팅: get/post/put/del (HTTP 메서드별 명시적 핸들러)
□ 플러그인 시스템: Dancer2::Plugin::* (기능 확장)
□ Dancer2::Plugin::DBIC (DBIx::Class ORM 통합)
□ Template::Toolkit (템플릿 엔진 — 자동 이스케이프 설정)
□ config.yml → 환경별 설정 분리 (environments/*.yml)
□ Plack::Middleware (PSGI 미들웨어 스택 활용)
□ 세션: Dancer2::Session::Cookie (암호화 세션)
□ 입력 검증: Dancer2::Plugin::FormValidator 또는 수동 검증

금지:
❌ request->params 미검증 직접 사용
❌ 시크릿 키 config.yml에 평문 저장 (환경변수 사용)
❌ send_file()에 사용자 입력 경로 전달 (경로 탐색 공격)
```

---

## Python Framework Reviewers

### FastAPI
```
□ Pydantic v2 모델로 입력/출력 타입 정의
□ Depends() 의존성 주입 활용
□ background_tasks: 비동기 작업 처리
□ HTTPException: 표준 에러 응답
□ CORS: CORSMiddleware에 명시적 origins 목록
□ 인증: OAuth2PasswordBearer / JWT

금지:
❌ sync 함수에 I/O 작업 (async def 사용)
❌ 전역 상태 (request.app.state 활용)
```

### Django
```
□ ORM: raw() 사용 시 parameterized
□ CSRF: {% csrf_token %} 모든 폼에 필수
□ 미들웨어: SecurityMiddleware 활성화
□ SECRET_KEY: 환경변수 필수
□ DEBUG: 프로덕션에서 False
□ ALLOWED_HOSTS: 명시적 목록

금지:
❌ shell_plus에서 delete() 직접 실행 (프로덕션)
❌ select_related 없이 N+1 쿼리
```

---

## Java Framework Reviewers

### Spring Boot
```
□ application.yml: 민감정보 → 환경변수 참조
□ @RestController: 반환 타입 명시
□ Exception Handler: @ControllerAdvice 전역 처리
□ JPA: N+1 → @EntityGraph / fetch join
□ 테스트: @SpringBootTest vs @WebMvcTest 구분

금지:
❌ @Autowired 필드 주입 (생성자 주입)
❌ LazyInitializationException 무시
```

---

## 리뷰어 출력 포맷

```
🔍 Language Review — TypeScript

CONV-TS 체크: 5/5 Pass ✅
보안 체크: 8/8 Pass ✅

이슈 없음.

---

🔍 Language Review — Python

CONV-PY 체크: 4/5
  ⚠️  CONV-PY-004: bare except 발견 (auth.py:45)
      → except Exception as e: 로 수정 권장

보안 체크: 7/8
  ❌ CONV-PY-SEC-002: subprocess(shell=True) (utils.py:23)
      → shlex.split() + shell=False 필수
```

---

## Build Resolver 연동

V1 빌드 실패 감지 시 → `resources/build-resolvers.md` 자동 로딩:
```
Go 빌드 실패    → Go-Resolver 에이전트 (haiku)
Rust 빌드 실패  → Rust-Resolver 에이전트 (sonnet — borrow checker 복잡도)
Java 빌드 실패  → Java-Resolver 에이전트 (haiku)
Kotlin 빌드 실패 → Kotlin-Resolver 에이전트 (haiku)
C++ 빌드 실패  → Cpp-Resolver 에이전트 (sonnet — 링커 에러 복잡도)
Swift 빌드 실패 → Swift-Resolver 에이전트 (haiku)
Python 오류    → Python-Resolver 에이전트 (haiku)
PHP 빌드 실패  → PHP-Resolver 에이전트 (haiku)
Perl 빌드 실패 → Perl-Resolver 에이전트 (haiku)
```

---

*AuraKit Language Reviewers — TS/JS · Python · Go · Java · Rust · Kotlin · C++ · Swift · PHP · Perl · Framework-Specific · Build Resolver 연동*
