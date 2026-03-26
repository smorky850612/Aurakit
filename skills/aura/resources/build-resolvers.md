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

## Python / PyTorch Resolver

### 에러 패턴 & 수정

```
ModuleNotFoundError: No module named '[package]'
→ 원인: 패키지 미설치 또는 venv 미활성화
→ 수정: pip install [package]
  또는: source .venv/bin/activate
  확인: which python → 올바른 인터프리터 경로인지 검증

ImportError: cannot import name '[name]' from '[module]'
→ 원인: API 변경 또는 잘못된 이름
→ 수정: 해당 버전 문서 확인, pip show [package]로 버전 확인
  흔한 사례: from collections import Mapping → Python 3.10+에서 제거됨
  → from collections.abc import Mapping 으로 변경

RuntimeError: CUDA out of memory
→ 원인: GPU 메모리 부족
→ 수정:
  torch.cuda.empty_cache()
  # 배치 사이즈 줄이기 (//2)
  # torch.cuda.amp.autocast() 활성화
  # gradient checkpointing: model.gradient_checkpointing_enable()

RuntimeError: Expected all tensors to be on the same device
→ 원인: CPU/GPU 텐서 혼용
→ 수정: .to(device) 통일, device 변수 일관성 확인
  device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
  model.to(device); inputs = inputs.to(device)

AttributeError: '[Module]' object has no attribute '[method]'
→ 원인: 버전 불일치 API
→ 수정: pip install --upgrade [package]
  또는 호환 API 사용

TypeError: [func]() got an unexpected keyword argument '[arg]'
→ 원인: API 변경 (구버전 파라미터)
→ 수정: 최신 API 문서 참조, 파라미터명 수정

SyntaxError: invalid syntax
→ 원인: Python 2/3 문법 혼용, 오타, 또는 f-string 내 백슬래시
→ 수정:
  print("x") (Python 3)
  f-string 내 백슬래시 불가 → 변수로 분리
  # bad:  f"path\\{name}"  → good: sep = "\\"; f"path{sep}{name}"

IndentationError: unexpected indent / unindent
→ 원인: 탭/스페이스 혼용 또는 들여쓰기 불일치
→ 수정: 에디터에서 탭 → 4 스페이스 자동 변환 설정
  python -tt script.py → 탭/스페이스 혼용 검출

RecursionError: maximum recursion depth exceeded
→ 원인: 무한 재귀 또는 재귀 깊이 초과
→ 수정: 재귀 로직 점검, 필요 시 sys.setrecursionlimit() 조정
  또는 반복문(iterative)으로 변환

ValueError: too many values to unpack / not enough values to unpack
→ 원인: 언패킹 대상과 변수 개수 불일치
→ 수정: 대상 객체 길이 확인 (len()), * 연산자로 가변 언패킹
  a, *rest = some_list
```

### 타입 시스템 에러 (mypy / pyright)

```
error: Incompatible types in assignment (expression has type "X", variable has type "Y")
→ 원인: 타입 어노테이션과 실제 값 불일치
→ 수정: 올바른 타입 어노테이션 적용 또는 Union 타입 사용
  x: Union[int, str] = get_value()
  # Python 3.10+: x: int | str = get_value()

error: Item "None" of "Optional[X]" has no attribute "Y"
→ 원인: Optional 타입에서 None 가능성 미처리
→ 수정: None 체크 후 접근
  if obj is not None:
      obj.method()

error: Argument of type "X" cannot be assigned to parameter of type "Y"
→ 원인: 함수 호출 시 타입 불일치
→ 수정: 캐스팅 또는 함수 시그니처 수정
  from typing import cast
  result = cast(TargetType, value)

error: "X" has no attribute "Y"
→ 원인: 타입 추론 실패 또는 동적 속성
→ 수정: Protocol 정의, TypedDict 사용, 또는 TYPE_CHECKING 분기
  from typing import TYPE_CHECKING
  if TYPE_CHECKING:
      from module import SomeClass

error: Cannot infer type argument [N] of "func"
→ 원인: 제네릭 함수에서 타입 추론 실패
→ 수정: 명시적 타입 인자 전달
  result = func[int](args)  # Python 3.12+ 또는 TypeVar 사용
```

### 패키지 관리자 문제 (pip / poetry / conda)

```
pip:
  ERROR: Could not find a version that satisfies the requirement [pkg]==[ver]
  → 원인: 해당 버전이 현재 Python 버전과 호환 불가 또는 존재하지 않음
  → 수정: pip install [pkg] (최신 호환 버전), 또는 Python 버전 확인
    pip index versions [pkg] → 사용 가능한 버전 목록 확인

  ERROR: pip's dependency resolver does not currently support backtracking
  → 원인: 의존성 간 버전 충돌
  → 수정: pip install --upgrade pip → 최신 resolver 사용
    pip install [pkg1] [pkg2] 동시 설치로 충돌 해결
    최종 수단: pip install --no-deps [pkg] → 의존성 무시 (위험)

  ERROR: Cannot uninstall '[pkg]'. It is a distutils installed project
  → 원인: 시스템 패키지와 충돌
  → 수정: pip install --ignore-installed [pkg]
    또는 venv 사용 (권장)

poetry:
  SolverProblemError: ... is not compatible ...
  → 원인: pyproject.toml 버전 범위 충돌
  → 수정: poetry update 또는 버전 범위 완화
    poetry add [pkg]@latest → 최신 호환 버전 추가
    poetry lock --no-update → lock 파일 재생성 (버전 유지)

  PackageNotFoundError: Package [pkg] not found
  → 원인: private index 미설정 또는 패키지명 오타
  → 수정: pyproject.toml에 [[tool.poetry.source]] 추가
    또는 poetry source add [name] [url]

conda:
  ResolvePackageNotFound / UnsatisfiableError
  → 원인: 채널에 해당 패키지/버전 없음
  → 수정: conda install -c conda-forge [pkg]
    또는: conda config --add channels conda-forge
    pip와 conda 혼용 시 → conda 환경 내에서 pip 사용 주의
```

### 의존성 해결 전략

```
1. 가상 환경 격리 (필수)
   python -m venv .venv && source .venv/bin/activate  # Unix
   python -m venv .venv && .venv\Scripts\activate      # Windows
   → 시스템 Python 오염 방지

2. 의존성 고정
   pip freeze > requirements.txt             # 현재 환경 스냅샷
   pip-compile requirements.in               # pip-tools 사용 (권장)
   poetry lock                               # poetry lock 파일 생성

3. 충돌 진단
   pip check                                 # 호환성 확인
   pipdeptree                                # 의존성 트리 시각화
   pipdeptree --reverse --packages [pkg]     # 특정 패키지 역추적
   poetry show --tree                        # poetry 의존성 트리

4. 클린 재설치
   pip install --force-reinstall -r requirements.txt
   poetry install --no-cache                 # 캐시 무시 재설치

5. Python 버전별 분기
   python_requires >= "3.8" 확인 (setup.cfg / pyproject.toml)
   tox / nox 로 멀티버전 테스트
```

