#!/usr/bin/env node
/**
 * AuraKit — PreToolUse Bash Guard (Node.js 크로스 플랫폼 버전)
 * 위험한 Bash 명령 감지. matcher: Bash
 */

'use strict';

const { readInput, allow, block } = require('./lib/common.js');

const input = readInput();
const cmd = (input.tool_input || {}).command || '';

if (!cmd) allow();

// ── 파괴적 명령 패턴 ─────────────────────────────────────────────────
const DANGEROUS = [
  { re: /rm\s+-rf?\s+\/(?:\s|$)/, desc: 'rm -rf /' },
  { re: /git\s+push\s+.*--force\s+(?:origin\s+)?main/, desc: 'force push to main' },
  { re: /git\s+reset\s+--hard\s+HEAD~[2-9]/, desc: 'git reset --hard HEAD~N (N≥2)' },
  { re: /DROP\s+DATABASE/i, desc: 'DROP DATABASE' },
  { re: /chmod\s+-R\s+777/, desc: 'chmod -R 777' },
  { re: />\s*\/etc\/(passwd|shadow|sudoers)/, desc: '/etc/passwd|shadow 쓰기' },
  { re: /curl.*\|\s*(?:bash|sh)/, desc: 'curl | bash (원격 실행)' },
  { re: /wget.*\|\s*(?:bash|sh)/, desc: 'wget | bash (원격 실행)' },
];

const found = DANGEROUS.filter(p => p.re.test(cmd));

if (found.length > 0) {
  block(
    '🔴 AuraKit Bash Guard 차단\n' +
    '   위험한 명령이 감지되었습니다:\n' +
    found.map(f => '   - ' + f.desc).join('\n') + '\n' +
    '   의도한 명령이라면 직접 터미널에서 실행하세요.'
  );
}

allow();
