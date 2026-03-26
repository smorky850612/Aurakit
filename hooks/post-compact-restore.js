#!/usr/bin/env node
/**
 * AuraKit — PostCompact Restore (Node.js 크로스 플랫폼 버전)
 * 컴팩트 후 스냅샷에서 컨텍스트 복구
 */
'use strict';
const { readInput, addContext } = require('./lib/common.js');
const { readSnapshot, getSnapshotPath, parseSnapshot } = require('./lib/snapshot.js');

readInput(); // stdin consume (required by hook protocol)

// 자동 컴팩트 후 환경변수 복원 (aura-compact가 1%로 낮춘 경우)
if (process.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE === '1') {
  process.env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = '65';
}

const snap = readSnapshot();
if (!snap) process.exit(0);

const { mode, request, next } = parseSnapshot(snap);

addContext(
  `[AuraKit PostCompact 복구]\n` +
  `이전 작업 모드: ${mode}\n` +
  (request ? `원래 요청: ${request}\n` : '') +
  `다음 작업: ${next}\n` +
  `전체 스냅샷: ${getSnapshotPath()}`
);
