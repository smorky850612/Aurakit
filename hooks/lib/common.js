/**
 * AuraKit Hook Commons — 크로스 플랫폼 Node.js 훅 유틸리티
 * Windows (cmd/PowerShell) + Unix (bash/zsh) 모두 지원
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ── stdin 읽기 (동기, 크로스 플랫폼) ─────────────────────────────────
function readInput() {
  try {
    const raw = fs.readFileSync('/dev/stdin', 'utf8');
    return JSON.parse(raw) || {};
  } catch {
    try {
      // Windows fallback
      const raw = fs.readFileSync(0, 'utf8'); // fd 0 = stdin
      return JSON.parse(raw) || {};
    } catch {
      return {};
    }
  }
}

// ── 출력 헬퍼 ─────────────────────────────────────────────────────────

/** 허용 (아무것도 출력 안 함) */
function allow() {
  process.exit(0);
}

/** 차단 — stderr에 메시지 출력 후 exit 2 */
function block(reason) {
  process.stderr.write(reason + '\n');
  process.exit(2);
}

/** UserPromptSubmit/Stop용 컨텍스트 주입 */
function addContext(content) {
  process.stdout.write(JSON.stringify({ continue: true, additionalContext: content }));
  process.exit(0);
}

/** Stop 훅용 (systemPrompt 주입) */
function addSystemPrompt(content) {
  process.stdout.write(JSON.stringify({ continue: true, systemPrompt: content }));
  process.exit(0);
}

// ── 파일 시스템 헬퍼 ──────────────────────────────────────────────────

function fileExists(p) {
  try { fs.accessSync(p); return true; } catch { return false; }
}

function dirExists(p) {
  try { return fs.statSync(p).isDirectory(); } catch { return false; }
}

function mkdirSafe(p) {
  try { fs.mkdirSync(p, { recursive: true }); } catch {}
}

function readFileSafe(p, def = '') {
  try { return fs.readFileSync(p, 'utf8'); } catch { return def; }
}

function writeFileSafe(p, content) {
  try {
    mkdirSafe(path.dirname(p));
    fs.writeFileSync(p, content, 'utf8');
    return true;
  } catch { return false; }
}

// ── 홈 디렉토리 경로 ──────────────────────────────────────────────────

const HOME = process.env.HOME || process.env.USERPROFILE || '';
const HOOKS_DIR = path.join(HOME, '.claude', 'skills', 'aurakit', 'hooks');
const AURA_DIR = path.join(process.cwd(), '.aura');
const SNAPSHOTS_DIR = path.join(AURA_DIR, 'snapshots');

// ── 보안 패턴 (15개) ─────────────────────────────────────────────────

const SECRET_PATTERNS = [
  /[A-Z_]{3,}_KEY\s*=\s*\S{8,}/,
  /[A-Z_]{3,}_SECRET\s*=\s*\S{8,}/,
  /[A-Z_]{3,}_TOKEN\s*=\s*\S{8,}/,
  /[A-Z_]{3,}_PASSWORD\s*=\s*\S{8,}/,
  /[A-Z_]{3,}_DSN\s*=\s*postgres:\/\//,
  /sk-[a-zA-Z0-9]{20,}/,
  /ghp_[a-zA-Z0-9]{36}/,
  /github_pat_[a-zA-Z0-9_]{82}/,
  /xoxb-[0-9]+-[a-zA-Z0-9]+/,        // Slack Bot Token
  /AKIA[0-9A-Z]{16}/,                  // AWS Access Key
  /(?:key|secret|token|password)\s*[:=]\s*['"]?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i,  // UUID-format secret (context-bound)
  /AIza[0-9A-Za-z-_]{35}/,            // Google API Key
  /eyJ[a-zA-Z0-9+/\-_]+=*\.[a-zA-Z0-9+/\-_]+=*\.[a-zA-Z0-9+/\-_]+=*/,  // JWT (base64url)
  /-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/,
  /SG\.[a-zA-Z0-9]{22}\.[a-zA-Z0-9]{43}/, // SendGrid
];

const ENV_FILE_PATTERN = /^\.env$|\/\.env$|\.env\.local$|\.env\.production$|\.env\.staging$/;

module.exports = {
  readInput,
  allow,
  block,
  addContext,
  addSystemPrompt,
  fileExists,
  dirExists,
  mkdirSafe,
  readFileSafe,
  writeFileSafe,
  HOME,
  HOOKS_DIR,
  AURA_DIR,
  SNAPSHOTS_DIR,
  SECRET_PATTERNS,
  ENV_FILE_PATTERN,
};
