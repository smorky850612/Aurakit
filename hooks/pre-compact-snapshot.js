#!/usr/bin/env node
/**
 * AuraKit — PreCompact Snapshot (Node.js 크로스 플랫폼 버전)
 * 컴팩트 전 현재 작업 상태를 스냅샷으로 저장
 */
'use strict';
const { readInput, allow } = require('./lib/common.js');
const { readSnapshot, writeSnapshot, createDefaultSnapshot, touchSnapshot } = require('./lib/snapshot.js');

readInput(); // stdin consume (required by hook protocol)

const existing = readSnapshot();
if (!existing || existing.trim() === '') {
  writeSnapshot(createDefaultSnapshot('알 수 없음 (PreCompact 자동 저장)'));
}

touchSnapshot();
allow();