### 환경별 주의사항 (Environment Gotchas)

```
Windows:
  - 경로 구분자: os.path.join() 또는 pathlib.Path 사용 (하드코딩 금지)
  - 인코딩: open(file, encoding="utf-8") 명시 (기본이 cp949/cp1252)
  - 긴 경로: Windows 10+에서 LongPathsEnabled 레지스트리 설정 필요
  - pip install 빌드 실패 → Visual C++ Build Tools 설치 필요
    (Microsoft C++ Build Tools 또는 Visual Studio Installer)

macOS:
  - system Python 사용 금지 → brew install python 또는 pyenv 사용
  - SSL 인증서: pip install certifi && /Applications/Python*/Install\ Certificates.command
  - Apple Silicon (M1/M2/M3):
    일부 패키지 arm64 미지원 → arch -x86_64 pip install [pkg]
    또는 conda-forge에서 arm64 빌드 확인
  - tensorflow-macos / tensorflow-metal → Apple GPU 가속 별도 패키지

Linux:
  - python3-dev / python3-devel 패키지 필요 (C extension 빌드 시)
  - libffi-dev, libssl-dev → 암호화 관련 패키지 빌드 의존성
  - deadsnakes PPA (Ubuntu): 최신 Python 버전 설치
    sudo add-apt-repository ppa:deadsnakes/ppa

Docker:
  - 멀티스테이지 빌드: builder 단계에서 pip install → 최종 이미지에 복사
  - --no-cache-dir 사용 → 이미지 크기 축소
  - requirements.txt 변경 시만 레이어 재빌드:
    COPY requirements.txt .
    RUN pip install -r requirements.txt
    COPY . .

PyTorch 전용:
  - CUDA 버전 불일치: nvidia-smi 버전과 torch CUDA 버전 일치 필수
    torch.version.cuda → 설치된 CUDA 런타임 확인
    nvcc --version → 시스템 CUDA Toolkit 확인
  - CPU 전용 설치: pip install torch --index-url https://download.pytorch.org/whl/cpu
  - nightly 빌드: pip install --pre torch --index-url https://download.pytorch.org/whl/nightly/cu121
```

### 자동 수정 명령

```bash
pip install -r requirements.txt      # 의존성 설치
pip check                            # 의존성 충돌 확인
python -m py_compile *.py            # 문법 검사
ruff check . --fix                   # 린트 자동 수정 (ruff 있는 경우)
mypy . --ignore-missing-imports      # 타입 체크 (mypy)
pyright .                            # 타입 체크 (pyright)
black . --check                      # 포맷 확인
black .                              # 포맷 자동 수정
isort . --check-only                 # import 정렬 확인
isort .                              # import 정렬 수정
python -m pytest --tb=short          # 테스트 실행 (짧은 트레이스백)
pip-audit                            # 보안 취약점 스캔
```

---

## Java / Spring Boot Resolver

### 컴파일 에러 패턴

```
cannot find symbol: class [Name]
→ 원인: import 누락 또는 클래스명 오류
→ 수정: import 추가 또는 의존성 확인
  IDE 자동 import 또는 수동으로 정확한 패키지 경로 추가

incompatible types: [A] cannot be converted to [B]
→ 원인: 타입 불일치
→ 수정: 명시적 캐스팅 또는 제네릭 수정
  List<Object> → List<String> 변환 시 stream().map() 사용

@Autowired field ... is not a Spring bean
→ 원인: @Component/@Service/@Repository 누락
→ 수정: 어노테이션 추가
  또는 @Configuration 클래스에서 @Bean 메서드로 정의

BeanCreationException: Error creating bean with name [X]
→ 원인: 순환 의존성 또는 설정 오류
→ 수정: @Lazy 또는 @Configuration 구조 검토
  Spring Boot 2.6+ 기본 순환 참조 금지:
  spring.main.allow-circular-references=true (임시) → 구조 리팩토링 (권장)

NoSuchBeanDefinitionException: No qualifying bean of type [X]
→ 원인: 빈 미등록
→ 수정: 컴포넌트 스캔 경로 확인 또는 @Bean 정의
  @SpringBootApplication의 패키지 위치 → 하위 패키지만 스캔

java.lang.ClassNotFoundException: [class]
→ 원인: 클래스패스에 해당 클래스 없음
→ 수정: 의존성 추가 (pom.xml / build.gradle)
  mvn dependency:tree → 어떤 jar에 포함되어 있는지 확인

java.lang.NoSuchMethodError: '[method]'
→ 원인: 컴파일 시점과 런타임 시점의 라이브러리 버전 불일치
→ 수정: mvn dependency:tree -Dverbose → 중복/충돌 확인
  <exclusions>로 충돌 의존성 제거

java.lang.UnsupportedClassVersionError: [class] has been compiled by a more recent version
→ 원인: 컴파일된 JDK > 실행 JDK
→ 수정: JAVA_HOME 확인, 올바른 JDK 버전 설정
  javac -version / java -version 비교

error: unmappable character for encoding UTF-8
→ 원인: 소스 파일 인코딩 불일치
→ 수정: 파일을 UTF-8로 저장
  Maven: <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>

error: package [X] does not exist
→ 원인: 의존성 미다운로드 또는 scope 문제
→ 수정: mvn dependency:resolve
  test scope에서만 사용 가능한 의존성을 main에서 사용하는 경우 scope 변경
```

### 타입 시스템 에러 & 제네릭 문제

```
error: incompatible types: inference variable T has incompatible bounds
→ 원인: 제네릭 타입 추론 실패
→ 수정: 명시적 타입 인자 전달
  Collections.<String>emptyList()
  또는 변수에 타입 명시: List<String> list = Collections.emptyList();

warning: unchecked or unsafe operations
→ 원인: raw type 사용 (제네릭 미적용)
→ 수정: 제네릭 타입 파라미터 추가
  List list → List<String> list
  @SuppressWarnings("unchecked") → 최후의 수단

error: method [X] in class [Y] cannot be applied to given types
→ 원인: 메서드 시그니처와 호출 인자 불일치
→ 수정: 파라미터 타입/개수 확인, 오버로딩 메서드 중 정확한 것 선택

error: [X] is not a functional interface
→ 원인: 람다 표현식을 비함수형 인터페이스에 대입
→ 수정: @FunctionalInterface 어노테이션 확인
  추상 메서드가 정확히 1개인지 확인

ClassCastException: [A] cannot be cast to [B]
→ 원인: 런타임 타입 변환 실패
→ 수정: instanceof 체크 후 캐스팅
  if (obj instanceof TargetType target) { ... }  // Java 16+ pattern matching

NullPointerException
→ 원인: null 참조 접근
→ 수정: Optional 사용 또는 null 체크
  Optional.ofNullable(value).map(...).orElse(default)
  Java 14+: NullPointerException 메시지에 상세 원인 포함 (-XX:+ShowCodeDetailsInExceptionMessages)
```

