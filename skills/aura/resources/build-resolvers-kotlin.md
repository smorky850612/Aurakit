# AuraKit — Kotlin Build Resolver

> FIX 모드 V1 빌드 실패 시 Kotlin 프로젝트에서 자동 트리거.

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
