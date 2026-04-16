#!/usr/bin/env node
'use strict';

/**
 * AuraKit — settings.json Repair Script
 *
 * 용도: Claude Code hooks 스키마가 깨진 settings.json을 자동 수리
 * 실행: npx @smorky85/aurakit-repair
 *       node ~/.claude/skills/aurakit/hooks/repair.js
 *
 * 문제: v6.5.2 이하 설치기가 hooks를 잘못된 형식으로 생성
 *   잘못됨: [{"type":"command","command":"..."}]
 *   올바름: [{"matcher":"","hooks":[{"type":"command","command":"..."}]}]
 */

const fs = require('fs');
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE;
const SETTINGS_PATH = path.join(HOME, '.claude', 'settings.json');

const log = (m) => console.log(`  \x1b[36m[AuraKit Repair]\x1b[0m ${m}`);
const ok = (m) => console.log(`  \x1b[32m✓\x1b[0m ${m}`);
const warn = (m) => console.log(`  \x1b[33m!\x1b[0m ${m}`);

/**
 * hook 배열의 각 엔트리가 올바른 {matcher, hooks} 형식인지 검사.
 * 잘못된 {type, command} 형식이면 래핑하여 수리.
 * @returns {repaired: boolean, count: number}
 */
function repairHooks(settings) {
  if (!settings.hooks || typeof settings.hooks !== 'object') {
    return { repaired: false, count: 0 };
  }

  let totalRepaired = 0;

  for (const [event, hookList] of Object.entries(settings.hooks)) {
    if (!Array.isArray(hookList)) continue;

    // 엔트리가 {type, command} 형식이면 래핑 필요
    const needsRepair = hookList.some(
      (entry) => entry.type === 'command' && entry.command && !entry.hooks
    );

    if (needsRepair) {
      // 모든 flat command 엔트리를 하나의 matcher 그룹으로 래핑
      const commands = hookList.filter((e) => e.type === 'command' && e.command);
      const others = hookList.filter((e) => !(e.type === 'command' && e.command && !e.hooks));

      settings.hooks[event] = [
        ...others,
        { matcher: '', hooks: commands },
      ];
      totalRepaired += commands.length;
    }
  }

  return { repaired: totalRepaired > 0, count: totalRepaired };
}

function main() {
  console.log('');
  log('Checking ~/.claude/settings.json hooks format...');
  console.log('');

  if (!fs.existsSync(SETTINGS_PATH)) {
    warn('settings.json not found — nothing to repair');
    process.exit(0);
  }

  let settings;
  try {
    settings = JSON.parse(fs.readFileSync(SETTINGS_PATH, 'utf8'));
  } catch (e) {
    warn('settings.json parse failed: ' + e.message);
    process.exit(1);
  }

  const { repaired, count } = repairHooks(settings);

  if (!repaired) {
    ok('settings.json hooks format is already correct — no repair needed');
    process.exit(0);
  }

  // 백업 후 저장
  const backupPath = SETTINGS_PATH + '.pre-repair-backup';
  fs.writeFileSync(backupPath, fs.readFileSync(SETTINGS_PATH, 'utf8'));
  ok(`Backup saved: ${backupPath}`);

  fs.writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2), 'utf8');
  ok(`Repaired ${count} hook entries → correct {matcher, hooks} format`);
  console.log('');
  log('Restart Claude Code to apply the fix.');
  console.log('');
}

// 라이브러리로도 사용 가능 (install.js에서 호출)
module.exports = { repairHooks };

if (require.main === module) {
  // --silent: pre-session.sh에서 호출 시 출력 없이 수리만 수행
  if (process.argv.includes('--silent')) {
    try {
      const settings = JSON.parse(fs.readFileSync(SETTINGS_PATH, 'utf8'));
      const { repaired } = repairHooks(settings);
      if (repaired) {
        fs.writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2), 'utf8');
      }
    } catch (e) { /* silent */ }
  } else {
    main();
  }
}
