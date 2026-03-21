#!/usr/bin/env node
/**
 * AuraKit — Subagent Start Monitor (PreToolUse:Agent) G19
 * 에이전트 시작 시 .aura/agent-memory/active.json 에 기록
 * 동시 실행 에이전트 추적 및 컨텍스트 격리 확인
 */
'use strict';

const path = require('path');
const fs = require('fs');
const { readInput, allow, mkdirSafe, AURA_DIR } = require('./lib/common.js');

const input = readInput();
const toolInput = input.tool_input || {};

const agentPrompt = (toolInput.prompt || '').slice(0, 100);
const agentType = toolInput.subagent_type || 'general-purpose';
const runInBg = toolInput.run_in_background || false;
const isolation = toolInput.isolation || 'none';

if (!agentPrompt) allow();

const memoryDir = path.join(AURA_DIR, 'agent-memory');
mkdirSafe(memoryDir);

const activeFile = path.join(memoryDir, 'active.json');

// 현재 활성 에이전트 목록 로딩
let active = [];
try {
  const raw = fs.readFileSync(activeFile, 'utf8');
  active = JSON.parse(raw);
  if (!Array.isArray(active)) active = [];
} catch { active = []; }

// 5분 이상 된 항목 제거 (stale 방지)
const now = Date.now();
active = active.filter(a => (now - new Date(a.startedAt).getTime()) < 5 * 60 * 1000);

// 새 에이전트 등록
const entry = {
  id: `agent-${Date.now()}`,
  type: agentType,
  promptHash: agentPrompt,
  startedAt: new Date().toISOString(),
  background: runInBg,
  isolation,
  status: 'running',
};

active.push(entry);

try {
  fs.writeFileSync(activeFile, JSON.stringify(active, null, 2), 'utf8');
} catch {}

// 동시 에이전트 경고 (5개 초과 시)
if (active.length > 5) {
  process.stderr.write(
    `[AuraKit] ⚠️  동시 에이전트 ${active.length}개 실행 중. 토큰 사용량 주의.\n`
  );
}

allow();