### 패키지 관리자 문제 (Maven / Gradle)

```
Maven:
  [ERROR] Failed to execute goal ... Could not resolve dependencies
  → 원인: repository에 해당 아티팩트 없음
  → 수정:
    mvn dependency:resolve -U    # 강제 업데이트
    ~/.m2/settings.xml 에서 저장소 URL 확인
    <repositories> 에 필요한 저장소 추가

  [ERROR] Plugin [X] not found in any plugin repository
  → 원인: 플러그인 저장소 미설정
  → 수정: <pluginRepositories> 추가 또는 Maven Central 접근 확인

  [WARNING] The POM for [X] is missing, no dependency information available
  → 원인: 로컬 캐시 손상
  → 수정: rm -rf ~/.m2/repository/[group]/[artifact]
    mvn dependency:purge-local-repository

  Maven Enforcer: RequireJavaVersion 실패
  → 원인: JAVA_HOME이 요구 버전과 불일치
  → 수정: JAVA_HOME 설정, mvn -version으로 확인

Gradle:
  Could not resolve all dependencies for configuration ':compileClasspath'
  → 원인: 저장소 미설정 또는 버전 없음
  → 수정:
    repositories { mavenCentral(); google() }  # build.gradle
    ./gradlew --refresh-dependencies          # 캐시 새로고침

  Execution failed for task ':compileJava'. Compilation failed
  → 원인: Java 소스 레벨 불일치
  → 수정: build.gradle에서 sourceCompatibility / targetCompatibility 설정
    java { sourceCompatibility = JavaVersion.VERSION_17 }

  Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'
  → 원인: Android 프로젝트에서 SDK/NDK 버전 불일치
  → 수정: local.properties의 sdk.dir, build.gradle의 compileSdkVersion 확인

  Gradle wrapper version mismatch
  → 원인: gradle-wrapper.properties의 distributionUrl 불일치
  → 수정: ./gradlew wrapper --gradle-version [version]
    또는 gradle/wrapper/gradle-wrapper.properties 직접 수정
```

### 의존성 해결 전략

```
1. 의존성 트리 분석
   mvn dependency:tree -Dverbose                  # Maven 전체 트리 (충돌 포함)
   mvn dependency:tree -Dincludes=[groupId]        # 특정 그룹 필터링
   ./gradlew dependencies --configuration compileClasspath  # Gradle 컴파일 의존성

2. 버전 충돌 해결
   Maven:
     <dependencyManagement> 에서 버전 고정 (BOM 패턴)
     <dependency>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-dependencies</artifactId>
       <version>3.2.0</version>
       <type>pom</type>
       <scope>import</scope>
     </dependency>

   Gradle:
     implementation platform('org.springframework.boot:spring-boot-dependencies:3.2.0')
     또는 constraints { implementation('com.example:lib:1.0') }

3. 전이적 의존성 제외
   Maven:
     <exclusions>
       <exclusion>
         <groupId>commons-logging</groupId>
         <artifactId>commons-logging</artifactId>
       </exclusion>
     </exclusions>
   Gradle:
     implementation('com.example:lib:1.0') { exclude group: 'commons-logging' }

4. 로컬 캐시 정리
   rm -rf ~/.m2/repository          # Maven 전체 캐시 삭제 (최후 수단)
   rm -rf ~/.gradle/caches          # Gradle 전체 캐시 삭제
   ./gradlew clean --no-build-cache # Gradle 빌드 캐시 무시
```

### 환경별 주의사항 (Environment Gotchas)

```
JDK 버전:
  - Java 8 → 17 → 21 마이그레이션 시 주요 변경사항:
    Java 9+: 모듈 시스템 (JPMS) → --add-opens / --add-exports 필요할 수 있음
    Java 11: javax.xml.bind 제거됨 → jakarta.xml.bind 별도 추가
    Java 17: sealed classes, pattern matching 도입
    Java 21: virtual threads, sequenced collections
  - JAVA_HOME 확인: echo $JAVA_HOME && java -version

Spring Boot 버전:
  - Spring Boot 2.x → 3.x 마이그레이션:
    javax.* → jakarta.* 패키지 변경 (전체 치환 필요)
    Spring Security: WebSecurityConfigurerAdapter 제거됨 → SecurityFilterChain @Bean 패턴
    최소 Java 17 필요
  - application.properties / application.yml 키 변경 확인:
    spring.redis.* → spring.data.redis.*

빌드 환경:
  - CI/CD에서 Maven wrapper 권한: chmod +x mvnw
  - Docker 빌드: eclipse-temurin 이미지 사용 (Oracle JDK 라이선스 주의)
  - Gradle daemon OOM: org.gradle.jvmargs=-Xmx2g (gradle.properties)
  - 멀티 모듈 프로젝트: 루트에서 mvn clean install -pl [module] -am

인코딩:
  - 소스 파일: UTF-8 강제 (Maven: encoding 설정, Gradle: compileJava.options.encoding)
  - JVM 기본 인코딩: -Dfile.encoding=UTF-8 (CI에서 명시 권장)

테스트:
  - JUnit 4 → 5 마이그레이션: @Test import 경로 변경
    org.junit.Test → org.junit.jupiter.api.Test
  - Mockito inline mocking: Java 16+ 에서 --add-opens 필요 또는 mockito-inline 의존성
```

### 자동 수정 명령

```bash
./mvnw dependency:resolve -q        # 의존성 해결 (Maven)
./mvnw dependency:tree -Dverbose    # 의존성 트리 + 충돌 표시
./mvnw clean compile -q             # 클린 빌드
./mvnw versions:display-dependency-updates  # 업데이트 가능한 의존성 표시
./gradlew dependencies -q           # 의존성 트리 (Gradle)
./gradlew clean build -q            # Gradle 클린 빌드
./gradlew dependencyUpdates         # Gradle 버전 업데이트 확인 (플러그인 필요)
google-java-format --replace *.java # 포맷 자동 수정
```

---

## Kotlin Resolver

### 에러 패턴 & 수정

