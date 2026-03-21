#!/usr/bin/env node
/**
 * AuraKit — Teammate Idle Monitor (PostToolUse:Agent) G4
 * 에이전트 작업 완료 시 결과를 .aura/agent-memory 에 저장
 * 다음 에이전트가 이전 에이전트 결과를 참고할 수 있도록 (크로스에이전트 메모리)
 */
'use strict';

const path = require('path');
const fs = require('fs');
const { readInput, allow, mkdirSafe, AURA_DIR } = require('./lib/common.js');

const input = readInput();
const toolInput = input.tool_input || {};
const toolResult = input.tool_response || {};

const agentPrompt = (toolInput.prompt || '').toLowerCase();
if (!agentPrompt) allow();

let agentType = 'unknown';
if (/scout|프로젝트 스캔|탐색/.test(agentPrompt)) agentType = 'scout';
else if (/review|리뷰|검토/.test(agentPrompt)) agentType = 'reviewer';
else if (/test|테스트/.test(agentPrompt)) agentType = 'test-runner';
else if (/security|보안/.test(agentPrompt)) agentType = 'security';
else if (/gap|match rate/.test(agentPrompt)) agentType = 'gap-detector';
else if (/build|구현|만들/.test(agentPrompt)) agentType = 'builder';
else if (/debug|fix|수정/.test(agentPrompt)) agentType = 'debugger';

if (agentType === 'unknown') allow();

const memoryDir = path.join(AURA_DIR, 'agent-memory');
mkdirSafe(memoryDir);

const memoryFile = path.join(memoryDir, agentType + '.json');
const resultStr = typeof toolResult === 'string' ? toolResult : JSON.stringify(toolResult);

const memory = {
  agent: agentType,
  timestamp: new Date().toISOString(),
  promptHash: agentPrompt.slice(0, 50),
  result: resultStr.slice(0, 500),
  status: resultStr.length > 0 ? 'completed' : 'empty',
};

try {
  fs.writeFileSync(memoryFile, JSON.stringify(memory, null, 2), 'utf8');
} catch {}

allow();
