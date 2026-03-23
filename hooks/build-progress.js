#!/usr/bin/env node
/**
 * AuraKit — PostToolUse Build Progress (Node.js 크로스 플랫폼 버전)
 * 파일 완료 시 스냅샷 업데이트 + 진행률 표시. matcher: Write|Edit
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { readInput, allow, AURA_DIR, SNAPSHOTS_DIR } = require('./lib/common.js');

const input = readInput();
const filePath = (input.tool_input || {}).file_path || '';
if (!filePath) allow();

const snapshotFile = path.join(SNAPSHOTS_DIR, 'current.md');
try {
  if (fs.existsSync(snapshotFile)) {
    let snap = fs.readFileSync(snapshotFile, 'utf8');
    // Remaining 섹션에서 완료된 파일 체크
    const baseName = path.basename(filePath);
    const escapedBase = baseName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    snap = snap.replace(new RegExp(`^- \\[ \\] .*${escapedBase}.*$`, 'm'), m => m.replace('[ ]', '[x]'));
    fs.writeFileSync(snapshotFile, snap, 'utf8');
  }
} catch {}

allow();