```
Overload resolution ambiguity
→ 원인: 함수 오버로딩 충돌
→ 수정: 명시적 타입 지정
  val result: String = ambiguousFunc(arg)
  또는 as 캐스팅으로 파라미터 타입 명시: func(arg as Int)

Smart cast to [Type] is impossible
→ 원인: var + nullable 타입 (가변 변수는 중간에 변경될 수 있어 스마트캐스트 불가)
→ 수정: val로 변경 또는 지역 변수로 복사
  val localX = x; if (localX != null) { use(localX) }
  또는 ?.let { } 사용: x?.let { use(it) }

None of the following candidates is applicable
→ 원인: 함수 시그니처 불일치
→ 수정: 파라미터 타입/개수 확인
  named arguments로 명확하게: func(name = "value", count = 1)

Unresolved reference: [name]
→ 원인: import 누락 또는 확장 함수 미적용
→ 수정: import 추가 또는 패키지 확인
  확장 함수: import 경로에 확장 함수 정의 파일 포함 필요

Type mismatch: inferred type is [A] but [B] was expected
→ 원인: 타입 추론 실패
→ 수정: 명시적 타입 지정
  val x: List<String> = emptyList()

Null can not be a value of a non-null type [Type]
→ 원인: nullable 타입에 non-null 대입
→ 수정: ?: null-safety 연산자 사용 또는 타입을 T?로 변경
  val result = nullableValue ?: defaultValue

Expecting member declaration
→ 원인: 클래스 본문에 잘못된 코드 (함수 호출 등)
→ 수정: init {} 블록 안으로 이동 또는 함수로 래핑

'when' expression must be exhaustive
→ 원인: sealed class/enum의 모든 분기가 처리되지 않음
→ 수정: 누락된 분기 추가 또는 else → 사용
  when (result) {
      is Success -> ...
      is Error -> ...
      // else → ... (모든 서브클래스 처리 시 불필요)
  }

Platform declaration clash: The following declarations have the same JVM signature
→ 원인: JVM에서 동일한 시그니처로 컴파일되는 함수 2개 이상 존재
→ 수정: @JvmName 어노테이션으로 JVM 레벨 이름 변경
  @JvmName("filterStrings") fun filter(list: List<String>): List<String>
  @JvmName("filterInts") fun filter(list: List<Int>): List<Int>

'public' function exposes its 'internal' parameter type [Type]
→ 원인: 가시성 불일치 (public 함수가 internal 타입을 노출)
→ 수정: 함수 가시성을 internal로 줄이거나 타입을 public으로 변경

Suspension functions can be called only within coroutine body
→ 원인: suspend 함수를 일반 함수에서 호출
→ 수정: 호출 함수도 suspend로 선언하거나 coroutine builder 사용
  runBlocking { suspendFunc() }       // 메인/테스트
  lifecycleScope.launch { suspendFunc() }  // Android
  viewModelScope.launch { suspendFunc() }  // ViewModel
```

### 타입 시스템 심화

```
제네릭 variance 에러:
  Type parameter [T] is declared as 'out' but occurs in 'in' position
  → 원인: 공변(out)/반변(in) 위반
  → 수정: variance 방향 확인
    interface Producer<out T>  → T를 반환만 가능
    interface Consumer<in T>   → T를 받기만 가능
    둘 다 필요 시 → 불변(invariant): <T>

  Type argument is not within its bounds
  → 원인: 제네릭 bound 위반
  → 수정: where 절 또는 upper bound 확인
    fun <T : Comparable<T>> sort(list: List<T>)

Nothing 타입 추론 문제:
  val list = listOf()   → List<Nothing> 추론됨
  → 수정: 명시적 타입 지정: val list = listOf<String>()
    또는: val list: List<String> = listOf()

reified 타입 파라미터:
  Cannot use 'T' as reified type parameter. Use a class instead.
  → 원인: inline 함수에서 reified 없이 타입 파라미터 사용
  → 수정: inline fun <reified T> parseJson(json: String): T
    주의: reified는 inline 함수에서만 사용 가능

SAM 변환 문제:
  Type mismatch: inferred type is () -> Unit but [JavaInterface] was expected
  → 원인: Java SAM 인터페이스에 Kotlin 람다 전달 시 변환 실패
  → 수정: fun interface로 선언 (Kotlin 인터페이스의 경우)
    또는 SAM 생성자 사용: JavaInterface { /* lambda */ }
```

### 패키지 관리자 문제 (Gradle / Maven)

```
Gradle (Kotlin DSL):
  Unresolved reference: implementation
  → 원인: plugins 블록에서 Kotlin/Java 플러그인 미적용
  → 수정:
    plugins {
        kotlin("jvm") version "1.9.22"
        // 또는 id("org.jetbrains.kotlin.jvm") version "1.9.22"
    }

  e: Could not find [artifact] in [repository]
  → 원인: Kotlin 컴파일러 아티팩트 누락
  → 수정: settings.gradle.kts에 pluginManagement 저장소 추가
    pluginManagement {
        repositories { gradlePluginPortal(); mavenCentral() }
    }

  Module was compiled with an incompatible version of Kotlin
  → 원인: 프로젝트와 의존 라이브러리의 Kotlin 버전 불일치
  → 수정: Kotlin 버전 통일
    kotlin("jvm") version "1.9.22"  → 모든 모듈 동일 버전
    또는 의존 라이브러리 업데이트

  Kotlin reflection is not available (KotlinReflection not found)
  → 원인: kotlin-reflect 의존성 누락
  → 수정: implementation(kotlin("reflect"))

Kotlin Multiplatform:
  Could not resolve [target] platform dependencies
  → 원인: 타겟 플랫폼 설정 누락
  → 수정: kotlin { [target]() } 블록에 정확한 타겟 설정
    sourceSets 구조 확인 (commonMain, jvmMain, iosMain 등)

  Incompatible Kotlin/Native version
  → 원인: Kotlin/Native 컴파일러와 라이브러리 버전 불일치
  → 수정: 전체 Kotlin 관련 의존성 버전 통일

Android + Kotlin:
  Execution failed for task ':app:kaptDebugKotlin'
  → 원인: KAPT 어노테이션 프로세서 오류
  → 수정:
    kapt.use.worker.api=false (gradle.properties)
    또는 KSP로 마이그레이션 (권장):
    id("com.google.devtools.ksp") version "1.9.22-1.0.17"
```

### 의존성 해결 전략

