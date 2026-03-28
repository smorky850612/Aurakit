#!/usr/bin/env node
/**
 * AuraKit — Instinct Auto-Save Hook
 * PostToolUse 이벤트: BUILD/FIX 완료 시 성공 패턴 + 안티패턴 자동 저장
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
const LOCK_FILE = INDEX_FILE + '.lock'
const PATTERNS_DIR = path.join(INSTINCT_DIR, 'patterns')
const ANTI_DIR = path.join(INSTINCT_DIR, 'anti-patterns')

// 글로벌 Instinct (전체 프로젝트 공유 학습 - ~/.claude/.aura/global-instincts/)
const GLOBAL_BASE = path.join(
  process.env.HOME || process.env.USERPROFILE || require('os').homedir(),
  '.claude', '.aura', 'global-instincts'
)
const GLOBAL_INDEX = path.join(GLOBAL_BASE, 'index.json')
const GLOBAL_LOCK_FILE = GLOBAL_INDEX + '.lock'
const GLOBAL_SCORE_THRESHOLD = 60  // 로컬 score ≥ 60 → 글로벌 승격
const LOCK_MAX_AGE_MS = 10000      // 10초 이상 된 lock은 스테일로 간주

// ─────────────────────────────────────────────────
// Race Condition 방어: 파일 잠금 + 원자적 쓰기
// ─────────────────────────────────────────────────

/**
 * 파일 잠금 획득 시도 (단일 시도, fail-fast)
 * 다른 프로세스가 잠금 중이면 잠금 없이 계속 진행 (best-effort)
 */
function acquireLock(lockPath) {
  try {
    // 스테일 잠금 감지 및 제거
    try {
      const stat = fs.statSync(lockPath)
      if (Date.now() - stat.mtimeMs > LOCK_MAX_AGE_MS) {
        fs.unlinkSync(lockPath)
      } else {
        return false  // 다른 프로세스가 활성 잠금 보유 중
      }
    } catch {
      // 잠금 파일 없음 — 정상 경로
    }
    // O_EXCL 플래그: 파일이 이미 존재하면 예외 발생 (원자적 생성)
    fs.writeFileSync(lockPath, String(process.pid), { flag: 'wx' })
    return true
  } catch {
    return false
  }
}

function releaseLock(lockPath) {
  try { fs.unlinkSync(lockPath) } catch {}
}

/**
 * 원자적 파일 쓰기: temp 파일에 먼저 쓰고 rename
 * rename은 대부분 OS에서 원자적 연산 (파일 중간 상태 없음)
 */
function writeAtomic(filePath, content) {
  const tmp = filePath + '.tmp.' + process.pid
  try {
    fs.writeFileSync(tmp, content, 'utf8')
    fs.renameSync(tmp, filePath)
  } catch (e) {
    try { fs.unlinkSync(tmp) } catch {}
    throw e
  }
}

/**
 * 잠금 보호 하에 fn() 실행
 * 잠금 획득 실패 시 잠금 없이 실행 (데이터 손실 가능하지만 데드락 없음)
 */
function withLock(lockPath, fn) {
  const acquired = acquireLock(lockPath)
  try {
    fn()
  } finally {
    if (acquired) releaseLock(lockPath)
  }
}

// ─────────────────────────────────────────────────
// 보안 패턴 감지 (민감 데이터 — 저장 전 스캔)
// ─────────────────────────────────────────────────

const SENSITIVE_PATTERNS = [
  /sk-[a-zA-Z0-9]{20,}/,
  /ghp_[a-zA-Z0-9]{36}/,
  /AKIA[0-9A-Z]{16}/,
  /-----BEGIN.*PRIVATE KEY-----/,
  /password\s*[:=]\s*['"][^'"]+['"]/i,
  /secret\s*[:=]\s*['"][^'"]{8,}['"]/i,
]

function hasSensitiveData(content) {
  return SENSITIVE_PATTERNS.some(p => p.test(content))
}

// ─────────────────────────────────────────────────
// 안티패턴 감지 규칙 (Edit.old_string 기반)
// ─────────────────────────────────────────────────

