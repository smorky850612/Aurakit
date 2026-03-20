#!/usr/bin/env node
/**
 * AuraKit — PostToolUse Build Verify (Node.js 크로스 플랫폼 버전)
 * TypeScript/Python 문법 검사 (V1). matcher: Write|Edit
 */
'use strict';
const { execSync } = require('child_process');
const { readInput, allow } = require('./lib/common.js');
const input = readInput();
const filePath = (input.tool_input || {}).file_path || '';
if (!filePath) allow();

// TypeScript 파일 검사
if (/\.(ts|tsx)$/.test(filePath)) {
  try {
    execSync('npx tsc --noEmit --skipLibCheck 2>&1', { timeout: 15000, stdio: 'pipe' });
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

allow();
