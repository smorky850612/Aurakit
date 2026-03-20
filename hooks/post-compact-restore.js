#!/usr/bin/env node
/**
 * AuraKit — PostCompact Restore (Node.js 크로스 플랫폼 버전)
 * 컴팩트 후 스냅샷에서 컨텍스트 복구
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { readInput, addContext, SNAPSHOTS_DIR } = require('./lib/common.js');

const snapshotFile = path.join(SNAPSHOTS_DIR, 'current.md');
if (!fs.existsSync(snapshotFile)) process.exit(0);

const snap = fs.readFileSync(snapshotFile, 'utf8');
const modeMatch = snap.match(/- Mode:\s*(.+)/);
const requestMatch = snap.match(/- Original Request:\s*(.+)/);
const nextMatch = snap.match(/## Next Action\n([\s\S]+?)(?:\n##|$)/);

const mode = modeMatch ? modeMatch[1].trim() : '알 수 없음';
const req = requestMatch ? requestMatch[1].trim() : '';
const next = nextMatch ? nextMatch[1].trim() : '/aura 로 재개';

addContext(
  `[AuraKit PostCompact 복구]\n` +
  `이전 작업 모드: ${mode}\n` +
  (req ? `원래 요청: ${req}\n` : '') +
  `다음 작업: ${next}\n` +
  `전체 스냅샷: ${snapshotFile}`
);
