# AuraKit — Desktop Pipeline (Electron / Tauri)

> `/aura desktop:` 호출 시 로딩. Electron + Tauri 전문 가이드.

---

## 프레임워크 선택

| 기준 | Electron | Tauri |
|------|----------|-------|
| 언어 | Node.js + HTML/CSS/JS | Rust + HTML/CSS/JS |
| 번들 크기 | ~100MB (Chromium 포함) | ~5MB (시스템 WebView) |
| 메모리 | 높음 (V8 + Chromium) | 낮음 (Rust 런타임) |
| 생태계 | 넓음 (npm 전체 사용) | 제한적 (Rust crate) |
| 보안 | 추가 설정 필요 | 기본 샌드박스 강화 |
| 성숙도 | 높음 (VS Code, Slack 등) | 성장 중 |

---

## Electron 프로젝트 구조

```
src/
  main/           # 메인 프로세스 (Node.js)
    index.ts      # 앱 진입점
    ipc.ts        # IPC 핸들러
    preload.ts    # 컨텍스트 브릿지
  renderer/       # 렌더러 프로세스 (React/Vue 등)
    App.tsx
    pages/
electron-builder.json  # 빌드 설정
```

### 핵심 패턴 (Electron)

```typescript
// main/index.ts — BrowserWindow 생성
const win = new BrowserWindow({
  width: 1200, height: 800,
  webPreferences: {
    preload: path.join(__dirname, 'preload.js'),
    contextIsolation: true,   // ✅ 필수
    nodeIntegration: false,   // ✅ 필수 (보안)
    sandbox: true,            // ✅ 권장
  },
});

// preload.ts — 안전한 IPC 브릿지
contextBridge.exposeInMainWorld('api', {
  readFile: (path: string) => ipcRenderer.invoke('read-file', path),
  saveFile: (path: string, content: string) => ipcRenderer.invoke('save-file', path, content),
});

// main/ipc.ts — IPC 핸들러
ipcMain.handle('read-file', async (_, filePath: string) => {
  // 경로 검증 (path traversal 방지)
  const resolved = path.resolve(filePath);
  if (!resolved.startsWith(app.getPath('userData'))) throw new Error('접근 불가 경로');
  return fs.readFileSync(resolved, 'utf8');
});
```

---

## Tauri 프로젝트 구조

```
src/             # 프론트엔드 (React/Vue/Svelte)
src-tauri/       # Rust 백엔드
  src/
    main.rs      # 진입점
    commands.rs  # Tauri 커맨드
  tauri.conf.json
```

### 핵심 패턴 (Tauri)

```rust
// src-tauri/src/commands.rs
#[tauri::command]
async fn read_file(path: String) -> Result<String, String> {
    std::fs::read_to_string(&path).map_err(|e| e.to_string())
}

// main.rs
tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![read_file])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
```

```typescript
// 프론트엔드에서 호출
import { invoke } from '@tauri-apps/api/tauri';
const content = await invoke<string>('read_file', { path: '/path/to/file' });
```

---

## 보안 규칙 (데스크톱 특화)

| 규칙 | 이유 |
|------|------|
| `contextIsolation: true` | 렌더러-메인 격리 |
| `nodeIntegration: false` | 렌더러에서 Node.js 직접 접근 차단 |
| IPC 경로 검증 필수 | Path traversal 공격 방지 |
| CSP 헤더 설정 | XSS 방지 |
| 자동 업데이트 서명 | 코드 무결성 보장 |

---

## 빌드 및 배포

```bash
# Electron
npx electron-builder --mac --win --linux
# 출력: dist/mac/*.dmg, dist/win/*.exe, dist/linux/*.AppImage

# Tauri
npm run tauri build
# 출력: src-tauri/target/release/bundle/
```

---

## 검증 (V1-V3)

```bash
# V1: 타입 + 린트
npx tsc --noEmit
npx eslint src/ --ext .ts,.tsx

# V2: 보안 감사
npx electronegativity -i . 2>/dev/null || true  # Electron 보안 감사
cargo audit 2>/dev/null || true                  # Tauri Rust 의존성 감사

# V3: 실행 테스트
npm run dev  # 개발 모드 실행 확인
```
