#!/usr/bin/env node
/**
 * AuraKit — PostToolUse Output Filter (Node.js 크로스 플랫폼 버전)
 * Agent 결과에서 성공 시 "Pass" 한 줄만 반환 (Fail-Only Output). matcher: Agent
 */
'use strict';
const { readInput, allow } = require('./lib/common.js');
const input = readInput();
// 이 훅은 관찰 전용 — 차단하지 않음
allow();