```
1. 의존성 트리 분석
   ./gradlew dependencies --configuration compileClasspath
   ./gradlew dependencyInsight --dependency [pkg] --configuration compileClasspath

2. Kotlin BOM 사용 (버전 일관성)
   implementation(platform(kotlin("bom")))
   implementation(platform("org.jetbrains.kotlinx:kotlinx-coroutines-bom:1.7.3"))

3. 버전 카탈로그 (Gradle 7.0+)
   gradle/libs.versions.toml 에서 중앙 관리:
   [versions]
   kotlin = "1.9.22"
   coroutines = "1.7.3"
   [libraries]
   kotlinx-coroutines = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "coroutines" }

4. 멀티모듈 프로젝트 통일
   루트 build.gradle.kts에서 allprojects / subprojects 블록으로 버전 관리
   또는 Convention Plugins 패턴 사용 (buildSrc / build-logic)

5. Kotlin/JVM 호환성 매트릭스
   Kotlin 1.8.x → JDK 8~19
   Kotlin 1.9.x → JDK 8~21
   Kotlin 2.0.x → JDK 8~22
   jvmToolchain(17) → Gradle이 자동으로 JDK 다운로드/설정
```

### 환경별 주의사항 (Environment Gotchas)

```
Kotlin/JVM:
  - Kotlin 컴파일러 버전과 stdlib 버전 일치 필수
  - kotlin-stdlib-jdk7 / jdk8 → Kotlin 1.8+에서 kotlin-stdlib로 통합됨
  - @JvmStatic, @JvmField, @JvmOverloads → Java interop 필수 어노테이션

Android:
  - AGP(Android Gradle Plugin) + Kotlin 버전 호환성 확인
    https://developer.android.com/studio/releases/gradle-plugin
  - compose compiler 버전 → Kotlin 버전에 종속
    Kotlin 1.9.22 → Compose Compiler 1.5.8
    Kotlin 2.0+ → Compose Compiler Gradle Plugin 사용
  - R8/ProGuard: Kotlin reflection 사용 시 keep rules 추가 필요
    -keep class kotlin.Metadata { *; }

Coroutines:
  - runBlocking은 메인 스레드/Android UI에서 사용 금지 (데드락 위험)
  - Dispatchers.IO / Dispatchers.Default 적절히 사용
  - 구조적 동시성: SupervisorJob + CoroutineExceptionHandler 패턴

KMP (Kotlin Multiplatform):
  - expect/actual 선언 시 actual 구현 누락 → 빌드 실패
  - iOS 타겟: Xcode Command Line Tools 필수
  - Native 메모리 모델: new memory model (Kotlin 1.7.20+ 기본)

CI/CD:
  - Gradle daemon 종료: --no-daemon (CI에서 권장)
  - 캐싱: ~/.gradle/caches 경로 캐시 (빌드 속도 개선)
  - Kotlin 컴파일 메모리: kotlin.daemon.jvmargs=-Xmx2g (gradle.properties)
```

### 자동 수정 명령

```bash
./gradlew clean build -q                # Gradle 클린 빌드
./gradlew ktlintFormat                  # KtLint 자동 포맷 (있는 경우)
./gradlew detekt                        # 정적 분석 (detekt)
./gradlew dependencies --scan           # 의존성 분석 (Gradle build scan)
./gradlew kaptDebugKotlin 2>&1 | head -50  # KAPT 에러 확인
kotlinc -script script.kts              # 스크립트 실행
```

---

## C++ Resolver

### 에러 패턴 & 수정

```
undefined reference to `function_name`
→ 원인: 링킹 실패 (선언은 있고 정의 없음)
→ 수정: 구현 파일 추가 또는 라이브러리 링킹
  # CMakeLists.txt:
  target_link_libraries(target lib)
  # 수동 컴파일: g++ main.cpp utils.cpp -o app (모든 소스 포함)

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
  unordered_map → #include <unordered_map>
  algorithm → #include <algorithm>   (sort, find, etc.)
  memory → #include <memory>         (unique_ptr, shared_ptr)
  filesystem → #include <filesystem> (C++17)
  format → #include <format>         (C++20)
  ranges → #include <ranges>         (C++20)

multiple definition of '[symbol]'
→ 원인: ODR(One Definition Rule) 위반
→ 수정: 헤더에서 정의 → 소스 파일로 이동, 또는 inline 추가
  inline void func() { ... }    // C++17 inline variable도 동일
  inline constexpr int MAX = 100;

expected ';' before ... / expected ')' before ...
→ 원인: 세미콜론/괄호 누락 (연쇄 에러 주의)
→ 수정: 실제 오류는 위쪽 줄에서 찾기
  클래스 정의 뒤 세미콜론: class Foo { ... };  ← 이 세미콜론 누락이 흔함

error: no viable conversion from '[A]' to '[B]'
→ 원인: 암시적 변환 불가
→ 수정: 명시적 변환 추가
  static_cast<TargetType>(value)
  explicit 생성자가 암시적 변환을 막는 경우 → static_cast 필수

error: incomplete type '[Type]' used in nested name specifier
→ 원인: 전방 선언만 있고 완전한 정의가 없음
→ 수정: 해당 타입의 완전한 헤더 #include
  전방 선언으로는 포인터/참조 선언만 가능, 멤버 접근 불가

error: static assertion failed: [message]
→ 원인: static_assert 조건 불만족 (컴파일 시간 체크)
→ 수정: 메시지에 표시된 조건 확인 후 타입/값 수정

error: use of deleted function '[func]'
→ 원인: 복사/이동 생성자/대입연산자가 삭제됨
→ 수정: std::move() 사용 또는 명시적 복사 구현
  unique_ptr → std::move(ptr) (복사 불가, 이동만 가능)

error: call to implicitly-deleted copy constructor of '[Type]'
→ 원인: 클래스 멤버 중 복사 불가 타입 포함
→ 수정: 이동 생성자 사용 또는 해당 멤버를 shared_ptr로 변경

error: constexpr variable '[name]' must be initialized by a constant expression
→ 원인: constexpr 변수에 런타임 값 대입
→ 수정: const로 변경 또는 constexpr 가능한 표현식 사용

warning: comparison of integer expressions of different signedness
→ 원인: signed/unsigned 비교
→ 수정: 타입 통일
  for (size_t i = 0; i < vec.size(); ++i)  // int i → size_t i
```

### 템플릿 에러

```
error: no matching function for call to '[template_func]<...>'
→ 원인: 템플릿 인스턴스화 실패
→ 수정: 템플릿 인자 명시 또는 SFINAE 조건 확인
  template<typename T> auto func(T val) -> std::enable_if_t<std::is_integral_v<T>, T>;

error: dependent name is parsed as non-type; use 'typename' keyword
→ 원인: 종속 타입 앞에 typename 키워드 누락
→ 수정:
  typename Container::iterator it;  // typename 필수
  typename std::remove_reference<T>::type  // C++14: std::remove_reference_t<T>

error: template argument deduction/substitution failed
→ 원인: 템플릿 인자 추론 실패
→ 수정: 명시적 템플릿 인자 전달
  func<int, std::string>(42, "hello");

"candidate template ignored" (대량의 에러 메시지)
→ 원인: Concepts (C++20) 미충족 또는 SFINAE 조건 불만족
→ 수정: requires 절 조건 확인
  template<typename T> requires std::integral<T>
  void process(T val);
```

