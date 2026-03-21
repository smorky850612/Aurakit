/**
 * AuraKit — Snapshot Helpers
 * 스냅샷 읽기/쓰기/파싱 공통 유틸리티
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { SNAPSHOTS_DIR, mkdirSafe, writeFileSafe } = require('./common.js');

const SNAPSHOT_FILE = path.join(SNAPSHOTS_DIR, 'current.md');

/**
 * 스냅샷 파일 경로 반환
 */
function getSnapshotPath() {
  return SNAPSHOT_FILE;
}

/**
 * 스냅샷 내용 읽기 (없으면 null)
 */
function readSnapshot() {
  if (!fs.existsSync(SNAPSHOT_FILE)) return null;
  try {
    return fs.readFileSync(SNAPSHOT_FILE, 'utf8');
  } catch {
    return null;
  }
}

/**
 * 스냅샷 저장 (디렉토리 없으면 생성)
 */
function writeSnapshot(content) {
  mkdirSafe(SNAPSHOTS_DIR);
  writeFileSafe(SNAPSHOT_FILE, content);
}

/**
 * 기본 스냅샷 생성 (내용이 없을 때)
 */
function createDefaultSnapshot(mode = '알 수 없음') {
  const ts = new Date().toISOString();
  return `# AuraKit Snapshot\n- Timestamp: ${ts}\n- Mode: ${mode}\n\n## Status\n자동 저장됨.\n\n## Next Action\n/aura 로 재개\n`;
}

/**
 * 스냅샷 타임스탬프 갱신
 */
function touchSnapshot() {
  const snap = readSnapshot();
  if (!snap) return;
  try {
    const updated = snap.replace(/- Timestamp:.*/, `- Timestamp: ${new Date().toISOString()}`);
    fs.writeFileSync(SNAPSHOT_FILE, updated, 'utf8');
  } catch {}
}

/**
 * 스냅샷에서 필드 파싱
 * @returns {{ mode, request, next }}
 */
function parseSnapshot(snap) {
  if (!snap) return { mode: '알 수 없음', request: '', next: '/aura 로 재개' };
  const modeMatch = snap.match(/- Mode:\s*(.+)/);
  const requestMatch = snap.match(/- Original Request:\s*(.+)/);
  const nextMatch = snap.match(/## Next Action\n([\s\S]+?)(?:\n##|$)/);
  return {
    mode: modeMatch ? modeMatch[1].trim() : '알 수 없음',
    request: requestMatch ? requestMatch[1].trim() : '',
    next: nextMatch ? nextMatch[1].trim() : '/aura 로 재개',
  };
}

module.exports = {
  getSnapshotPath,
  readSnapshot,
  writeSnapshot,
  createDefaultSnapshot,
  touchSnapshot,
  parseSnapshot,
};
