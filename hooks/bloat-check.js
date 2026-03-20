#!/usr/bin/env node
/**
 * AuraKit — PostToolUse Bloat Check (Node.js 크로스 플랫폼 버전)
 * 파일 크기 감시 (250줄 초과 경고). matcher: Write|Edit
 */
'use strict';
const fs = require('fs');
const { readInput, allow } = require('./lib/common.js');
const input = readInput();
const filePath = (input.tool_input || {}).file_path || '';
if (!filePath) allow();

try {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n').length;
  if (lines > 250) {
    process.stderr.write(
      `⚠️  AuraKit Bloat: ${filePath} (${lines}줄 > 250줄)\n` +
      '   컴포넌트 분할을 권장합니다. /aura clean: 으로 정리 가능.\n'
    );
  }
} catch {}
allow();
