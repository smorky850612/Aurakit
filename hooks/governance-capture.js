#!/usr/bin/env node
/**
 * AuraKit — Governance Capture (의사결정 감사 추적)
 * Write 완료 후 주요 파일 생성 이력을 자동 기록
 * .aura/governance/decisions.jsonl + adr-YYYY-MM.md 누적
 * Hook: PostToolUse (matcher: Write)
 */
'use strict';

const { readInput, mkdirSafe, fileExists, AURA_DIR } = require('./lib/common.js');
const path = require('path');
const fs = require('fs');

const input = readInput();
const toolName = input.tool_name || '';
const toolInput = input.tool_input || {};

// Write 툴만 처리
if (toolName !== 'Write') process.exit(0);

const filePath = toolInput.file_path || '';
const content = toolInput.content || '';
if (!filePath || !content) process.exit(0);

// ── 기록 제외 패턴 (노이즈 방지) ─────────────────────────────────────
const SKIP_PATTERNS = /\.(test|spec|snap|lock|log|map|min\.js|d\.ts)(\.|$)/i;
if (SKIP_PATTERNS.test(filePath)) process.exit(0);

// 짧은 파일 스킵 (30줄 미만 — 설정 조각 등 제외)
const lines = content.split('\n');
if (lines.length < 30) process.exit(0);

// ── 카테고리 감지 ────────────────────────────────────────────────────
const CATEGORY_PATTERNS = [
  { re: /\.(config|conf|toml|ini)$|next\.config|vite\.config|tsconfig|eslint|prettier/i, label: 'config' },
  { re: /schema|migration|migrate|prisma|drizzle/i, label: 'schema' },
  { re: /route|endpoint|handler|controller|api\//i, label: 'api' },
  { re: /auth|login|session|token|jwt|oauth/i, label: 'auth' },
  { re: /database|db\.|model|entity|repository|dao/i, label: 'database' },
  { re: /Dockerfile|docker-compose|\.github\/workflows|k8s|terraform/i, label: 'infra' },
  { re: /component|\.tsx?$|\.vue$|\.svelte$/i, label: 'ui' },
  { re: /service|provider|context|store|hook/i, label: 'service' },
  { re: /test|spec|e2e|playwright|vitest|jest/i, label: 'test' },
];

let category = 'general';
const baseName = path.basename(filePath);
const firstLines = content.substring(0, 500);

for (const { re, label } of CATEGORY_PATTERNS) {
  if (re.test(filePath) || re.test(baseName) || re.test(firstLines)) {
    category = label;
    break;
  }
}

// ── 거버넌스 디렉토리 초기화 ─────────────────────────────────────────
const govDir = path.join(AURA_DIR, 'governance');
mkdirSafe(govDir);

// ── decisions.jsonl 기록 ──────────────────────────────────────────────
const entry = JSON.stringify({
  ts: new Date().toISOString(),
  file: filePath,
  category,
  lines: lines.length,
  summary: lines[0].replace(/^[#/*\s]+/, '').substring(0, 80),
}) + '\n';

try { fs.appendFileSync(path.join(govDir, 'decisions.jsonl'), entry, 'utf8'); } catch {}

// ── ADR 월별 마크다운 ─────────────────────────────────────────────────
const month = new Date().toISOString().substring(0, 7);
const adrFile = path.join(govDir, `adr-${month}.md`);

if (!fileExists(adrFile)) {
  try {
    fs.writeFileSync(
      adrFile,
      `# AuraKit Architecture Decisions — ${month}\n\n` +
      `> 자동 생성 (governance-capture.js). /aura review 시 분석 대상.\n\n`,
      'utf8'
    );
  } catch {}
}

const ts = new Date().toISOString().replace('T', ' ').substring(0, 16);
const adrLine = `- \`${ts}\` [${category}] \`${path.basename(filePath)}\` — ${lines.length}줄\n`;
try { fs.appendFileSync(adrFile, adrLine, 'utf8'); } catch {}

process.exit(0);
