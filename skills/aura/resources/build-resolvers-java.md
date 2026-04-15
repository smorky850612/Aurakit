# AuraKit — Java / Spring Boot Build Resolver

> FIX 모드 V1 빌드 실패 시 Java/Spring 프로젝트에서 자동 트리거.

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
