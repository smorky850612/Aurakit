#!/usr/bin/env node
/**
 * AuraKit — PostToolUse Build Verify (Node.js 크로스 플랫폼 버전)
 * TypeScript/Python 문법 검사 + Convention Check (V1). matcher: Write|Edit
 */
'use strict';
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');
const { readInput, allow } = require('./lib/common.js');
const input = readInput();
const filePath = (input.tool_input || {}).file_path || '';
if (!filePath) allow();

// TypeScript 파일 검사 — tsconfig.json 없으면 스킵 (npx 기동비용 방지)
if (/\.(ts|tsx)$/.test(filePath) && fs.existsSync('tsconfig.json')) {
  try {
    // 로컬 tsc 우선 사용 (npx 오버헤드 ~1s 제거)
    const localTsc = path.join('node_modules', '.bin', 'tsc');
    const tscCmd = fs.existsSync(localTsc) ? `"${localTsc}"` : 'npx tsc';
    execSync(`${tscCmd} --noEmit --skipLibCheck 2>&1`, { timeout: 15000, stdio: 'pipe' });
  } catch (e) {
    const out = e.stdout ? e.stdout.toString() : '';
    if (out && out.includes('error TS')) {
      process.stderr.write('⚠️  AuraKit V1: TypeScript 오류\n' + out.substring(0, 500) + '\n');
    }
  }
}

// Python 파일 검사
if (/\.py$/.test(filePath)) {
  try {
    const py = process.platform === 'win32' ? 'python' : 'python3';
    execSync(`${py} -m py_compile "${filePath}" 2>&1`, { timeout: 10000, stdio: 'pipe' });
  } catch (e) {
    const out = e.stdout ? e.stdout.toString() : (e.stderr ? e.stderr.toString() : '');
    if (out) process.stderr.write('⚠️  AuraKit V1: Python 오류\n' + out.substring(0, 300) + '\n');
  }
}

// Convention Check (CONV-001~005) — 경고만, 차단 아님 (pre-commit에서 차단)
if (/\.(ts|tsx|js|jsx|py|go)$/.test(filePath)) {
  try {
    const convScript = path.join(__dirname, '..', 'scripts', 'convention-check.sh');
    if (fs.existsSync(convScript)) {
      execSync(`bash "${convScript}" "${filePath}" 2>&1`, { timeout: 10000, stdio: 'pipe' });
    }
  } catch (e) {
    const out = e.stdout ? e.stdout.toString() : '';
    if (out && out.includes('CONV')) {
      process.stderr.write('⚠️  AuraKit V1 Convention:\n' + out.substring(0, 400) + '\n');
    }
  }
}

allow();
