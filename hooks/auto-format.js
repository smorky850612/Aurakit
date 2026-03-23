#!/usr/bin/env node
/**
 * AuraKit — PostToolUse Auto Formatter
 * Write/Edit 완료 후 자동 코드 포맷
 * Prettier(JS/TS/CSS/JSON/MD) · gofmt(Go) · black(Python) · rustfmt(Rust)
 * Hook: PostToolUse (matcher: Write|Edit)
 */
'use strict';

const { readInput, fileExists } = require('./lib/common.js');
const { execSync } = require('child_process');
const path = require('path');

const input = readInput();
const toolName = input.tool_name || '';
const toolInput = input.tool_input || {};

// Write/Edit 툴만 처리
if (!['Write', 'Edit'].includes(toolName)) process.exit(0);

const filePath = toolInput.file_path || '';
if (!filePath) process.exit(0);

const ext = path.extname(filePath).toLowerCase();

// ── 도구 실행 헬퍼 ────────────────────────────────────────────────────
function tryExec(cmd) {
  try {
    execSync(cmd, { timeout: 15000, stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

// ── Prettier 적용 대상 확장자 ─────────────────────────────────────────
const PRETTIER_EXTS = new Set(['.js', '.jsx', '.ts', '.tsx', '.css', '.scss', '.json', '.md', '.yaml', '.yml', '.html']);

if (PRETTIER_EXTS.has(ext)) {
  // Prettier 설정 파일 존재 확인 (프로젝트에 설정 없으면 포맷하지 않음)
  const hasPrettier =
    fileExists('.prettierrc') ||
    fileExists('.prettierrc.json') ||
    fileExists('.prettierrc.js') ||
    fileExists('.prettierrc.cjs') ||
    fileExists('.prettierrc.yaml') ||
    fileExists('.prettierrc.yml') ||
    fileExists('prettier.config.js') ||
    fileExists('prettier.config.cjs');

  if (hasPrettier) {
    // 로컬 설치 우선, 없으면 npx
    const localPrettier = path.join('node_modules', '.bin', 'prettier');
    if (fileExists(localPrettier)) {
      tryExec(`"${localPrettier}" --write "${filePath}" 2>/dev/null`);
    } else {
      tryExec(`npx --yes --quiet prettier --write "${filePath}" 2>/dev/null`);
    }
  }
  process.exit(0);
}

// ── Go ────────────────────────────────────────────────────────────────
if (ext === '.go') {
  tryExec(`gofmt -w "${filePath}"`);
  process.exit(0);
}

// ── Python ────────────────────────────────────────────────────────────
if (ext === '.py') {
  // black 우선, 없으면 autopep8
  if (!tryExec(`black "${filePath}" --quiet 2>/dev/null`)) {
    tryExec(`python -m black "${filePath}" --quiet 2>/dev/null`);
  }
  process.exit(0);
}

// ── Rust ──────────────────────────────────────────────────────────────
if (ext === '.rs') {
  tryExec(`rustfmt "${filePath}" 2>/dev/null`);
  process.exit(0);
}

// ── Java / Kotlin ─────────────────────────────────────────────────────
if (ext === '.java') {
  // google-java-format (있을 때만)
  tryExec(`google-java-format -i "${filePath}" 2>/dev/null`);
  process.exit(0);
}

if (ext === '.kt' || ext === '.kts') {
  tryExec(`ktlint -F "${filePath}" 2>/dev/null`);
  process.exit(0);
}

// ── PHP ───────────────────────────────────────────────────────────────
if (ext === '.php') {
  tryExec(`php-cs-fixer fix "${filePath}" --quiet 2>/dev/null`);
  process.exit(0);
}

process.exit(0);
