# AuraKit — C++ Build Resolver

> FIX 모드 V1 빌드 실패 시 C++ 프로젝트에서 자동 트리거.

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
