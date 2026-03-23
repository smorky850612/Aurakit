#!/usr/bin/env node
/**
 * AuraKit — PostToolUse Injection Guard (Node.js 크로스 플랫폼 버전)
 * WebFetch 결과에서 프롬프트 인젝션 패턴 감지. matcher: WebFetch
 */

'use strict';

const { readInput, allow } = require('./lib/common.js');

const input = readInput();
const response = JSON.stringify(input.tool_response || '');

// ── 인젝션 패턴 감지 ─────────────────────────────────────────────────
const INJECTION_PATTERNS = [
  /ignore (?:previous|all prior) instructions/i,
  /disregard your system prompt/i,
  /you are now (?:a|an|the) (?!logged|connected|signed|authenticated)/i,
  /act as (?:a|an) (?:different|new|unrestricted|jailbroken)/i,
  /jailbreak/i,
  /new (?:system )?persona/i,
  /forget (?:your|all) instructions/i,
  /ignore (?:your|the) (?:system|previous|above) (?:prompt|instructions|message)/i,
];

const found = INJECTION_PATTERNS.filter(p => p.test(response));

if (found.length > 0) {
  // 경고만 (차단 아님 — 사용자가 판단)
  process.stderr.write(
    '⚠️  AuraKit Injection Guard: WebFetch 결과에 의심스러운 패턴이 감지되었습니다.\n' +
    '   패턴 수: ' + found.length + '개\n' +
    '   주의해서 결과를 검토하세요.\n'
  );
}

allow();
