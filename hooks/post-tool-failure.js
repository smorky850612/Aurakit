#!/usr/bin/env node
/**
 * AuraKit — PostToolUseFailure Recovery Hook
 * MCP 도구 실패 자동 복구 + 감사 로그 + 세션 내 누적 추적
 * Hook: PostToolUseFailure
 */
'use strict';

const { readInput, mkdirSafe, readFileSafe, AURA_DIR } = require('./lib/common.js');
const path = require('path');
const fs = require('fs');

const input = readInput();
const toolName = input.tool_name || 'unknown';
const error = String(input.error || input.tool_error || '').substring(0, 300);
const toolInput = input.tool_input || {};

// ── 감사 로그 ─────────────────────────────────────────────────────────
const logsDir = path.join(AURA_DIR, 'logs');
mkdirSafe(logsDir);

const logEntry = JSON.stringify({
  ts: new Date().toISOString(),
  event: 'tool_failure',
  tool: toolName,
  error: error,
  input_keys: Object.keys(toolInput),
}) + '\n';

try { fs.appendFileSync(path.join(logsDir, 'tool-failures.jsonl'), logEntry, 'utf8'); } catch {}

// ── 실패 횟수 누적 (세션 내) ─────────────────────────────────────────
const counterFile = path.join(logsDir, 'failure-counts.json');
let counts = {};
try { counts = JSON.parse(fs.readFileSync(counterFile, 'utf8')); } catch {}
counts[toolName] = (counts[toolName] || 0) + 1;
try { fs.writeFileSync(counterFile, JSON.stringify(counts, null, 2), 'utf8'); } catch {}

// ── MCP 복구 전략 ─────────────────────────────────────────────────────
const isMCPTool = toolName.startsWith('mcp__') || /Sanity|Vercel|GitHub|Slack/i.test(toolName);
const isTimeoutError = /timeout|ETIMEDOUT|ECONNREFUSED|ECONNRESET/i.test(error);
const isAuthError = /auth|token|credential|401|403|unauthorized/i.test(error);
const isNotFoundError = /not found|404|does not exist/i.test(error);

if (isMCPTool) {
  if (isTimeoutError) {
    process.stderr.write(
      `\n💡 AuraKit MCP Recovery [${toolName}]: 연결 타임아웃\n` +
      `   → 자동 재시도 또는 REST API 직접 호출로 전환합니다.\n`
    );
  } else if (isAuthError) {
    process.stderr.write(
      `\n🔐 AuraKit MCP Recovery [${toolName}]: 인증 실패\n` +
      `   → /aura mcp:check 실행 또는 MCP 토큰 갱신이 필요합니다.\n`
    );
  } else if (isNotFoundError) {
    process.stderr.write(
      `\n⚠️  AuraKit MCP Recovery [${toolName}]: 리소스 없음\n` +
      `   → 리소스 ID/이름을 확인하거나 로컬 캐시를 사용합니다.\n`
    );
  } else {
    process.stderr.write(
      `\n⚠️  AuraKit MCP Recovery [${toolName}]: 도구 실패\n` +
      `   → 대안: 직접 API 호출 또는 수동 처리로 전환합니다.\n`
    );
  }
}

// 동일 도구 3회 이상 연속 실패 시 강한 경고
if (counts[toolName] >= 3) {
  process.stderr.write(
    `\n🚨 AuraKit: [${toolName}] 이번 세션 ${counts[toolName]}회 실패 누적\n` +
    `   → /aura mcp:check 실행 또는 MCP 서버 재시작을 권장합니다.\n`
  );
}

process.exit(0);
