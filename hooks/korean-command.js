#!/usr/bin/env node
/**
 * AuraKit — UserPromptSubmit Korean IME (Node.js 크로스 플랫폼 버전)
 * 두벌식 IME 역변환 + 다국어 명령 매핑
 */
'use strict';
const { readInput, addContext } = require('./lib/common.js');
const input = readInput();
const prompt = (input.prompt || '').trim();
if (!prompt) process.exit(0);

// 두벌식 역변환 맵
const DUBEOLSIK = {
  'ㅂ':'q','ㅈ':'w','ㄷ':'e','ㄱ':'r','ㅅ':'t','ㅛ':'y','ㅕ':'u','ㅑ':'i','ㅐ':'o','ㅔ':'p',
  'ㅁ':'a','ㄴ':'s','ㅇ':'d','ㄹ':'f','ㅎ':'g','ㅗ':'h','ㅓ':'j','ㅏ':'k','ㅣ':'l',
  'ㅋ':'z','ㅌ':'x','ㅊ':'c','ㅍ':'v','ㅠ':'b','ㅜ':'n','ㅡ':'m',
};

// 한국어 AuraKit 명령어 매핑
const KO_CMDS = {
  '/아우라': '/aura',
  '/아우라빌드': '/aura build:',
  '/아우라수정': '/aura fix:',
  '/아우라정리': '/aura clean:',
  '/아우라배포': '/aura deploy:',
  '/아우라리뷰': '/aura review:',
  '/아우라컴팩트': '/aura-compact',
};

// 매핑 먼저 확인
for (const [ko, en] of Object.entries(KO_CMDS)) {
  if (prompt.startsWith(ko)) {
    // 컨텍스트에 정규화된 명령 주입
    addContext(`[AuraKit IME] 명령 감지: ${prompt} → ${en}`);
    break;
  }
}

process.exit(0);