const CODE_ANTI_PATTERNS = [
  {
    id: 'jwt-localstorage',
    pattern: /localStorage\.(setItem|getItem)\s*\(\s*['"](?:token|jwt|auth|access_token)['"]/i,
    description: 'JWT/Token을 localStorage에 저장 — XSS에 취약. httpOnly Cookie 사용 권장.',
    category: 'auth',
    tags: ['jwt', 'localStorage', 'xss', 'auth'],
  },
  {
    id: 'sql-string-concat',
    pattern: /(?:query|sql)\s*[=+]\s*[`'"].*\$\{|[`'"]\s*\+\s*(?:req\.|user\.|params\.|body\.|input)/i,
    description: 'SQL 문자열 직접 연결 — SQL Injection 위험. Parameterized query / ORM 사용.',
    category: 'db',
    tags: ['sql', 'injection', 'security', 'db'],
  },
  {
    id: 'eval-user-input',
    pattern: /eval\s*\(\s*(?:req\b|user\b|input\b|data\b|body\b|params\b)/i,
    description: 'eval()에 사용자 입력 전달 — RCE(원격 코드 실행) 위험. eval() 사용 금지.',
    category: 'security',
    tags: ['eval', 'rce', 'security'],
  },
  {
    id: 'math-random-security',
    pattern: /Math\.random\(\)\s*[\*\+]?\s*(?:\d{4,}|Date\.now|token|secret|id)/i,
    description: 'Math.random()을 보안 목적으로 사용 — 예측 가능. crypto.randomBytes() 사용.',
    category: 'security',
    tags: ['random', 'crypto', 'security'],
  },
  {
    id: 'http-external',
    pattern: /fetch\s*\(\s*['"`]http:\/\/(?!localhost|127\.0\.0\.1|0\.0\.0\.0)/i,
    description: '외부 API를 HTTP(비암호화)로 호출 — 중간자 공격 위험. HTTPS 사용 필수.',
    category: 'security',
    tags: ['http', 'https', 'security'],
  },
  {
    id: 'any-type-abuse',
    pattern: /:\s*any(?:\[\])?\s*[=;,)]/,
    description: 'TypeScript any 타입 남용 — 타입 안전성 파괴. unknown + type guard 사용.',
    category: 'ui',
    tags: ['typescript', 'any', 'types'],
  },
  {
    id: 'plain-password-store',
    pattern: /(?:user\.password|password)\s*=\s*(?:req\.|body\.|input\.)[\w.]*(?:password|pw|pass)/i,
    description: '비밀번호 평문 저장 — 보안 사고 위험. bcrypt/argon2 해시 필수.',
    category: 'auth',
    tags: ['password', 'bcrypt', 'auth', 'security'],
  },
]

// ─────────────────────────────────────────────────
// 카테고리/언어 감지
// ─────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────
// 인덱스 로드/저장
// ─────────────────────────────────────────────────

function loadIndex() {
  if (!fs.existsSync(INDEX_FILE)) {
    return { version: '1.0', updated: new Date().toISOString(), patterns: [], anti_patterns: [] }
  }
  try {
    const data = JSON.parse(fs.readFileSync(INDEX_FILE, 'utf8'))
    // anti_patterns 필드 없는 구버전 인덱스 호환성
    if (!data.anti_patterns) data.anti_patterns = []
    return data
  } catch {
    return { version: '1.0', updated: new Date().toISOString(), patterns: [], anti_patterns: [] }
  }
}

// 유사 성공 패턴 탐색 (Jaccard 유사도 ≥ 40%)
function findSimilar(index, tags, category) {
  return index.patterns.find(p => {
    if (p.category !== category) return false
    const overlap = tags.filter(t => (p.tags || []).includes(t)).length
    const union = new Set([...tags, ...(p.tags || [])]).size
    return union > 0 && (overlap / union) >= 0.4
  })
}

// 유사 안티패턴 탐색 (id 기반 정확 매칭)
function findSimilarAnti(index, antiId) {
  return index.anti_patterns.find(p => p.id === antiId)
}

// ─────────────────────────────────────────────────
// 안티패턴 저장
// ─────────────────────────────────────────────────

/**
 * Edit 도구의 old_string에서 안티패턴 감지
 * old_string에 나쁜 패턴이 있고 new_string에 없으면 → 수정된 것이므로 안티패턴으로 저장
 */
function detectAndSaveAntiPattern(index, toolInput, toolName) {
  if (toolName !== 'Edit') return  // Write는 old_string 없음

  const oldCode = toolInput?.old_string || ''
  const newCode = toolInput?.new_string || ''
  const filePath = toolInput?.file_path || ''
  const language = detectLanguage(filePath)

  if (oldCode.length < 10) return

  for (const rule of CODE_ANTI_PATTERNS) {
    const inOld = rule.pattern.test(oldCode)
    const inNew = rule.pattern.test(newCode)

    // old에 있고 new에 없으면 → 이 코드가 나쁜 코드였음 (수정됨)
    if (!inOld || inNew) continue

    const antiId = `anti-${rule.id}`
    const existing = findSimilarAnti(index, antiId)
    if (existing) {
      existing.occurrence_count = (existing.occurrence_count || 1) + 1
      existing.updated = new Date().toISOString()
    } else {
      const dirs = [INSTINCT_DIR, ANTI_DIR]
      dirs.forEach(d => { if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true }) })

      const antiFile = path.join(ANTI_DIR, `${antiId}.md`)

      // 안티패턴 코드 샘플 저장 (50자 제한, 민감정보 제거)
      const sample = oldCode.slice(0, 200).replace(/['"][^'"]{20,}['"]/g, '"[REDACTED]"')

      try {
        fs.writeFileSync(antiFile, [
          `---`,
          `id: ${antiId}`,
          `rule: ${rule.id}`,
          `category: ${rule.category}`,
          `language: ${language}`,
          `tags: [${rule.tags.join(', ')}]`,
          `---`,
          ``,
          `## 안티패턴: ${rule.description}`,
          ``,
          `### 발견된 코드 샘플`,
          `\`\`\`${language}`,
          sample,
          `\`\`\``,
          ``,
          `### 왜 나쁜가`,
          rule.description,
          ``,
          `### 올바른 대안`,
          `위 패턴을 발견하면 즉시 수정 필요 (security-scan.js가 차단함)`,
        ].join('\n'), 'utf8')

        index.anti_patterns.push({
          id: antiId,
          rule: rule.id,
          category: rule.category,
          language,
          description: rule.description,
          tags: rule.tags,
          occurrence_count: 1,
          created: new Date().toISOString(),
          updated: new Date().toISOString(),
        })
      } catch {
        // 쓰기 실패 무시
      }
    }
  }
}

// ─────────────────────────────────────────────────
// 성공 패턴 저장
// ─────────────────────────────────────────────────

function savePattern(index, toolInput, toolName) {
  const filePath = toolInput?.file_path || toolInput?.path || ''
  const content = toolInput?.content || toolInput?.new_string || ''

  if (hasSensitiveData(content)) return
  if (content.length < 50) return

  const category = detectCategory(toolInput)
  const language = detectLanguage(filePath)
  const tags = [category, language].filter(t => t !== 'unknown' && t !== 'general')

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
    existing.score = Math.min(100, existing.score + 3)
    existing.success_count = (existing.success_count || 0) + 1
    existing.updated = new Date().toISOString()
    // score ≥ 60 → 글로벌 승격 (저장된 패턴 파일 내용 사용)
    if (existing.score >= GLOBAL_SCORE_THRESHOLD) {
      try {
        const patternFile = path.join(PATTERNS_DIR, `${existing.id}.md`)
        const storedContent = fs.existsSync(patternFile)
          ? fs.readFileSync(patternFile, 'utf8')
          : content
        promoteToGlobal(existing, storedContent)
      } catch {
        promoteToGlobal(existing, content)
      }
    }
  } else {
    const dirs = [INSTINCT_DIR, PATTERNS_DIR, ANTI_DIR]
    dirs.forEach(d => { if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true }) })

    const nextNum = index.patterns.reduce((max, p) => {
      const m = p.id.match(/pattern-(\d+)/)
      return m ? Math.max(max, parseInt(m[1], 10)) : max
    }, 0) + 1
    const id = `pattern-${String(nextNum).padStart(3, '0')}`
    const patternFile = path.join(PATTERNS_DIR, `${id}.md`)
    const snippet = content.split('\n').slice(0, 50).join('\n')

    try {
      writeAtomic(patternFile, [
        `---`,
        `id: ${id}`,
        `category: ${category}`,
        `language: ${language}`,
        `score: 50`,
        `tags: [${tags.join(', ')}]`,
        `---`,
        ``,
        `## 컨텍스트`,
        `파일: ${path.basename(filePath)} (${toolName} 완료)`,
        ``,
        `## 핵심 코드`,
        `\`\`\`${language}`,
        snippet,
        `\`\`\``,
        ``,
        `## 태그`,
        tags.map(t => `- ${t}`).join('\n'),
      ].join('\n'))

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
      // 쓰기 실패 무시
    }
  }

  index.patterns.sort((a, b) => b.score - a.score)
  if (index.patterns.length > 100) {
    const removed = index.patterns.splice(80)
    removed.forEach(p => {
      try { fs.unlinkSync(path.join(PATTERNS_DIR, `${p.id}.md`)) } catch {}
    })
  }

  index.updated = new Date().toISOString()
}

