#!/usr/bin/env node
/**
 * AuraKit LEAKFORGE — cache-guard.js
 * NERVE 모듈 | CACHE-RULE-01~07 자동 준수 가드
 *
 * 이벤트: PreToolUse
 * 기능:
 *   - 도구 세트 변경/모델 변경 시도 감지 (CACHE-RULE-03/04)
 *   - 위반 시 경고 메시지를 context에 주입하고 block
 *   - 캐시 미스 추정 토큰 수를 StatusLine 표시용으로 기록
 *
 * hooks/lib/common.js의 readInput, addContext, block, writeFileSafe 활용
 */

'use strict';

const path = require('path');
const { readInput, addContext, block, writeFileSafe, AURA_DIR } = require('./lib/common');

// ── 캐시 미스 추정 토큰 비용 ──────────────────────────────────────────
const CACHE_MISS_ESTIMATES = {
  TOOL_CHANGE: 19000,      // 도구 정의 ~5K + 시스템 프롬프트 14K
  MODEL_CHANGE: 50000,     // 대화 히스토리 전체 재처리 (중간 규모 추정)
  SYSTEM_PROMPT_CHANGE: 14000, // 시스템 프롬프트만
};

// ── 위험 도구 패턴 (세션 중 추가/제거가 캐시를 깨는 도구 조작) ──────────
// "model" 관련 bash 명령어 감지
const MODEL_CHANGE_PATTERNS = [
  /claude\s+--model\s+/i,
  /ANTHROPIC_MODEL\s*=/i,
  /CLAUDE_MODEL\s*=/i,
];

// 도구 세트 변경을 시사하는 명령어 패턴
const TOOL_CHANGE_PATTERNS = [
  /claude\s+mcp\s+add/i,
  /claude\s+mcp\s+remove/i,
  /settings\.json.*disallowed-tools/i,
];

// ── 캐시 미스 기록 ────────────────────────────────────────────────────
function recordCacheMiss(rule, estimatedTokens, reason) {
  const logPath = path.join(AURA_DIR, 'cache-guard-log.json');
  let log = [];
  try {
    const existing = require('fs').readFileSync(logPath, 'utf8');
    log = JSON.parse(existing);
  } catch {}

  log.push({
    timestamp: new Date().toISOString(),
    rule,
    estimatedTokens,
    reason,
  });

  // 최근 50개만 유지
  if (log.length > 50) log = log.slice(-50);

  writeFileSafe(logPath, JSON.stringify(log, null, 2));
}

// ── 총 캐시 미스 토큰 조회 ────────────────────────────────────────────
function getTotalCacheMiss() {
  const logPath = path.join(AURA_DIR, 'cache-guard-log.json');
  try {
    const log = JSON.parse(require('fs').readFileSync(logPath, 'utf8'));
    return log.reduce((sum, entry) => sum + (entry.estimatedTokens || 0), 0);
  } catch {
    return 0;
  }
}

// ── 메인 ─────────────────────────────────────────────────────────────
const input = readInput();
const toolName = input.tool_name || '';
const toolInput = input.tool_input || {};

// Bash 명령어 내용 추출
const bashCommand = (toolInput.command || '').toString();
const writeContent = (toolInput.content || '').toString();

let violation = null;

// CACHE-RULE-03: 도구 세트 변경 감지
if (toolName === 'Bash') {
  for (const pattern of TOOL_CHANGE_PATTERNS) {
    if (pattern.test(bashCommand)) {
      violation = {
        rule: 'CACHE-RULE-03',
        estimatedTokens: CACHE_MISS_ESTIMATES.TOOL_CHANGE,
        reason: `세션 중 도구 세트 변경 시도: ${bashCommand.slice(0, 80)}`,
      };
      break;
    }
  }

  // CACHE-RULE-04: 모델 변경 감지
  if (!violation) {
    for (const pattern of MODEL_CHANGE_PATTERNS) {
      if (pattern.test(bashCommand)) {
        violation = {
          rule: 'CACHE-RULE-04',
          estimatedTokens: CACHE_MISS_ESTIMATES.MODEL_CHANGE,
          reason: `세션 중 모델 변경 시도: ${bashCommand.slice(0, 80)}`,
        };
        break;
      }
    }
  }
}

// Write/Edit로 settings.json 도구 목록 변경 감지 (CACHE-RULE-03)
if ((toolName === 'Write' || toolName === 'Edit') &&
    (toolInput.file_path || '').includes('settings.json') &&
    (writeContent.includes('disallowed-tools') || writeContent.includes('allowed-tools'))) {
  violation = {
    rule: 'CACHE-RULE-03',
    estimatedTokens: CACHE_MISS_ESTIMATES.TOOL_CHANGE,
    reason: 'settings.json 도구 목록 세션 중 변경 시도',
  };
}

if (violation) {
  recordCacheMiss(violation.rule, violation.estimatedTokens, violation.reason);
  const totalMiss = getTotalCacheMiss();

  const warningMsg = [
    `⚠️  [CACHE-GUARD] ${violation.rule} 위반 감지`,
    `    이유: ${violation.reason}`,
    `    예상 캐시 미스: ~${(violation.estimatedTokens / 1000).toFixed(0)}K 토큰`,
    `    세션 누적 캐시 미스: ~${(totalMiss / 1000).toFixed(0)}K 토큰`,
    ``,
    `    대안:`,
    violation.rule === 'CACHE-RULE-03'
      ? `    → 도구 세트 변경 대신 기존 도구로 작업하거나 새 세션에서 시작`
      : `    → /aura escalate 명령으로 서브에이전트에 작업 위임`,
    ``,
    `    계속 진행하려면 이 경고를 무시하고 직접 실행하세요.`,
    `    캐시 규칙 상세: skills/aura/resources/cache-engineering.md`,
  ].join('\n');

  // 경고만 주입하고 계속 진행 (block 대신 addContext)
  // 치명적 보안 위반이 아니므로 사용자가 판단
  addContext(warningMsg);
} else {
  // 정상 — 아무것도 하지 않음
  process.exit(0);
}
