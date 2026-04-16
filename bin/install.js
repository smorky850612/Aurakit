#!/usr/bin/env node
'use strict';

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE;
const SKILLS_DIR = path.join(HOME, '.claude', 'skills');
const AURA_SKILL = path.join(SKILLS_DIR, 'aura');
const AURAKIT_DIR = path.join(SKILLS_DIR, 'aurakit');
const HOOKS_DIR = path.join(AURAKIT_DIR, 'hooks');
const SRC = path.resolve(__dirname, '..');

const log = (m) => console.log(`  \x1b[36m[AuraKit]\x1b[0m ${m}`);
const ok = (m) => console.log(`  \x1b[32m✓\x1b[0m ${m}`);
const warn = (m) => console.log(`  \x1b[33m!\x1b[0m ${m}`);

console.log('');
log('Installing AuraKit v6.5...');
console.log('');

// 0. 기존 settings.json 수리 (v6.5.2 이하 잘못된 hooks 형식 마이그레이션)
try {
  const settingsPath = path.join(HOME, '.claude', 'settings.json');
  if (fs.existsSync(settingsPath)) {
    const { repairHooks } = require('./repair.js');
    const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
    const { repaired, count } = repairHooks(settings);
    if (repaired) {
      fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2), 'utf8');
      ok(`Repaired ${count} hook entries (legacy format → matcher+hooks)`);
    }
  }
} catch (e) { /* repair is best-effort */ }

// 1. skills/aura/ → ~/.claude/skills/aura/
try {
  const src = path.join(SRC, 'skills', 'aura');
  if (fs.existsSync(src)) {
    fs.cpSync(src, AURA_SKILL, { recursive: true });
    ok('SKILL.md + resources installed');
  } else {
    warn('skills/aura/ not found.');
  }
} catch (e) { warn('Skill copy failed: ' + e.message); }

// 2. hooks/ → ~/.claude/skills/aurakit/hooks/
try {
  const src = path.join(SRC, 'hooks');
  if (fs.existsSync(src)) {
    fs.mkdirSync(path.join(HOOKS_DIR, 'lib'), { recursive: true });
    fs.cpSync(src, HOOKS_DIR, { recursive: true });
    ok('16 hooks + lib installed');
  }
} catch (e) { warn('Hook copy failed: ' + e.message); }

// 2.5. bin/ → ~/.claude/skills/aurakit/bin/ (repair.js 등)
try {
  const src = path.join(SRC, 'bin');
  if (fs.existsSync(src)) {
    const dest = path.join(AURAKIT_DIR, 'bin');
    fs.mkdirSync(dest, { recursive: true });
    fs.cpSync(src, dest, { recursive: true });
    ok('bin/ tools installed (repair, install)');
  }
} catch (e) { /* optional */ }

// 3. agents/ → ~/.claude/skills/aurakit/agents/
try {
  const src = path.join(SRC, 'agents');
  if (fs.existsSync(src)) {
    const dest = path.join(AURAKIT_DIR, 'agents');
    fs.mkdirSync(dest, { recursive: true });
    fs.cpSync(src, dest, { recursive: true });
    ok('Agents installed');
  }
} catch (e) { /* optional */ }

// 4. rules/ → ~/.claude/rules/
try {
  const src = path.join(SRC, 'rules');
  const dest = path.join(HOME, '.claude', 'rules');
  if (fs.existsSync(src)) {
    fs.mkdirSync(dest, { recursive: true });
    fs.cpSync(src, dest, { recursive: true });
    ok('Security rules (always-active) installed');
  }
} catch (e) { warn('Rule copy failed: ' + e.message); }

// 5. templates/ → ~/.claude/skills/aurakit/templates/
try {
  const src = path.join(SRC, 'templates');
  if (fs.existsSync(src)) {
    const dest = path.join(AURAKIT_DIR, 'templates');
    fs.mkdirSync(dest, { recursive: true });
    fs.cpSync(src, dest, { recursive: true });
    ok('Templates installed');
  }
} catch (e) { /* optional */ }

// 6. install.sh (settings.json hook registration — --auto: skip claude check + quiet)
try {
  const sh = path.join(SRC, 'install.sh');
  if (fs.existsSync(sh)) {
    // Windows에서 bash는 POSIX 경로가 필요: C:\... → /c/...
    let shBashPath = sh;
    if (process.platform === 'win32') {
      shBashPath = sh.replace(/\\/g, '/').replace(/^([A-Za-z]):/, (_, d) => `/${d.toLowerCase()}`);
    }
    execSync(`bash "${shBashPath}" --auto`, { stdio: 'inherit' });
  }
} catch (e) {
  warn('settings.json hook registration failed. Manual: bash install.sh');
}

console.log('');
log('══════════════════════════════════════');
log('  AuraKit v6.5 installed!');
log('');
log('  Usage:');
log('    /aura build: login with JWT');
log('    /aura fix: TypeError in auth.ts');
log('    /aura review:');
log('    /aura! change button color');
log('    /aura pro payment system');
log('');
log('  46 modes · 23 agents · 6-layer security · 10 hooks · ~55% token savings');
log('══════════════════════════════════════');
console.log('');
