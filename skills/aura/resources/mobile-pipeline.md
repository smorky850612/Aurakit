# AuraKit — Mobile Pipeline (React Native / Expo)

> `/aura mobile:` 호출 시 로딩. React Native + Expo 전문 가이드.

---

## 프레임워크 감지

```bash
# Expo 프로젝트
cat package.json | grep -E '"expo"'
cat app.json 2>/dev/null | head -5

# React Native (without Expo)
cat package.json | grep "react-native"

# Expo Router (파일 기반 라우팅)
ls app/ 2>/dev/null | head -5
```

---

## 프로젝트 구조

```
app/                    # Expo Router (권장)
  _layout.tsx           # 루트 레이아웃
  (tabs)/               # 탭 네비게이션
    index.tsx
    profile.tsx
  [id].tsx              # 동적 라우트

components/
  ui/                   # 재사용 UI 컴포넌트
  features/             # 기능별 컴포넌트

hooks/                  # 커스텀 훅
constants/              # 색상, 폰트, 레이아웃
```

---

## 핵심 패턴

### 1. 크로스 플랫폼 스타일

```typescript
import { StyleSheet, Platform } from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: Platform.OS === 'ios' ? 44 : 24,
  },
  shadow: {
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.1 },
      android: { elevation: 4 },
    }),
  },
});
```

### 2. 안전 영역 처리

```typescript
import { SafeAreaView } from 'react-native-safe-area-context';

export default function Screen() {
  return (
    <SafeAreaView style={{ flex: 1 }} edges={['top', 'bottom']}>
      {/* 콘텐츠 */}
    </SafeAreaView>
  );
}
```

### 3. 네이티브 모듈 (Expo)

```typescript
import * as Camera from 'expo-camera';
import * as FileSystem from 'expo-file-system';
import * as SecureStore from 'expo-secure-store';

// 권한 요청 패턴
const [permission, requestPermission] = Camera.useCameraPermissions();
if (!permission?.granted) {
  await requestPermission();
}
```

### 4. 상태 관리

```typescript
// Zustand (권장 — 경량, React Native 최적화)
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

const useStore = create(
  persist(
    (set) => ({ count: 0, increment: () => set((s) => ({ count: s.count + 1 })) }),
    { name: 'app-storage', storage: createJSONStorage(() => AsyncStorage) }
  )
);
```

---

## 성능 최적화

| 항목 | 방법 |
|------|------|
| 리스트 렌더링 | `FlatList` + `keyExtractor` + `getItemLayout` |
| 이미지 | `expo-image` (캐시 + 블러해시 지원) |
| 애니메이션 | `react-native-reanimated` (JS 스레드 분리) |
| 번들 크기 | Hermes 엔진 + `metro.config.js` 최적화 |

---

## 빌드 및 배포

```bash
# 개발 빌드
npx expo start

# EAS Build (클라우드)
npx eas build --platform ios --profile preview
npx eas build --platform android --profile preview

# OTA 업데이트 (JS만 변경 시)
npx eas update --branch main --message "Fix login flow"
```

---

## 보안 규칙 (모바일 특화)

- ✅ 민감 데이터: `expo-secure-store` (iOS Keychain / Android Keystore)
- ✅ 네트워크: HTTPS + Certificate Pinning (`expo-ssl-pinning`)
- ❌ AsyncStorage에 토큰/비밀번호 저장 금지
- ❌ `__DEV__` 플래그로만 보호하는 로직 금지

---

## 검증 (V1-V3)

```bash
# V1: 타입 체크 + 린트
npx tsc --noEmit
npx eslint . --ext .ts,.tsx

# V2: Expo Doctor
npx expo-doctor

# V3: 디바이스 테스트
npx expo start --ios    # iOS Simulator
npx expo start --android # Android Emulator
```
