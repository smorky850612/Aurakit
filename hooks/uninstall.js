#!/usr/bin/env node
/**
 * AuraKit — Uninstall Hook
 * settings.json에서 AuraKit 훅 설정 제거
 *
 * 실행: node hooks/uninstall.js
 * 또는: /aura uninstall (SKILL.md O 섹션)
 */

const fs = require('fs')
const path = require('path')
const os = require('os')

const SETTINGS_PATH = path.join(os.homedir(), '.claude', 'settings.json')

// AuraKit 훅 핸들러 목록 (확장자 제외 기본 이름)
// install.sh는 일부를 .sh로, 일부를 .js로 등록함 — 확장자 무관 매칭 사용
const AURAKIT_HANDLER_BASES = [
  'pre-session',
  'korean-command',
  'security-scan',
  'build-verify',
  'bloat-check',
  'instinct-auto-save',
  'auto-format',
  'governance-capture',
  'post-tool-failure',
  'session-stop',
  'pre-compact-snapshot',
  'post-compact-restore',
  'bash-guard',
  'subagent-start',
  'subagent-stop',
  'teammate-idle',
]

function isAurakitHook(command) {
  if (!command) return false
  // 파일명에서 확장자 제거 후 비교 (pre-session.sh / pre-session.js 모두 매칭)
  const basename = path.basename(command).replace(/\.(js|sh|py|ts)$/, '')
  return AURAKIT_HANDLER_BASES.includes(basename)
}

function removeAurakitHooks(settings) {
  if (!settings.hooks) return { settings, removed: 0 }

  let removed = 0

  for (const [event, hookList] of Object.entries(settings.hooks)) {
    if (!Array.isArray(hookList)) continue

    const filtered = hookList.map(hookGroup => {
      if (!hookGroup.hooks) return hookGroup
      const before = hookGroup.hooks.length
      hookGroup.hooks = hookGroup.hooks.filter(h => !isAurakitHook(h.command || h))
      removed += before - hookGroup.hooks.length
      return hookGroup
    }).filter(hookGroup => {
      // 훅 목록이 비어버린 그룹 제거
      if (hookGroup.hooks && hookGroup.hooks.length === 0) return false
      return true
    })

    settings.hooks[event] = filtered
    if (settings.hooks[event].length === 0) {
      delete settings.hooks[event]
    }
  }

  if (Object.keys(settings.hooks).length === 0) {
    delete settings.hooks
  }

  return { settings, removed }
}

function main() {
  if (!fs.existsSync(SETTINGS_PATH)) {
    console.log('⚠️  settings.json 없음 — 언인스톨 불필요')
    process.exit(0)
  }

  let settings
  try {
    settings = JSON.parse(fs.readFileSync(SETTINGS_PATH, 'utf8'))
  } catch (e) {
    console.error('❌ settings.json 파싱 실패:', e.message)
    process.exit(1)
  }

  // 백업
  const backupPath = SETTINGS_PATH + '.aurakit-backup'
  fs.writeFileSync(backupPath, JSON.stringify(settings, null, 2), 'utf8')
  console.log(`📦 백업 저장: ${backupPath}`)

  const { settings: cleaned, removed } = removeAurakitHooks(settings)

  fs.writeFileSync(SETTINGS_PATH, JSON.stringify(cleaned, null, 2), 'utf8')

  if (removed === 0) {
    console.log('ℹ️  AuraKit 훅이 settings.json에 없습니다 (이미 제거됨)')
  } else {
    console.log(`✅ AuraKit 언인스톨 완료 — ${removed}개 훅 제거`)
    console.log('   settings.json 복원됨')
    console.log(`   백업: ${backupPath}`)
  }
}

main()
