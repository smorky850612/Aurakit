#!/usr/bin/env node
/**
 * AuraKit — UserPromptSubmit Hook
 * 1. 사용자 언어 자동 감지 → ~/.claude/.aura-lang 저장
 * 2. 두벌식 IME 역변환 + 다국어 명령 매핑
 */
'use strict';
const fs = require('fs');
const path = require('path');
const { readInput, addContext, HOME } = require('./lib/common.js');

const input = readInput();
const prompt = (input.prompt || '').trim();
if (!prompt) process.exit(0);

// ── 언어 감지 ────────────────────────────────────────────────────────
const LANG_FILE = path.join(HOME, '.claude', '.aura-lang');

function detectLang(text) {
  const ko = (text.match(/[\uAC00-\uD7A3\u3130-\u318F]/g) || []).length;
  const ja = (text.match(/[\u3040-\u30FF]/g) || []).length;
  const zh = (text.match(/[\u4E00-\u9FFF]/g) || []).length;

  // CJK 문자가 하나라도 있으면 CJK 언어 판단
  if (ko + ja + zh > 0) {
    if (ko >= ja && ko >= zh) return 'ko';
    if (ja >= zh) return 'ja';
    return 'zh';
  }

  // 라틴계 언어 단어 패턴 감지
  if (/\b(qué|cómo|dónde|por favor|hacer|añadir|es|está)\b/i.test(text)) return 'es';
  if (/\b(comment|qu[ei]|s['']il vous|créer|ajouter|voici|bonjour)\b/i.test(text)) return 'fr';
  if (/\b(wie|warum|bitte|danke|machen|erstellen|hinzufügen|ich|Sie)\b/i.test(text)) return 'de';
  if (/\b(come|dove|perché|per favore|fare|aggiungere|ciao|grazie)\b/i.test(text)) return 'it';

  return 'en';
}

// 언어 감지 후 저장 (짧은 입력은 건너뜀 — 오탐 방지)
if (prompt.length >= 2) {
  try {
    const lang = detectLang(prompt);
    fs.writeFileSync(LANG_FILE, lang, 'utf8');
  } catch (_) {
    // 실패해도 진행
  }
}

// ── 두벌식 역변환 맵 ─────────────────────────────────────────────────
const DUBEOLSIK = {
  'ㅂ':'q','ㅈ':'w','ㄷ':'e','ㄱ':'r','ㅅ':'t','ㅛ':'y','ㅕ':'u','ㅑ':'i','ㅐ':'o','ㅔ':'p',
  'ㅁ':'a','ㄴ':'s','ㅇ':'d','ㄹ':'f','ㅎ':'g','ㅗ':'h','ㅓ':'j','ㅏ':'k','ㅣ':'l',
  'ㅋ':'z','ㅌ':'x','ㅊ':'c','ㅍ':'v','ㅠ':'b','ㅜ':'n','ㅡ':'m',
};

// ── 한국어 AuraKit 명령어 매핑 ────────────────────────────────────────
const KO_CMDS = {
  '/아우라': '/aura',
  '/아우라빌드': '/aura build:',
  '/아우라수정': '/aura fix:',
  '/아우라정리': '/aura clean:',
  '/아우라배포': '/aura deploy:',
  '/아우라리뷰': '/aura review:',
  '/아우라컴팩트': '/aura-compact',
};

// 매핑 확인 — 매칭되면 컨텍스트 주입 후 종료
for (const [ko, en] of Object.entries(KO_CMDS)) {
  if (prompt.startsWith(ko)) {
    addContext(`[AuraKit IME] 명령 감지: ${prompt} → ${en}`);
    // addContext 내부에서 process.exit(0) 호출됨
  }
}

process.exit(0);
