#!/usr/bin/env node
/**
 * AuraKit — UserPromptSubmit Token Stats Inject (Node.js wrapper)
 * 기존 token-stats-inject.py를 호출하는 크로스 플랫폼 래퍼
 */
'use strict';
const path = require('path');
const { spawnSync } = require('child_process');

const dir = __dirname;
const pyScript = path.join(dir, 'token-stats-inject.py');
const py = process.platform === 'win32' ? 'python' : (
  (() => { try { require('child_process').execSync('python3 --version', {stdio:'pipe'}); return 'python3'; } catch { return 'python'; } })()
);

const stdin = require('fs').readFileSync(0);
const result = spawnSync(py, [pyScript], { input: stdin, encoding: 'utf8', timeout: 10000 });

if (result.stdout) process.stdout.write(result.stdout);
if (result.stderr) process.stderr.write(result.stderr);
process.exit(result.status || 0);
