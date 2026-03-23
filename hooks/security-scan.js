#!/usr/bin/env node
/**
 * AuraKit — PreToolUse Security Scan (Node.js 크로스 플랫폼 버전)
 * 시크릿 패턴 감지 (보안 L4). matcher: Write|Edit
 */

'use strict';

const path = require('path');
const fs = require('fs');
const {
  readInput, allow, block,
  fileExists, readFileSafe, writeFileSafe, mkdirSafe,
  AURA_DIR, SECRET_PATTERNS, ENV_FILE_PATTERN
} = require('./lib/common.js');

const input = readInput();
const toolInput = input.tool_input || {};

const content = toolInput.content || toolInput.new_string || '';
const filePath = toolInput.file_path || '';

if (!content) allow();

// ── .env 파일 쓰기 보안 검사 ──────────────────────────────────────────
if (ENV_FILE_PATTERN.test(filePath)) {
  if (/^[A-Z_]+=.{8,}/m.test(content)) {
    if (fileExists('.gitignore')) {
      const gi = readFileSafe('.gitignore');
      if (!/^\.env$|^\.env\b/m.test(gi)) {
        block('⚠️  AuraKit Security L4: .env 파일이 .gitignore에 없습니다.\n   .gitignore에 먼저 .env를 추가하세요.');
      }
    }
  }
}

// ── 시크릿 패턴 감지 ─────────────────────────────────────────────────
const foundSecrets = [];
for (const pattern of SECRET_PATTERNS) {
  if (pattern.test(content)) {
    const match = content.match(pattern);
    if (match) foundSecrets.push(match[0].substring(0, 20) + '...');
  }
}

if (foundSecrets.length > 0) {
  // 감사 로그 기록
  const auditLog = path.join(AURA_DIR, 'security-audit.log');
  const entry = `[${new Date().toISOString()}] BLOCKED: Secret pattern in ${filePath || 'unknown'}\n`;
  try {
    mkdirSafe(AURA_DIR);
    fs.appendFileSync(auditLog, entry, 'utf8');
  } catch {}

  block(
    '🔴 AuraKit Security L4 차단\n' +
    `   파일: ${filePath}\n` +
    `   감지된 패턴 (${foundSecrets.length}개):\n` +
    foundSecrets.map(s => `   - ${s}`).join('\n') + '\n' +
    '   ENV 변수로 이동 후 .env 파일에 저장하세요.'
  );
}

// ── localStorage 토큰 저장 감지 ───────────────────────────────────────
if (/localStorage\.setItem\s*\(\s*['"`][^'"]*['"`]\s*,\s*.*(?:[Tt]oken|[Jj][Ww][Tt])/.test(content)) {
  block(
    '🔴 AuraKit Security L4 차단\n' +
    `   파일: ${filePath}\n` +
    '   localStorage에 JWT/Token 저장은 금지됩니다.\n' +
    '   httpOnly Cookie를 사용하세요.'
  );
}

// ── SQL Injection 패턴 (raw string concatenation) ────────────────────
const sqlRaw = /`(?:SELECT|INSERT|UPDATE|DELETE)[^`]*\$\{[^}]+\}[^`]*`/i;
if (sqlRaw.test(content)) {
  process.stderr.write(
    '⚠️  AuraKit Security L3 경고\n' +
    `   파일: ${filePath}\n` +
    '   SQL 문자열 연결 감지. Parameterized query 사용을 권장합니다.\n'
  );
  // 경고만 (차단 아님)
}

allow();
