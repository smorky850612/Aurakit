#!/usr/bin/env node
/**
 * AuraKit — PreCompact Snapshot (Node.js 크로스 플랫폼 버전)
 * 컴팩트 전 현재 작업 상태를 스냅샷으로 저장
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { readInput, allow, AURA_DIR, SNAPSHOTS_DIR, mkdirSafe, writeFileSafe } = require('./lib/common.js');

const input = readInput();
const transcriptPath = input.transcript_path || '';

mkdirSafe(SNAPSHOTS_DIR);

const snapshotFile = path.join(SNAPSHOTS_DIR, 'current.md');
const existing = fs.existsSync(snapshotFile) ? fs.readFileSync(snapshotFile, 'utf8') : '';

if (!existing || existing.trim() === '') {
  // 기본 스냅샷 생성
  const ts = new Date().toISOString();
  const snap = `# AuraKit Snapshot\n- Timestamp: ${ts}\n- Mode: 알 수 없음 (PreCompact 자동 저장)\n\n## Status\nCompact 전 자동 저장됨.\n\n## Next Action\n/aura 로 재개\n`;
  writeFileSafe(snapshotFile, snap);
}

// 타임스탬프 갱신
try {
  let snap = fs.readFileSync(snapshotFile, 'utf8');
  snap = snap.replace(/- Timestamp:.*/, `- Timestamp: ${new Date().toISOString()}`);
  fs.writeFileSync(snapshotFile, snap, 'utf8');
} catch {}

allow();
