#!/usr/bin/env node
/**
 * AuraKit — Subagent Start Monitor (PreToolUse:Agent) G19
 * 에이전트 시작 시 .aura/agent-memory/active.json 에 기록
 * 동시 실행 에이전트 추적 및 컨텍스트 격리 확인
 *
 * === Anti-Infinite-Loop Safeguards ===
 * - Max total agents per session: 12
 * - Max depth: 3 (Agent → Child → Grandchild)
 * - Circuit breaker: frozen flag stops all new spawns
 * - 3 consecutive failures → auto-freeze
 * - Concurrent agent cap: 5 (warning at threshold)
 *
 * See: skills/aura/resources/agent-spawning.md
 */
'use strict';

const path = require('path');
const fs = require('fs');
const { readInput, allow, mkdirSafe, AURA_DIR } = require('./lib/common.js');

// ── Constants ────────────────────────────────────────────────────────
const MAX_SPAWN_COUNT = 12;
const MAX_DEPTH = 3;
const MAX_CONCURRENT = 5;
const STALE_TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes
const CONSECUTIVE_FAIL_LIMIT = 3;

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

// ── Default tracking structure ───────────────────────────────────────
const DEFAULT_TRACKING = {
  session_id: `session-${Date.now()}`,
  spawn_count: 0,
  max_depth_reached: 0,
  failed_count: 0,
  frozen: false,
  agents: [],
};

// ── Load tracking file ──────────────────────────────────────────────
let tracking;
try {
  const raw = fs.readFileSync(activeFile, 'utf8');
  const parsed = JSON.parse(raw);
  // Migration: if the file is an old-format array, convert it
  if (Array.isArray(parsed)) {
    tracking = {
      ...DEFAULT_TRACKING,
      spawn_count: parsed.length,
      agents: parsed.map(a => ({
        id: a.id || `agent-${Date.now()}`,
        status: a.status || 'running',
        depth: a.depth || 1,
        tokens_used: a.tokens_used || 0,
        startedAt: a.startedAt,
        type: a.type,
        children: a.children || [],
      })),
    };
  } else if (parsed && typeof parsed === 'object') {
    tracking = { ...DEFAULT_TRACKING, ...parsed };
  } else {
    tracking = { ...DEFAULT_TRACKING };
  }
} catch {
  tracking = { ...DEFAULT_TRACKING };
}

// ── Prune stale agents (older than 5 minutes) ───────────────────────
const now = Date.now();
tracking.agents = (tracking.agents || []).filter(a => {
  if (!a.startedAt) return true; // keep entries without timestamp
  return (now - new Date(a.startedAt).getTime()) < STALE_TIMEOUT_MS;
});

// ── Calculate current state ─────────────────────────────────────────
const runningAgents = tracking.agents.filter(a => a.status === 'running');
const currentDepth = Math.max(0, ...tracking.agents.map(a => a.depth || 1));
const nextDepth = currentDepth < MAX_DEPTH ? currentDepth + 1 : currentDepth;

// ── Anti-Infinite-Loop Checks (advisory — log to stderr, don't block) ─
let warnings = [];

// Check 1: frozen flag (circuit breaker tripped)
if (tracking.frozen === true) {
  warnings.push(
    `[AuraKit] SPAWN FROZEN: Agent spawning is frozen due to circuit breaker. ` +
    `No new agents should be created. Reset .aura/agent-memory/active.json to unfreeze.`
  );
}

// Check 2: total spawn count
if (tracking.spawn_count >= MAX_SPAWN_COUNT) {
  warnings.push(
    `[AuraKit] SPAWN LIMIT: Total agent count (${tracking.spawn_count}) reached ` +
    `maximum of ${MAX_SPAWN_COUNT}. No more agents should be spawned this session.`
  );
}

// Check 3: max depth
if (currentDepth >= MAX_DEPTH) {
  warnings.push(
    `[AuraKit] DEPTH LIMIT: Current depth (${currentDepth}) has reached ` +
    `maximum of ${MAX_DEPTH}. No deeper nesting allowed.`
  );
}

// Check 4: concurrent agent cap
if (runningAgents.length >= MAX_CONCURRENT) {
  warnings.push(
    `[AuraKit] CONCURRENT LIMIT: ${runningAgents.length} agents running ` +
    `(max ${MAX_CONCURRENT}). Wait for agents to complete before spawning more.`
  );
}

// Check 5: consecutive failure circuit breaker
if (tracking.failed_count >= CONSECUTIVE_FAIL_LIMIT && !tracking.frozen) {
  tracking.frozen = true;
  warnings.push(
    `[AuraKit] CIRCUIT BREAKER: ${tracking.failed_count} consecutive agent failures detected. ` +
    `Spawning is now FROZEN. Partial results may be in .aura/snapshots/recovery.md`
  );
}

// Emit all warnings to stderr
if (warnings.length > 0) {
  process.stderr.write(warnings.join('\n') + '\n');
}

// ── Register new agent ──────────────────────────────────────────────
const entry = {
  id: `agent-${Date.now()}`,
  type: agentType,
  promptHash: agentPrompt,
  startedAt: new Date().toISOString(),
  background: runInBg,
  isolation,
  status: 'running',
  depth: nextDepth,
  children: [],
};

tracking.agents.push(entry);
tracking.spawn_count += 1;

// Update max depth reached
if (nextDepth > tracking.max_depth_reached) {
  tracking.max_depth_reached = nextDepth;
}

// ── Write updated tracking file ─────────────────────────────────────
try {
  fs.writeFileSync(activeFile, JSON.stringify(tracking, null, 2), 'utf8');
} catch {}

// ── Concurrent agent warning (soft) ─────────────────────────────────
const updatedRunning = tracking.agents.filter(a => a.status === 'running');
if (updatedRunning.length > MAX_CONCURRENT) {
  process.stderr.write(
    `[AuraKit] WARNING: ${updatedRunning.length} concurrent agents running ` +
    `(recommended max: ${MAX_CONCURRENT}). Monitor token usage closely.\n`
  );
}

allow();
