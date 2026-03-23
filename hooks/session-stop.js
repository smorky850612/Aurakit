#!/usr/bin/env node
/**
 * AuraKit — Stop Hook (세션 종료 메트릭 + Instinct 평가 힌트)
 * Hook: Stop
 * 세션 종료 시: 로그 기록, 실패 카운터 리셋, 미완료 작업 알림
 */
'use strict';

const { readInput, fileExists, readFileSafe, mkdirSafe, AURA_DIR } = require('./lib/common.js');
const path = require('path');
const fs = require('fs');

const input = readInput();
const sessionId = input.session_id || 'unknown';

const logsDir = path.join(AURA_DIR, 'logs');
mkdirSafe(logsDir);

// ── 세션 종료 로그 ─────────────────────────────────────────────────────
const stopLog = {
  ts: new Date().toISOString(),
  event: 'session_stop',
  session_id: sessionId,
};

try {
  fs.appendFileSync(
    path.join(logsDir, 'sessions.jsonl'),
    JSON.stringify(stopLog) + '\n',
    'utf8'
  );
} catch {}

// ── 실패 카운터 초기화 (다음 세션을 위해) ─────────────────────────────
const counterFile = path.join(logsDir, 'failure-counts.json');
try { fs.writeFileSync(counterFile, '{}', 'utf8'); } catch {}

// ── Instinct 패턴 평가 힌트 ──────────────────────────────────────────
const instinctsDir = path.join(AURA_DIR, 'instincts');
const instinctIndex = path.join(instinctsDir, 'index.json');

if (fileExists(instinctIndex)) {
  try {
    const idx = JSON.parse(readFileSafe(instinctIndex, '{}'));
    const patterns = idx.patterns || [];
    const lowScore = patterns.filter(p => p.score > 20 && p.score < 40).length;
    const highScore = patterns.filter(p => p.score >= 80).length;
    const total = patterns.length;

    const msgs = [];
    if (total > 0) msgs.push(`📚 Instincts: ${total}개 패턴 (Top: ${highScore}개 score≥80)`);
    if (lowScore > 0) msgs.push(`💡 저점수 패턴 ${lowScore}개 → 다음 세션에서 /aura instinct:evolve`);

    if (msgs.length > 0) {
      process.stderr.write('\n' + msgs.join('\n') + '\n');
    }
  } catch {}
}

// ── 미완료 스냅샷 알림 ───────────────────────────────────────────────
const snapshotFile = path.join(AURA_DIR, 'snapshots', 'current.md');
if (fileExists(snapshotFile)) {
  const content = readFileSafe(snapshotFile);
  const mode = (content.match(/^- Mode: (.+)/m) || [])[1] || '';
  const status = (content.match(/^- Status: (.+)/m) || [])[1] || '';

  if (status && !/(complete|done|완료|Pass)/i.test(status)) {
    process.stderr.write(
      `\n📌 AuraKit: 미완료 작업 저장됨\n` +
      `   모드: ${mode} | 상태: ${status}\n` +
      `   다음 세션 /aura 실행 시 자동 복구됩니다.\n`
    );
  }
}

// ── 거버넌스 요약 (이번 세션 ADR 기록 수) ──────────────────────────────
const govDir = path.join(AURA_DIR, 'governance');
const month = new Date().toISOString().substring(0, 7);
const adrFile = path.join(govDir, `adr-${month}.md`);
if (fileExists(adrFile)) {
  const adrContent = readFileSafe(adrFile, '');
  const adrCount = (adrContent.match(/^- `/gm) || []).length;
  if (adrCount > 0) {
    process.stderr.write(
      `\n📋 이번 달 아키텍처 기록: ${adrCount}개 → .aura/governance/adr-${month}.md\n`
    );
  }
}

process.exit(0);