### 패키지 관리자 / 빌드 시스템 문제 (CMake / Makefile / Conan / vcpkg)

```
CMake:
  CMake Error: Could not find a package configuration file provided by "[Pkg]"
  → 원인: find_package()에 해당하는 Config 파일 없음
  → 수정:
    sudo apt install lib[pkg]-dev              # Ubuntu
    brew install [pkg]                         # macOS
    vcpkg install [pkg]                        # vcpkg
    또는 CMAKE_PREFIX_PATH 설정:
    cmake -DCMAKE_PREFIX_PATH=/path/to/pkg ..

  CMake Error: The source directory "[dir]" does not contain a CMakeLists.txt file
  → 원인: 빌드 디렉토리에서 cmake 실행 경로 오류
  → 수정: cmake -S . -B build  (소스/빌드 디렉토리 명시)

  CMake Error at CMakeLists.txt: Unknown CMake command "[cmd]"
  → 원인: CMake 버전이 너무 낮음
  → 수정: cmake_minimum_required(VERSION 3.xx) 확인
    cmake --version → 업그레이드 필요 시 최신 CMake 설치

  Target "[target]" links to target "[dep]" but the target was not found
  → 원인: 의존 타겟 정의 누락
  → 수정: find_package([dep] REQUIRED) 또는 add_subdirectory() 추가

Makefile:
  make: *** No rule to make target '[file]', needed by '[target]'
  → 원인: 소스 파일 누락 또는 경로 오류
  → 수정: Makefile의 소스 목록 확인, 파일 존재 여부 점검

  make: *** No targets specified and no makefile found
  → 원인: Makefile 미존재 또는 이름 오류
  → 수정: ls Makefile / ls makefile 확인
    cmake / configure 먼저 실행해서 Makefile 생성

Conan:
  ERROR: Missing prebuilt package for '[pkg]'
  → 원인: 바이너리 패키지 미빌드
  → 수정: conan install . --build=missing

  ERROR: Conflict in [pkg] ... different versions required
  → 원인: 의존성 버전 충돌
  → 수정: conanfile.txt / conanfile.py에서 버전 범위 조정
    또는 [options] 에서 override

vcpkg:
  error: failed to install [pkg]
  → 원인: 빌드 도구 미설치 또는 triplet 불일치
  → 수정:
    vcpkg install [pkg]:x64-windows   # Windows
    vcpkg install [pkg]:x64-linux     # Linux
    vcpkg install [pkg]:arm64-osx     # macOS ARM
    CMAKE_TOOLCHAIN_FILE 설정:
    cmake -DCMAKE_TOOLCHAIN_FILE=[VCPKG_ROOT]/scripts/buildsystems/vcpkg.cmake ..
```

### 의존성 해결 전략

```
1. CMake FetchContent (Modern CMake 3.14+)
   include(FetchContent)
   FetchContent_Declare(
     googletest
     GIT_REPOSITORY https://github.com/google/googletest.git
     GIT_TAG v1.14.0
   )
   FetchContent_MakeAvailable(googletest)
   → 소스에서 자동 다운로드 + 빌드

2. 패키지 매니저 사용
   vcpkg: manifest mode (vcpkg.json) 권장
   conan: conanfile.py → 세밀한 제어 가능
   CPM.cmake: FetchContent 래퍼, 캐시 지원

3. 시스템 패키지 (Linux)
   apt: sudo apt install libboost-all-dev libssl-dev
   yum: sudo yum install boost-devel openssl-devel
   pkg-config: pkg-config --cflags --libs openssl

4. Header-Only 라이브러리
   단일 헤더 다운로드 → include/ 디렉토리에 배치
   또는 FetchContent / git submodule 사용
   target_include_directories(target PUBLIC include/)

5. 링크 순서 (중요)
   정적 라이브러리 링크 순서: 의존하는 쪽이 먼저
   target_link_libraries(app lib_high_level lib_low_level)
   순환 의존 시: -Wl,--start-group ... -Wl,--end-group
```

### 환경별 주의사항 (Environment Gotchas)

```
Windows (MSVC):
  - Visual Studio Build Tools 또는 전체 VS 설치 필요
  - MSVC 비표준 확장 주의: /permissive- 옵션으로 엄격 모드
  - Windows.h 매크로 충돌: #define NOMINMAX (min/max 매크로 비활성)
  - DLL export: __declspec(dllexport) / __declspec(dllimport)
  - 긴 경로: cmake -DCMAKE_OBJECT_PATH_MAX=260 또는 심볼릭 링크
  - 디버그/릴리즈 런타임 혼합 금지: /MD vs /MDd 통일

macOS (Clang):
  - Xcode Command Line Tools: xcode-select --install
  - Apple Clang ≠ LLVM Clang: brew install llvm (최신 기능 필요 시)
  - Apple Silicon: arm64 + x86_64 유니버설 바이너리
    cmake -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" ..
  - libc++ (기본) vs libstdc++: 혼합 링크 금지
  - rpath 설정: install_name_tool -add_rpath @executable_path/../lib app

Linux (GCC/Clang):
  - C++ 표준 지정: -std=c++17 / -std=c++20 / -std=c++23
  - ABI 호환성: GCC 5+ → C++11 ABI 기본 (_GLIBCXX_USE_CXX11_ABI=1)
    라이브러리와 ABI 불일치 시 → 동일 컴파일러/버전으로 재빌드
  - sanitizer 사용: -fsanitize=address,undefined (디버그 빌드에서 메모리 오류 검출)
  - static linking: -static (glibc static은 권장하지 않음, musl libc 사용)

크로스 컴파일:
  - CMAKE_TOOLCHAIN_FILE로 크로스 컴파일러 설정
  - sysroot 경로 설정: CMAKE_SYSROOT
  - QEMU로 테스트: qemu-[arch] ./test_binary

C++ 표준 호환성:
  - C++11: auto, lambda, move semantics, smart pointers
  - C++14: generic lambda, make_unique, variable templates
  - C++17: structured bindings, if constexpr, std::optional, filesystem
  - C++20: concepts, ranges, coroutines, modules, std::format
  - C++23: std::expected, deducing this, std::print
  - 컴파일러별 지원 수준 확인: https://en.cppreference.com/w/cpp/compiler_support
```

### 자동 수정 명령

