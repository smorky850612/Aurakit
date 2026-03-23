# AuraKit — Build Resolvers (언어별 빌드 오류 해결)

> FIX 모드 V1 빌드 실패 시 자동 트리거.
> project-profile.md의 언어/스택 감지 → 해당 Resolver 선택.

---

## 통합 방식

V1 빌드 실패 시 자동 연동:
```
project-profile.md → 언어 감지
→ 해당 Resolver 에이전트 실행 (격리)
→ 에러 파싱 → 패턴 매칭 → 최소 수정
→ V1 재실행 → Pass 확인
→ 실패 시: 수동 확인 요청
```

명시적 호출:
```bash
/aura fix:go build error      → Go Resolver
/aura fix:rust borrow error   → Rust Resolver
/aura fix:java spring error   → Java Resolver
/aura fix:kotlin type error   → Kotlin Resolver
/aura fix:cpp linker error    → C++ Resolver
/aura fix:swift build error   → Swift Resolver
/aura fix:python import error → Python Resolver
```

---

## Go Resolver

### 에러 패턴 & 수정

```
undefined: [identifier]
→ 원인: import 누락 또는 타이포
→ 수정: import 추가, go mod tidy

cannot use [type] as [type]
→ 원인: 타입 불일치
→ 수정: 명시적 타입 변환 또는 인터페이스 구현 확인

imported and not used: "[package]"
→ 원인: 미사용 import
→ 수정: 해당 import 제거 (goimports -w 자동)

go: module declares its path as: [X]; but was required as: [Y]
→ 원인: go.mod 경로 불일치
→ 수정: go mod tidy

import cycle not allowed
→ 원인: 순환 의존성
→ 수정: 인터페이스 추출 또는 패키지 구조 재설계

panic: interface conversion: [type] is not [interface]
→ 원인: 타입 단언 실패
→ 수정: ok 패턴으로 안전하게 변환
  val, ok := x.(Type); if !ok { ... }
```

### 자동 수정 명령

```bash
go mod tidy                  # 의존성 정리
goimports -w .               # import 자동 수정 (설치 시)
go vet ./...                 # 정적 분석
gofmt -w .                   # 포맷 수정
go generate ./...            # 코드 생성 (있는 경우)
```

---

## Rust Resolver

### Borrow Checker 패턴

```
error[E0382]: borrow of moved value: `x`
→ 원인: 소유권 이동 후 사용
→ 수정 옵션:
  // 1. clone()
  let y = x.clone(); use(x); use(y);
  // 2. 참조 사용
  let y = &x;

error[E0502]: cannot borrow `x` as mutable ... also borrowed as immutable
→ 원인: 가변/불변 참조 동시 존재
→ 수정: 참조 범위 분리 (블록으로 감싸기)

error[E0106]: missing lifetime specifier
→ 원인: 라이프타임 명시 필요
→ 수정:
  fn foo<'a>(x: &'a str) -> &'a str { x }

error[E0308]: mismatched types
→ 원인: 반환 타입 불일치
→ 수정: 명시적 타입 변환 또는 반환값 수정

error[E0277]: the trait bound `[T]: [Trait]` is not satisfied
→ 원인: 트레이트 미구현
→ 수정: impl Trait for T 추가 또는 where 절 수정
```

### 자동 수정 명령

```bash
cargo check                      # 빠른 체크 (링킹 없음)
cargo fix --allow-dirty          # 자동 수정
cargo clippy -- -D warnings      # 클리피 경고 → 에러
cargo fmt                        # 포맷 수정
```

---

## Java / Spring Boot Resolver

### 컴파일 에러 패턴

```
cannot find symbol: class [Name]
→ 원인: import 누락 또는 클래스명 오류
→ 수정: import 추가 또는 의존성 확인

incompatible types: [A] cannot be converted to [B]
→ 원인: 타입 불일치
→ 수정: 명시적 캐스팅 또는 제네릭 수정

@Autowired field ... is not a Spring bean
→ 원인: @Component/@Service/@Repository 누락
→ 수정: 어노테이션 추가

BeanCreationException: Error creating bean with name [X]
→ 원인: 순환 의존성 또는 설정 오류
→ 수정: @Lazy 또는 @Configuration 구조 검토

NoSuchBeanDefinitionException: No qualifying bean of type [X]
→ 원인: 빈 미등록
→ 수정: 컴포넌트 스캔 경로 확인 또는 @Bean 정의
```

### 자동 수정 명령

```bash
./mvnw dependency:resolve -q    # 의존성 해결 (Maven)
./gradlew dependencies -q       # 의존성 트리 (Gradle)
./mvnw clean compile -q         # 클린 빌드
./gradlew clean build -q        # Gradle 클린 빌드
```

---

## Kotlin Resolver

### 에러 패턴

```
Overload resolution ambiguity
→ 원인: 함수 오버로딩 충돌
→ 수정: 명시적 타입 지정

Smart cast to [Type] is impossible
→ 원인: var + nullable 타입
→ 수정: val로 변경 또는 지역 변수로 복사
  val localX = x; if (localX != null) { use(localX) }

None of the following candidates is applicable
→ 원인: 함수 시그니처 불일치
→ 수정: 파라미터 타입/개수 확인

Unresolved reference: [name]
→ 원인: import 누락 또는 확장 함수 미적용
→ 수정: import 추가 또는 패키지 확인

Type mismatch: inferred type is [A] but [B] was expected
→ 원인: 타입 추론 실패
→ 수정: 명시적 타입 지정
  val x: List<String> = emptyList()

Null can not be a value of a non-null type [Type]
→ 원인: nullable 타입에 non-null 대입
→ 수정: ?: null-safety 연산자 사용 또는 타입을 T?로 변경
```

