#!/usr/bin/env node
/**
 * AuraKit — Stop Hook Token Tracker (Node.js wrapper)
 * 기존 token-tracker.py를 호출하는 크로스 플랫폼 래퍼
 */
'use strict';
const { execSync } = require('child_process');
const path = require('path');

const dir = __dirname;
const pyScript = path.join(dir, 'token-tracker.py');
const py = process.platform === 'win32' ? 'python' : (
  (() => { try { execSync('python3 --version', {stdio:'pipe'}); return 'python3'; } catch { return 'python'; } })()
);

// stdin을 py script로 전달
const { spawnSync } = require('child_process');
const stdin = require('fs').readFileSync(0);
const result = spawnSync(py, [pyScript], { input: stdin, encoding: 'utf8', timeout: 10000 });

if (result.stdout) process.stdout.write(result.stdout);
if (result.stderr) process.stderr.write(result.stderr);
process.exit(result.status || 0);
