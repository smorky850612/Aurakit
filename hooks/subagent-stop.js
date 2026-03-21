#!/usr/bin/env node
/**
 * AuraKit — Subagent Stop Monitor (PostToolUse:Agent) G19
 * 에이전트 완료 시 active.json 에서 제거 + 실행 시간 기록
 * teammate-idle.js와 분리 — 이쪽은 생명주기 관리, idle은 결과 캐싱
 */
'use strict';

const path = require('path');
const fs = require('fs');
const { readInput, allow, mkdirSafe, AURA_DIR } = require('./lib/common.js');

const input = readInput();
const toolInput = input.tool_input || {};
const toolResult = input.tool_response || {};

const agentType = toolInput.subagent_type || 'general-purpose';
const promptHash = (toolInput.prompt || '').slice(0, 50);

const memoryDir = path.join(AURA_DIR, 'agent-memory');
mkdirSafe(memoryDir);

const activeFile = path.join(memoryDir, 'active.json');
const historyFile = path.join(memoryDir, 'history.json');

// active.json 업데이트 (해당 에이전트 제거)
let active = [];
try {
  const raw = fs.readFileSync(activeFile, 'utf8');
  active = JSON.parse(raw);
  if (!Array.isArray(active)) active = [];
} catch { active = []; }

// 매칭 항목 찾기 (type + promptHash)
let matchIdx = active.findIndex(a =>
  a.type === agentType && a.promptHash.startsWith(promptHash.slice(0, 30))
);
if (matchIdx === -1) matchIdx = active.findIndex(a => a.type === agentType);

let duration = null;
if (matchIdx !== -1) {
  const entry = active[matchIdx];
  const startTime = new Date(entry.startedAt).getTime();
  duration = Math.round((Date.now() - startTime) / 1000);
  active.splice(matchIdx, 1);
}

try {
  fs.writeFileSync(activeFile, JSON.stringify(active, null, 2), 'utf8');
} catch {}

// history.json 에 실행 기록 추가
let history = [];
try {
  const raw = fs.readFileSync(historyFile, 'utf8');
  history = JSON.parse(raw);
  if (!Array.isArray(history)) history = [];
} catch { history = []; }

const resultStr = typeof toolResult === 'string'
  ? toolResult.slice(0, 200)
  : JSON.stringify(toolResult).slice(0, 200);

history.unshift({
  type: agentType,
  promptHash,
  completedAt: new Date().toISOString(),
  durationSec: duration,
  status: resultStr.length > 0 ? 'completed' : 'empty',
  resultSnippet: resultStr,
});

// 최근 20개만 유지
history = history.slice(0, 20);

try {
  fs.writeFileSync(historyFile, JSON.stringify(history, null, 2), 'utf8');
} catch {}

allow();