```bash
cmake -S . -B build && cmake --build build   # CMake 빌드
cmake --build build --clean-first             # CMake 클린 빌드
make -j$(nproc) 2>&1 | head -50              # Make (병렬 빌드, 첫 50줄)
clang-tidy src/*.cpp -- -std=c++17            # 정적 분석
clang-format -i src/*.cpp src/*.h             # 포맷 수정
cppcheck --enable=all src/                    # 추가 정적 분석
cmake --build build --target test             # CTest 테스트 실행
valgrind --leak-check=full ./build/app        # 메모리 누수 검사 (Linux)
```

---

## Swift Resolver

### 에러 패턴 & 수정

```
Value of type '[X]' has no member '[member]'
→ 원인: 잘못된 타입 또는 API 변경
→ 수정: 문서 확인, 올바른 프로퍼티/메서드 사용
  Xcode 자동완성으로 올바른 API 탐색

Cannot convert value of type '[A]' to expected argument type '[B]'
→ 원인: 타입 불일치
→ 수정: as? 캐스팅 또는 타입 변환 메서드 사용
  Int → String: String(intValue)
  String → Int: Int(stringValue) ?? 0

Use of undeclared type '[Name]'
→ 원인: import 누락 또는 모듈 미추가
→ 수정: import 추가 또는 Package.swift 의존성 확인
  import Foundation / import UIKit / import SwiftUI

Initializer 'init' requires that '[Type]' conform to '[Protocol]'
→ 원인: 프로토콜 준수 필요
→ 수정: extension으로 프로토콜 구현 추가
  extension MyType: Codable { ... }
  extension MyType: Hashable { ... }

Expression is unused / Result of call is unused
→ 원인: @discardableResult 미적용 또는 의도치 않은 표현식
→ 수정: 반환값 처리 또는 _ = 사용
  _ = someFunc()

'[X]' is only available in [iOS/macOS] [version] or newer
→ 원인: 최소 지원 버전 미달
→ 수정: @available 조건 추가 또는 iOS Deployment Target 수정
  if #available(iOS 16.0, *) {
      // use new API
  } else {
      // fallback
  }

Return from initializer without initializing all stored properties
→ 원인: init에서 모든 프로퍼티 초기화 안 됨
→ 수정: 모든 stored property에 초기값 할당 또는 기본값 설정
  var name: String = ""  // 기본값 제공
  또는 init에서 반드시 모든 프로퍼티 할당

Escaping closure captures mutating 'self' parameter
→ 원인: struct의 mutating 메서드에서 escaping closure가 self 캡처
→ 수정: class로 변경하거나 inout 패턴 사용
  또는 로컬 복사: var localSelf = self; closure { localSelf.modify() }

Cannot assign to property: '[X]' is a 'let' constant
→ 원인: 불변 값 변경 시도
→ 수정: let → var 변경, 또는 struct의 경우 mutating func 사용

Protocol '[P]' can only be used as a generic constraint because it has Self or associated type requirements
→ 원인: associated type이 있는 프로토콜을 직접 타입으로 사용
→ 수정: any 키워드 (Swift 5.7+) 또는 제네릭 constraint 사용
  func process(item: any Equatable)          // existential (Swift 5.7+)
  func process<T: Equatable>(item: T)         // generic constraint
  func process(item: some Equatable)          // opaque parameter (Swift 5.7+)

Type '[X]' does not conform to protocol 'Sendable'
→ 원인: 동시성 안전성 미충족 (Swift Concurrency)
→ 수정: @Sendable 어노테이션 또는 Sendable 프로토콜 구현
  struct MyData: Sendable { ... }           // 값 타입은 자동 가능
  final class MyClass: Sendable { ... }     // class는 final + 불변 프로퍼티 필요
  @unchecked Sendable → 최후의 수단 (개발자가 안전성 보장)

Actor-isolated property '[prop]' can not be referenced from a non-isolated context
→ 원인: actor 외부에서 actor의 격리된 프로퍼티 접근
→ 수정: await 사용 또는 nonisolated 선언
  let value = await myActor.prop
  // 또는 메서드를 nonisolated로 선언 (불변 데이터만)
```

### 타입 시스템 심화

```
제네릭 에러:
  Generic parameter '[T]' could not be inferred
  → 원인: 타입 추론 실패
  → 수정: 명시적 타입 지정
    let result: [String] = decode(data)
    또는: let result = decode(data) as [String]

  Conflicting arguments to generic parameter '[T]'
  → 원인: 제네릭 T에 2개 이상 타입이 매칭
  → 수정: 인자 타입 통일 또는 overload 분리

Opaque return type 에러:
  Function declares an opaque return type, but the return statements in its body do not have matching underlying types
  → 원인: some View 반환에서 분기별 다른 타입 반환
  → 수정: @ViewBuilder 사용 또는 AnyView로 감싸기 (성능 주의)
    @ViewBuilder
    var body: some View {
        if condition { Text("A") }
        else { Image("B") }
    }

Result Builder 에러:
  Type '[X]' cannot be used as a result builder
  → 원인: @resultBuilder 어노테이션 또는 필수 메서드 누락
  → 수정: buildBlock, buildOptional 등 필수 메서드 구현

KeyPath 에러:
  Key path value type '[A]' cannot be converted to contextual type '[B]'
  → 원인: KeyPath 타입 불일치
  → 수정: 올바른 root/value 타입으로 KeyPath 지정
    \MyType.propertyName  → KeyPath<MyType, PropertyType>

Codable 에러:
  Type '[X]' does not conform to protocol 'Decodable'
  → 원인: 모든 프로퍼티가 Codable이 아니거나 커스텀 init(from:) 필요
  → 수정: 모든 프로퍼티 Codable 준수 확인
    enum CodingKeys: String, CodingKey { ... }  // 커스텀 키 매핑
    Date 필드: JSONDecoder에 dateDecodingStrategy 설정
```

### 패키지 관리자 문제 (SPM / CocoaPods / Xcode)

