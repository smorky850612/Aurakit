# AuraKit — Swift Build Resolver

> FIX 모드 V1 빌드 실패 시 Swift 프로젝트에서 자동 트리거.

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
