# Contributing to AuraKit

Thanks for your interest in AuraKit! Whether you're fixing a typo or adding a new language reviewer, every contribution helps.

## Quick Start

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/Aurakit.git
cd Aurakit

# 2. Create a branch
git checkout -b feat/your-feature

# 3. Make changes, then validate
node -c hooks/*.js            # Syntax check all hooks

# 4. Commit and PR
git commit -m "feat(scope): your description"
```

## What You Can Contribute

### 1. Language Reviewers (Most Needed!)

Path: `resources/reviewers/[language].md`

**Checklist:**
- [ ] Unique prefix (existing: TS/PY/GO/JV/RS/KT/CPP/SW/PHP/PL)
- [ ] Exactly 10 rules (XX-01 ~ XX-10)
- [ ] 5 checklist items
- [ ] V1 build command included
- [ ] Reference added to `build-rules.md`

**Wanted:** C#, Ruby, Scala, Elixir, Dart, Zig, Haskell

### 2. Framework Patterns

Path: `resources/frameworks/[framework].md`

**Wanted:** SvelteKit, Remix, Astro, SolidJS, Hono, Elysia

### 3. Hooks

Path: `hooks/[name].js` — Must include error handling and graceful exit on empty stdin.

### 4. Security Rules

SEC-16+ with OWASP/CWE mapping. No overlap with SEC-01~15.

### 5. Translations & Documentation

Fix typos, add examples, write tutorials.

## Commit Convention

```
feat(reviewer): add C# reviewer
feat(framework): add SvelteKit patterns
feat(hook): add dependency-audit hook
fix(hook): resolve security-scan false positive
docs(readme): add usage examples
```

## Need Help?

Open an [issue](https://github.com/smorky850612/Aurakit/issues) with the `question` or `help wanted` tag.
