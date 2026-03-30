# T4 — Component Refactor (250-line split)

## Task
Refactor an oversized React component (350 lines) into atomic components:

```
UserDashboard.tsx (350 lines)
  - Header with user info
  - Stats cards (4 metrics)
  - Recent orders table (with pagination)
  - Activity chart
  - Settings sidebar
```

Requirements:
- Split into components ≤250 lines each
- Extract custom hooks for data fetching
- Maintain identical UI/behavior
- Use TypeScript (no `any`)
- No prop drilling (use context or composition)

Target stack: React 18 + TypeScript + Tailwind CSS

## Measurement
- Token usage: input + output
- Files created: count
- Largest component line count after refactor
- `any` type usage: count (must be 0)
- V1 build pass: yes/no

## Success Criteria
- All components ≤250 lines
- Zero `any` types
- Custom hooks extracted
- Build passes
