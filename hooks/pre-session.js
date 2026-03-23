#!/usr/bin/env node
/**
 * AuraKit — SessionStart Hook (Node.js 크로스 플랫폼 버전)
 * 세션 시작 시 프로젝트 환경 초기화 및 상태 확인
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { readInput, mkdirSafe, fileExists, dirExists, readFileSafe, AURA_DIR, SNAPSHOTS_DIR } = require('./lib/common.js');

readInput(); // stdin consume (required by hook protocol)

const profileFile = path.join(AURA_DIR, 'project-profile.md');
const snapshotFile = path.join(SNAPSHOTS_DIR, 'current.md');
const messages = [];

// ── 1. .aura/ 디렉토리 초기화 ─────────────────────────────────────────
if (!dirExists(AURA_DIR)) {
  mkdirSafe(SNAPSHOTS_DIR);
  messages.push('AuraKit: .aura/ 디렉토리를 초기화했습니다.');
}
if (!dirExists(SNAPSHOTS_DIR)) {
  mkdirSafe(SNAPSHOTS_DIR);
}

// ── 2. .env 보안 검사 ─────────────────────────────────────────────────
let envIssue = false;
if (fileExists('.env')) {
  if (fileExists('.gitignore')) {
    const gitignore = readFileSafe('.gitignore');
    if (!/^\.env$|^\.env\b/m.test(gitignore)) {
      messages.push('⚠️  AuraKit Security L1: .env 파일이 .gitignore에 없습니다.');
      messages.push('   즉시 .gitignore에 .env를 추가하세요:');
      messages.push("   echo '.env' >> .gitignore");
      envIssue = true;
    }
  } else {
    messages.push('⚠️  AuraKit Security L1: .gitignore 파일이 없습니다.');
    messages.push('   .gitignore를 생성하고 .env를 추가하세요.');
    envIssue = true;
  }
}

// ── 3. 프로젝트 프로필 확인 ───────────────────────────────────────────
if (!fileExists(profileFile)) {
  messages.push('📋 AuraKit: 프로젝트 프로필이 없습니다.');
  messages.push('   /aura 실행 시 Scout 에이전트가 자동으로 프로젝트를 스캔합니다.');
  messages.push('   (첫 실행에만 필요, 이후 캐시 사용)');
} else {
  // 프로필에서 레벨 읽기
  const profile = readFileSafe(profileFile);
  const levelMatch = profile.match(/Level:\s*(Starter|Dynamic|Enterprise)/i);
  if (levelMatch) {
    // 조용히 통과 (레벨 감지 성공)
  }
}

// ── 4. 스냅샷 복구 확인 ───────────────────────────────────────────────
if (fileExists(snapshotFile)) {
  const snapshot = readFileSafe(snapshotFile);
  const modeMatch = snapshot.match(/- Mode:\s*(.+)/);
  const requestMatch = snapshot.match(/- Original Request:\s*(.+)/);
  if (modeMatch || requestMatch) {
    const mode = modeMatch ? modeMatch[1].trim() : '알 수 없음';
    const req = requestMatch ? requestMatch[1].trim().substring(0, 50) : '';
    messages.push('\n🔄 AuraKit: 이전 작업 스냅샷이 발견되었습니다.');
    messages.push(`   모드: ${mode}`);
    if (req) messages.push(`   요청: ${req} ...`);
    messages.push('   /aura 실행 시 자동으로 이어서 작업합니다.');
  }
}

// ── 5. 출력 ──────────────────────────────────────────────────────────
if (messages.length > 0) {
  process.stdout.write(JSON.stringify({
    continue: true,
    additionalContext: messages.join('\n')
  }));
}

process.exit(0);