```
Swift Package Manager (SPM):
  Package resolution failed: [pkg] not found
  → 원인: 패키지 URL 오류 또는 네트워크 문제
  → 수정:
    swift package resolve                     # 의존성 재해결
    swift package reset                       # 캐시 초기화
    Package.swift의 URL 및 version/branch 확인

  Package '[pkg]' is using Swift tools version [X] which is newer than the current [Y]
  → 원인: 로컬 Swift 버전이 패키지 요구사항보다 낮음
  → 수정: Swift 업데이트 (Xcode 업데이트)
    swift --version으로 현재 버전 확인

  Dependency resolution failed: version solving failed
  → 원인: 패키지 간 버전 호환성 문제
  → 수정:
    버전 범위 완화: .upToNextMajor(from: "1.0.0")
    또는 특정 branch/commit 지정: .branch("main")
    Package.resolved 삭제 후 재해결: rm Package.resolved && swift package resolve

  Multiple targets named '[name]'
  → 원인: 서로 다른 패키지가 동일 타겟명 정의
  → 수정: 패키지 하나를 제거하거나 fork에서 타겟명 변경

  Binary dependency '[pkg]' is not available for the current platform
  → 원인: xcframework가 현재 아키텍처 미지원
  → 수정: 패키지 관리자에서 해당 플랫폼용 바이너리 확인
    arm64-apple-ios vs x86_64-apple-ios-simulator

CocoaPods:
  [!] Unable to find a specification for [Pod]
  → 원인: Pod 이름 오류 또는 repo 미업데이트
  → 수정: pod repo update && pod install

  [!] CocoaPods could not find compatible versions for pod "[Pod]"
  → 원인: 버전 충돌
  → 수정:
    Podfile에서 버전 범위 조정: pod 'Library', '~> 2.0'
    pod update [Library]                      # 특정 Pod만 업데이트
    pod deintegrate && pod install            # 클린 재설치

  [!] The sandbox is not in sync with the Podfile.lock
  → 원인: pod install 미실행
  → 수정: pod install (Podfile 변경 후 반드시 실행)

  CDN: trunk URL couldn't be downloaded
  → 원인: CocoaPods CDN 문제 또는 네트워크
  → 수정: Podfile 상단에 source 변경
    source 'https://cdn.cocoapods.org/'
    또는: source 'https://github.com/CocoaPods/Specs.git'

Xcode:
  No such module '[ModuleName]'
  → 원인: 프레임워크 미링크 또는 빌드 순서 문제
  → 수정:
    Product → Clean Build Folder (Shift+Cmd+K)
    DerivedData 삭제: rm -rf ~/Library/Developer/Xcode/DerivedData
    Embed & Sign 설정 확인 (Frameworks 탭)

  Signing for "[Target]" requires a development team
  → 원인: 코드 사이닝 설정 누락
  → 수정: Signing & Capabilities에서 Team 설정
    CI/CD: CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO (시뮬레이터 빌드)

  Build input file cannot be found: '[path]'
  → 원인: 파일이 프로젝트에 등록되었으나 디스크에 없음
  → 수정: 프로젝트에서 해당 파일 참조 제거 후 필요 시 재추가
```

### 의존성 해결 전략

```
1. SPM 우선 사용 (Apple 공식 권장)
   Package.swift에서 중앙 관리:
   dependencies: [
       .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
       .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.0.0")),
   ]

2. 버전 전략
   .exact("1.2.3")                    → 정확한 버전 (최소 유연성)
   .upToNextMinor(from: "1.2.0")      → 1.2.x 범위
   .upToNextMajor(from: "1.0.0")      → 1.x.x 범위 (권장)
   .branch("main")                    → 최신 개발 브랜치 (불안정)
   .revision("abc123...")             → 특정 커밋

3. Package.resolved 관리
   소스 제어에 포함 → 팀 전체 동일 버전 보장
   CI에서: swift package resolve --skip-update (lock 파일 기준으로 설치)

4. 로컬 패키지 개발
   .package(path: "../MyLocalPackage")  → 로컬 경로 참조
   개발 완료 후 → URL 기반 의존성으로 전환

5. SPM + CocoaPods 공존
   가능하면 SPM으로 통일 (CocoaPods deprecation 추세)
   공존 시: Pods 디렉토리와 SPM 패키지가 동일 라이브러리 제공하지 않도록 주의
```

### 환경별 주의사항 (Environment Gotchas)

```
Xcode 버전:
  - Swift 버전은 Xcode 버전에 종속:
    Xcode 15 → Swift 5.9
    Xcode 15.3 → Swift 5.10 (strict concurrency 경고)
    Xcode 16 → Swift 6.0 (strict concurrency 기본 활성화)
  - 여러 Xcode 버전 공존: xcode-select -s /Applications/Xcode-15.app
  - toolchain 명시: xcrun --toolchain swift

Swift Concurrency (async/await):
  - iOS 13+에서 사용 가능 (back-deploy)
  - Swift 6에서 data race safety 기본 활성화 → 대량의 경고/에러 발생 가능
  - 마이그레이션: SWIFT_STRICT_CONCURRENCY=complete (점진적 적용)
  - MainActor isolation: @MainActor 어노테이션으로 UI 스레드 보장
  - Task { @MainActor in ... } → UI 업데이트

SwiftUI:
  - iOS 버전별 API 차이 큼:
    iOS 14: @StateObject, LazyVStack
    iOS 15: .task, .searchable, AsyncImage
    iOS 16: NavigationStack, .navigationDestination
    iOS 17: @Observable macro, #Preview macro
  - @available로 분기 처리 필수

macOS / Linux:
  - macOS: Foundation 전체 사용 가능
  - Linux: swift-corelibs-foundation (일부 API 미지원 또는 동작 차이)
    URLSession, JSONDecoder 등은 지원
    NSAttributedString, NSPredicate 등 미지원
  - Docker에서 Swift:
    FROM swift:5.9-slim
    swift build -c release

iOS 시뮬레이터 vs 실기기:
  - 시뮬레이터: x86_64 (Intel Mac) / arm64 (Apple Silicon)
  - 실기기: arm64 전용
  - XCFramework: 여러 아키텍처 통합 배포
  - 시뮬레이터에서 하드웨어 API (카메라, NFC 등) 미지원 → #if targetEnvironment(simulator) 분기

CI/CD (GitHub Actions / Xcode Cloud):
  - fastlane: 빌드/테스트/배포 자동화
  - xcodebuild: -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
  - 코드 사이닝: match (fastlane) 또는 Xcode Cloud 자동 관리
  - SPM 캐시: ~/.swiftpm/cache 경로 캐시
```

### 자동 수정 명령

```bash
swift build                              # SPM 빌드
swift build -c release                   # 릴리즈 빌드
swift package resolve                    # 의존성 해결
swift package update                     # 의존성 업데이트
swift package reset                      # 패키지 캐시 초기화
swift test                               # 테스트 실행
xcodebuild -scheme App -quiet            # Xcode 빌드 (Xcode 프로젝트)
xcodebuild clean -scheme App             # Xcode 클린
pod install --repo-update                # CocoaPods 설치 + repo 업데이트
pod deintegrate && pod install           # CocoaPods 클린 재설치
swiftlint --fix                          # SwiftLint 자동 수정
swift-format format -r -i Sources/       # swift-format 포맷 수정
rm -rf ~/Library/Developer/Xcode/DerivedData  # DerivedData 전체 삭제
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