### 자동 수정 명령

```bash
./gradlew clean build -q        # Gradle 클린 빌드
./gradlew ktlintFormat          # KtLint 자동 포맷 (있는 경우)
```

---

## C++ Resolver

### 에러 패턴

```
undefined reference to `function_name`
→ 원인: 링킹 실패 (선언은 있고 정의 없음)
→ 수정: 구현 파일 추가 또는 라이브러리 링킹
  # CMakeLists.txt:
  target_link_libraries(target lib)

error: use of undeclared identifier '[name]'
→ 원인: 헤더 미포함 또는 선언 순서
→ 수정: #include 추가 또는 전방 선언

error: no matching function for call to '[func]'
→ 원인: 함수 오버로딩 해결 실패
→ 수정: 명시적 캐스팅 또는 함수 시그니처 확인

'std::[name]' was not declared in this scope
→ 원인: STL 헤더 누락
→ 수정: 해당 헤더 추가
  string → #include <string>
  vector → #include <vector>
  map    → #include <map>

multiple definition of '[symbol]'
→ 원인: ODR(One Definition Rule) 위반
→ 수정: 헤더에서 정의 → 소스 파일로 이동, 또는 inline 추가

expected ';' before ... / expected ')' before ...
→ 원인: 세미콜론/괄호 누락 (연쇄 에러 주의)
→ 수정: 실제 오류는 위쪽 줄에서 찾기
```

### 자동 수정 명령

```bash
cmake --build build --clean-first    # CMake 클린 빌드
make -j4 2>&1 | head -50             # Make (첫 50줄만)
clang-tidy src/*.cpp                 # 정적 분석
clang-format -i src/*.cpp src/*.h    # 포맷 수정
```

---

## Swift Resolver

### 에러 패턴

```
Value of type '[X]' has no member '[member]'
→ 원인: 잘못된 타입 또는 API 변경
→ 수정: 문서 확인, 올바른 프로퍼티/메서드 사용

Cannot convert value of type '[A]' to expected argument type '[B]'
→ 원인: 타입 불일치
→ 수정: as? 캐스팅 또는 타입 변환 메서드 사용

Use of undeclared type '[Name]'
→ 원인: import 누락 또는 모듈 미추가
→ 수정: import 추가 또는 Package.swift 의존성 확인

Initializer 'init' requires that '[Type]' conform to '[Protocol]'
→ 원인: 프로토콜 준수 필요
→ 수정: extension으로 프로토콜 구현 추가

Expression is unused / Result of call is unused
→ 원인: @discardableResult 미적용 또는 의도치 않은 표현식
→ 수정: 반환값 처리 또는 _ = 사용

'[X]' is only available in [iOS/macOS] [version] or newer
→ 원인: 최소 지원 버전 미달
→ 수정: @available 조건 추가 또는 iOS Deployment Target 수정
```

### 자동 수정 명령

```bash
swift build                      # SPM 빌드
swift package resolve            # 의존성 해결
swift package update             # 의존성 업데이트
xcodebuild -scheme App -quiet    # Xcode 빌드 (Xcode 프로젝트)
```

---

## Python / PyTorch Resolver

### 에러 패턴

```
ModuleNotFoundError: No module named '[package]'
→ 원인: 패키지 미설치 또는 venv 미활성화
→ 수정: pip install [package]
  또는: source .venv/bin/activate

ImportError: cannot import name '[name]' from '[module]'
→ 원인: API 변경 또는 잘못된 이름
→ 수정: 해당 버전 문서 확인, pip show [package]로 버전 확인

RuntimeError: CUDA out of memory
→ 원인: GPU 메모리 부족
→ 수정:
  torch.cuda.empty_cache()
  # 배치 사이즈 줄이기 (//2)
  # torch.cuda.amp.autocast() 활성화

RuntimeError: Expected all tensors to be on the same device
→ 원인: CPU/GPU 텐서 혼용
→ 수정: .to(device) 통일, device 변수 일관성 확인

AttributeError: '[Module]' object has no attribute '[method]'
→ 원인: 버전 불일치 API
→ 수정: pip install --upgrade [package]
  또는 호환 API 사용

TypeError: [func]() got an unexpected keyword argument '[arg]'
→ 원인: API 변경 (구버전 파라미터)
→ 수정: 최신 API 문서 참조, 파라미터명 수정
```

### 자동 수정 명령

```bash
pip install -r requirements.txt  # 의존성 설치
pip check                        # 의존성 충돌 확인
python -m py_compile *.py        # 문법 검사
ruff check . --fix               # 린트 자동 수정 (ruff 있는 경우)
```

---

## 에이전트 배정

| 언어 | Resolver | ECO | PRO | MAX |
|------|----------|-----|-----|-----|
| Go | Go-Resolver | haiku | haiku | sonnet |
| Rust | Rust-Resolver | sonnet | sonnet | opus |
| Java/Spring | Java-Resolver | haiku | sonnet | opus |
| Kotlin | Kotlin-Resolver | haiku | haiku | sonnet |
| C++ | Cpp-Resolver | sonnet | sonnet | opus |
| Swift | Swift-Resolver | haiku | haiku | sonnet |
| Python/PyTorch | Python-Resolver | haiku | haiku | sonnet |

Rust/C++는 복잡한 에러 패턴으로 sonnet 이상 사용.

---

*Build Resolvers — Go · Rust · Java · Kotlin · C++ · Swift · Python/PyTorch · FIX 모드 자동 연동*
