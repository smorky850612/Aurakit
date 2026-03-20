#!/usr/bin/env node
/**
 * AuraKit — PreToolUse Migration Guard (Node.js 크로스 플랫폼 버전)
 * 파괴적 DB 마이그레이션 차단. matcher: Write|Edit
 */

'use strict';

const { readInput, allow, block } = require('./lib/common.js');

const input = readInput();
const toolInput = input.tool_input || {};

const content = toolInput.content || toolInput.new_string || '';
const filePath = toolInput.file_path || '';

if (!content) allow();

// 마이그레이션 파일인지 확인 (SQL 파일 또는 migration 디렉토리)
const isMigration = /\/migration[s]?\//i.test(filePath) ||
  /\.sql$/.test(filePath) ||
  /prisma\/migrations/i.test(filePath);

if (!isMigration) allow();

// ── 파괴적 패턴 감지 ─────────────────────────────────────────────────
const PATTERNS = [
  { re: /DROP\s+TABLE(?!\s+IF\s+EXISTS)/i, desc: 'DROP TABLE (IF EXISTS 없음)' },
  { re: /DROP\s+COLUMN/i, desc: 'DROP COLUMN' },
  { re: /ALTER\s+TABLE.*DROP/i, desc: 'ALTER TABLE DROP' },
  { re: /TRUNCATE\s+TABLE/i, desc: 'TRUNCATE TABLE' },
  { re: /DELETE\s+FROM\s+\w+\s*;/i, desc: 'DELETE FROM (WHERE 조건 없음)' },
];

const found = PATTERNS.filter(p => p.re.test(content));

if (found.length > 0) {
  block(
    '🔴 AuraKit Migration Guard 차단\n' +
    '   파괴적 마이그레이션 패턴 감지:\n' +
    found.map(f => '   - ' + f.desc).join('\n') + '\n' +
    '   데이터 백업 확인 후 직접 텍스트 에디터로 작성하세요.'
  );
}

allow();
