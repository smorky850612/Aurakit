#!/usr/bin/env node
/**
 * AuraKit — Task Completed Hook (PostToolUse:Write|Edit) G3
 * 파일 작성 완료 시 .aura/snapshots/current.md 태스크를 자동 완료 처리
 */
'use strict';

const path = require('path');
const { readInput, allow, fileExists, readFileSafe, writeFileSafe, SNAPSHOTS_DIR } = require('./lib/common.js');

const input = readInput();
const toolInput = input.tool_input || {};
const toolResult = input.tool_response || '';

const filePath = toolInput.file_path || '';
if (!filePath) allow();

const resultStr = typeof toolResult === 'string' ? toolResult : JSON.stringify(toolResult);
const isSuccess = /success|created|updated/i.test(resultStr);
if (!isSuccess) allow();

const snapshotFile = path.join(SNAPSHOTS_DIR, 'current.md');
if (!fileExists(snapshotFile)) allow();

const snapshot = readFileSafe(snapshotFile);
const fileName = path.basename(filePath);

// [ ] filename → [x] filename 자동 체크
const escaped = fileName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const pattern = new RegExp('\\[ \\] .*' + escaped + '.*', 'g');
const updated = snapshot.replace(pattern, (match) => match.replace('[ ]', '[x]'));

if (updated !== snapshot) writeFileSafe(snapshotFile, updated);
allow();