// ─────────────────────────────────────────────────
// 글로벌 승격
// ─────────────────────────────────────────────────

function sanitizeForGlobal(content) {
  return content
    .replace(/\/[A-Za-z0-9_\-/.]+\.(ts|tsx|js|jsx|py|go|java|rs|rb|kt|swift|cpp)/g, '[file]')
    .replace(/[A-Z]:\\[A-Za-z0-9_\-\\.]+/g, '[path]')
    .replace(/https?:\/\/[^\s'"]+/g, '[url]')
    .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '[uuid]')
}

function loadGlobalIndex() {
  if (!fs.existsSync(GLOBAL_INDEX)) {
    return { version: '1.0', updated: new Date().toISOString(), patterns: [] }
  }
  try {
    return JSON.parse(fs.readFileSync(GLOBAL_INDEX, 'utf8'))
  } catch {
    return { version: '1.0', updated: new Date().toISOString(), patterns: [] }
  }
}

function promoteToGlobal(pattern, content) {
  try {
    const sanitized = sanitizeForGlobal(content)
    if (hasSensitiveData(sanitized)) return
    if (sanitized.length < 50) return

    const lang = pattern.language || 'general'
    const globalLangDir = path.join(GLOBAL_BASE, lang)
    if (!fs.existsSync(globalLangDir)) fs.mkdirSync(globalLangDir, { recursive: true })

    withLock(GLOBAL_LOCK_FILE, () => {
      const globalIndex = loadGlobalIndex()
      const existingGlobal = findSimilar(globalIndex, pattern.tags || [], pattern.category)

      if (existingGlobal) {
        existingGlobal.score = Math.min(100, existingGlobal.score + 1)
        existingGlobal.project_count = (existingGlobal.project_count || 1) + 1
        existingGlobal.updated = new Date().toISOString()
      } else {
        const nextGNum = globalIndex.patterns.reduce((max, p) => {
          const m = p.id.match(/g-\w+-(\d+)/)
          return m ? Math.max(max, parseInt(m[1], 10)) : max
        }, 0) + 1
        const gid = `g-${lang}-${String(nextGNum).padStart(4, '0')}`
        const snippet = sanitized.split('\n').slice(0, 40).join('\n')

        writeAtomic(path.join(globalLangDir, `${gid}.md`), [
          `---`,
          `id: ${gid}`,
          `category: ${pattern.category}`,
          `language: ${lang}`,
          `score: 30`,
          `tags: [${(pattern.tags || []).join(', ')}]`,
          `project_count: 1`,
          `---`,
          ``,
          `## 글로벌 패턴 (${lang} · ${pattern.category})`,
          ``,
          `\`\`\`${lang}`,
          snippet,
          `\`\`\``,
          ``,
          `## 태그`,
          (pattern.tags || []).map(t => `- ${t}`).join('\n'),
        ].join('\n'))

        globalIndex.patterns.push({
          id: gid,
          category: pattern.category,
          language: lang,
          description: `글로벌 패턴 — ${pattern.category} (${lang})`,
          score: 30,
          project_count: 1,
          tags: pattern.tags || [],
          created: new Date().toISOString(),
          updated: new Date().toISOString(),
        })
      }

      globalIndex.patterns.sort((a, b) => b.score - a.score)
      if (globalIndex.patterns.length > 500) globalIndex.patterns.splice(400)
      globalIndex.updated = new Date().toISOString()
      writeAtomic(GLOBAL_INDEX, JSON.stringify(globalIndex, null, 2))
    })
  } catch {
    // 글로벌 저장 실패는 항상 조용히 무시
  }
}

// ─────────────────────────────────────────────────
// 메인
// ─────────────────────────────────────────────────

async function main() {
  const rl = readline.createInterface({ input: process.stdin, terminal: false })
  let inputData = ''

  rl.on('line', line => { inputData += line })
  rl.on('close', () => {
    try {
      const hookData = JSON.parse(inputData)
      const toolName = hookData?.tool_name || hookData?.tool || ''
      const toolInput = hookData?.tool_input || hookData?.input || {}

      const SAVE_TOOLS = ['Write', 'Edit', 'MultiEdit']
      if (!SAVE_TOOLS.includes(toolName)) return

      const auraDir = path.join(process.cwd(), '.aura')
      if (!fs.existsSync(auraDir)) return

      withLock(LOCK_FILE, () => {
        const index = loadIndex()

        // 안티패턴 감지 (Edit의 old_string 분석)
        detectAndSaveAntiPattern(index, toolInput, toolName)

        // 성공 패턴 저장
        savePattern(index, toolInput, toolName)

        // 인덱스 원자적 저장
        if (!fs.existsSync(INSTINCT_DIR)) fs.mkdirSync(INSTINCT_DIR, { recursive: true })
        writeAtomic(INDEX_FILE, JSON.stringify(index, null, 2))
      })

    } catch {
      // hook 오류는 항상 조용히 처리
    }
  })
}

main().catch(() => {})
