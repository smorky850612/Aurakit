#!/usr/bin/env node
/**
 * AuraKit — Instinct Auto-Save Hook
 * PostToolUse 이벤트: BUILD/FIX 완료 시 성공 패턴 자동 저장
 *
 * 트리거: PostToolUse (tool_name이 "Write" 또는 "Edit"일 때)
 * 설치:  install.sh 실행 시 settings.json PostToolUse에 자동 등록
 */

const fs = require('fs')
const path = require('path')
const readline = require('readline')

// 패턴 저장 기준
const INSTINCT_DIR = path.join(process.cwd(), '.aura', 'instincts')
const INDEX_FILE = path.join(INSTINCT_DIR, 'index.json')
const PATTERNS_DIR = path.join(INSTINCT_DIR, 'patterns')
const ANTI_DIR = path.join(INSTINCT_DIR, 'anti-patterns')

// 보안 패턴 감지 (저장 전 스캔)
const SENSITIVE_PATTERNS = [
  /sk-[a-zA-Z0-9]{20,}/,          // OpenAI API key
  /ghp_[a-zA-Z0-9]{36}/,           // GitHub PAT
  /AKIA[0-9A-Z]{16}/,              // AWS Access Key
  /-----BEGIN.*PRIVATE KEY-----/,  // PEM private key
  /password\s*[:=]\s*['"][^'"]+['"]/i, // hardcoded password
  /secret\s*[:=]\s*['"][^'"]{8,}['"]/i, // hardcoded secret
]

function hasSensitiveData(content) {
  return SENSITIVE_PATTERNS.some(p => p.test(content))
}

// 카테고리 자동 감지 (파일명/내용 기반)
function detectCategory(toolInput) {
  const path_str = (toolInput?.file_path || toolInput?.path || '').toLowerCase()
  const content = (toolInput?.content || toolInput?.new_string || '').toLowerCase()
  const combined = path_str + ' ' + content

  if (/auth|login|signup|jwt|session|password|token/.test(combined)) return 'auth'
  if (/api|route|endpoint|controller|handler/.test(combined)) return 'api'
  if (/db|database|prisma|sql|query|migration|schema/.test(combined)) return 'db'
  if (/component|ui|render|jsx|tsx|style|css/.test(combined)) return 'ui'
  if (/security|csrf|xss|injection|sanitize|validate/.test(combined)) return 'security'
  if (/test|spec|mock|fixture/.test(combined)) return 'test'
  if (/deploy|docker|compose|ci|workflow/.test(combined)) return 'deploy'
  return 'general'
}

// 언어 감지
function detectLanguage(filePath) {
  const ext = path.extname(filePath || '').toLowerCase()
  const map = {
    '.ts': 'typescript', '.tsx': 'typescript',
    '.js': 'javascript', '.jsx': 'javascript',
    '.py': 'python',
    '.go': 'go',
    '.java': 'java',
    '.kt': 'kotlin',
    '.rs': 'rust',
    '.cpp': 'cpp', '.cc': 'cpp', '.cxx': 'cpp',
    '.swift': 'swift',
    '.rb': 'ruby',
  }
  return map[ext] || 'unknown'
}

// 인덱스 로드/생성
function loadIndex() {
  if (!fs.existsSync(INDEX_FILE)) {
    return { version: '1.0', updated: new Date().toISOString(), patterns: [], anti_patterns: [] }
  }
  try {
    return JSON.parse(fs.readFileSync(INDEX_FILE, 'utf8'))
  } catch {
    return { version: '1.0', updated: new Date().toISOString(), patterns: [], anti_patterns: [] }
  }
}

// 유사 패턴 찾기 (태그 기반 Jaccard 유사도)
function findSimilar(index, tags, category) {
  return index.patterns.find(p => {
    if (p.category !== category) return false
    const overlap = tags.filter(t => (p.tags || []).includes(t)).length
    const union = new Set([...tags, ...(p.tags || [])]).size
    return union > 0 && (overlap / union) >= 0.4  // 40% 이상 유사
  })
}

// 성공 패턴 저장
function savePattern(index, toolInput, toolName) {
  const filePath = toolInput?.file_path || toolInput?.path || ''
  const content = toolInput?.content || toolInput?.new_string || ''

  // 민감 데이터 포함 시 저장 안 함
  if (hasSensitiveData(content)) {
    return
  }

  // 너무 짧은 변경은 스킵 (의미 있는 패턴이 아닐 수 있음)
  if (content.length < 50) return

  const category = detectCategory(toolInput)
  const language = detectLanguage(filePath)
  const tags = [category, language].filter(t => t !== 'unknown' && t !== 'general')

  // 콘텐츠에서 추가 태그 추출
  const tagPatterns = {
    jwt: /jwt|jsonwebtoken/i,
    cookie: /httponly|setcookie|cookie/i,
    zod: /z\.(object|string|number)/,
    prisma: /prisma\./,
    'react-query': /useQuery|useMutation|QueryClient/,
    'react-hook-form': /useForm|register|handleSubmit/,
    'next-auth': /getServerSession|signIn|signOut/,
  }
  for (const [tag, pattern] of Object.entries(tagPatterns)) {
    if (pattern.test(content)) tags.push(tag)
  }

  const existing = findSimilar(index, tags, category)
  if (existing) {
    // 기존 패턴 점수 업데이트
    existing.score = Math.min(100, existing.score + 3)
    existing.success_count = (existing.success_count || 0) + 1
    existing.updated = new Date().toISOString()
  } else {
    // 새 패턴 생성
    const dirs = [INSTINCT_DIR, PATTERNS_DIR, ANTI_DIR]
    dirs.forEach(d => { if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true }) })

    const id = `pattern-${String(index.patterns.length + 1).padStart('001', '0').padStart(3, '0')}`
    const patternFile = path.join(PATTERNS_DIR, `${id}.md`)

    // 패턴 파일 생성 (처음 100줄만 저장)
    const snippet = content.split('\n').slice(0, 50).join('\n')
    const patternContent = `---
id: ${id}
category: ${category}
language: ${language}
score: 50
tags: [${tags.join(', ')}]
---

## 컨텍스트
파일: ${path.basename(filePath)} (${toolName} 완료)

## 핵심 코드
\`\`\`${language}
${snippet}
\`\`\`

## 태그
${tags.map(t => `- ${t}`).join('\n')}
`
    try {
      fs.writeFileSync(patternFile, patternContent, 'utf8')
      index.patterns.push({
        id,
        category,
        language,
        description: `${path.basename(filePath)} — ${category} 패턴 (${language})`,
        score: 50,
        success_count: 1,
        failure_count: 0,
        tags,
        created: new Date().toISOString(),
        updated: new Date().toISOString(),
      })
    } catch {
      // 쓰기 실패 시 조용히 무시 (hook 오류가 메인 작업을 방해해선 안 됨)
    }
  }

  // score 기준 정렬 + 100개 제한
  index.patterns.sort((a, b) => b.score - a.score)
  if (index.patterns.length > 100) {
    const removed = index.patterns.splice(80)
    removed.forEach(p => {
      try { fs.unlinkSync(path.join(PATTERNS_DIR, `${p.id}.md`)) } catch {}
    })
  }

  index.updated = new Date().toISOString()
}

// 메인: stdin에서 hook 데이터 읽기
async function main() {
  const rl = readline.createInterface({ input: process.stdin, terminal: false })
  let inputData = ''

  rl.on('line', line => { inputData += line })
  rl.on('close', () => {
    try {
      const hookData = JSON.parse(inputData)
      const toolName = hookData?.tool_name || hookData?.tool || ''
      const toolInput = hookData?.tool_input || hookData?.input || {}

      // Write/Edit 완료 시에만 패턴 저장
      const SAVE_TOOLS = ['Write', 'Edit', 'MultiEdit']
      if (!SAVE_TOOLS.includes(toolName)) return

      // .aura 디렉토리가 있는 프로젝트에서만 동작
      const auraDir = path.join(process.cwd(), '.aura')
      if (!fs.existsSync(auraDir)) return

      const index = loadIndex()
      savePattern(index, toolInput, toolName)

      // 인덱스 저장
      const dirs = [INSTINCT_DIR]
      dirs.forEach(d => { if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true }) })
      fs.writeFileSync(INDEX_FILE, JSON.stringify(index, null, 2), 'utf8')

    } catch {
      // hook 오류는 항상 조용히 처리 — 메인 작업에 영향 없음
    }
  })
}

main().catch(() => {})
