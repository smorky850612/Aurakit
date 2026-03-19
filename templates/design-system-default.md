# AuraKit Design System — Default Tokens
# Scout가 tailwind.config에서 커스텀 토큰을 추출하지 못할 때 사용하는 기본값.
# 프로젝트의 실제 디자인 토큰으로 교체하세요.

---

## Colors (CSS Custom Properties)

```css
:root {
  /* Brand */
  --color-primary: #2563eb;       /* blue-600 */
  --color-primary-dark: #1d4ed8;  /* blue-700 (hover) */
  --color-primary-light: #dbeafe; /* blue-100 (bg) */

  --color-secondary: #7c3aed;       /* violet-600 */
  --color-secondary-dark: #6d28d9;  /* violet-700 */
  --color-secondary-light: #ede9fe; /* violet-100 */

  /* Semantic */
  --color-success: #16a34a;       /* green-600 */
  --color-success-light: #dcfce7; /* green-100 */
  --color-warning: #d97706;       /* amber-600 */
  --color-warning-light: #fef3c7; /* amber-100 */
  --color-error: #dc2626;         /* red-600 */
  --color-error-light: #fee2e2;   /* red-100 */
  --color-info: #0284c7;          /* sky-600 */
  --color-info-light: #e0f2fe;    /* sky-100 */

  /* Neutral */
  --color-bg: #ffffff;
  --color-surface: #f9fafb;       /* gray-50 */
  --color-surface-2: #f3f4f6;     /* gray-100 */
  --color-text: #111827;          /* gray-900 */
  --color-text-secondary: #374151;/* gray-700 */
  --color-muted: #6b7280;         /* gray-500 */
  --color-placeholder: #9ca3af;   /* gray-400 */
  --color-border: #e5e7eb;        /* gray-200 */
  --color-border-focus: #2563eb;  /* blue-600 */
  --color-divider: #f3f4f6;       /* gray-100 */
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #0f172a;          /* slate-900 */
    --color-surface: #1e293b;     /* slate-800 */
    --color-surface-2: #334155;   /* slate-700 */
    --color-text: #f1f5f9;        /* slate-100 */
    --color-text-secondary: #cbd5e1; /* slate-300 */
    --color-muted: #94a3b8;       /* slate-400 */
    --color-border: #334155;      /* slate-700 */
    --color-divider: #1e293b;     /* slate-800 */
  }
}
```

---

## Typography

```css
:root {
  /* Font families */
  --font-sans: 'Inter', system-ui, -apple-system, BlinkMacSystemFont,
               'Segoe UI', Roboto, sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', 'Cascadia Code',
               'Consolas', monospace;
  --font-serif: 'Georgia', 'Cambria', serif;

  /* Font sizes */
  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.125rem;   /* 18px */
  --text-xl: 1.25rem;    /* 20px */
  --text-2xl: 1.5rem;    /* 24px */
  --text-3xl: 1.875rem;  /* 30px */
  --text-4xl: 2.25rem;   /* 36px */
  --text-5xl: 3rem;      /* 48px */

  /* Line heights */
  --leading-tight: 1.25;
  --leading-snug: 1.375;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;
  --leading-loose: 2;

  /* Font weights */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
  --font-extrabold: 800;
}
```

---

## Spacing (4px 기준 시스템)

```css
:root {
  --space-0: 0px;
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-5: 1.25rem;  /* 20px */
  --space-6: 1.5rem;   /* 24px */
  --space-7: 1.75rem;  /* 28px */
  --space-8: 2rem;     /* 32px */
  --space-9: 2.25rem;  /* 36px */
  --space-10: 2.5rem;  /* 40px */
  --space-11: 2.75rem; /* 44px */
  --space-12: 3rem;    /* 48px */
  --space-14: 3.5rem;  /* 56px */
  --space-16: 4rem;    /* 64px */
  --space-20: 5rem;    /* 80px */
  --space-24: 6rem;    /* 96px */
  --space-32: 8rem;    /* 128px */
}
```

---

## Border Radius

```css
:root {
  --radius-none: 0px;
  --radius-sm: 0.25rem;   /* 4px */
  --radius-md: 0.5rem;    /* 8px */
  --radius-lg: 0.75rem;   /* 12px */
  --radius-xl: 1rem;      /* 16px */
  --radius-2xl: 1.5rem;   /* 24px */
  --radius-3xl: 2rem;     /* 32px */
  --radius-full: 9999px;
}
```

---

## Shadows

```css
:root {
  --shadow-xs: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-sm: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1);
  --shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  --shadow-inner: inset 0 2px 4px 0 rgba(0, 0, 0, 0.05);
  --shadow-none: none;

  /* Colored shadows */
  --shadow-primary: 0 4px 14px 0 rgba(37, 99, 235, 0.3);
  --shadow-error: 0 4px 14px 0 rgba(220, 38, 38, 0.3);
}
```

---

## Transitions

```css
:root {
  --transition-fast: 100ms ease;
  --transition-base: 200ms ease;
  --transition-slow: 300ms ease;
  --transition-slower: 500ms ease;
}
```

---

## Z-Index 계층

```css
:root {
  --z-below: -1;
  --z-base: 0;
  --z-raised: 10;
  --z-dropdown: 100;
  --z-sticky: 200;
  --z-overlay: 300;
  --z-modal: 400;
  --z-popover: 500;
  --z-toast: 600;
  --z-tooltip: 700;
}
```

---

## 기본 컴포넌트 스타일

### 버튼

```css
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-4);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  transition: all var(--transition-base);
  cursor: pointer;
  border: 1px solid transparent;
}

.btn-primary {
  background-color: var(--color-primary);
  color: #ffffff;
}
.btn-primary:hover { background-color: var(--color-primary-dark); }

.btn-outline {
  background-color: transparent;
  border-color: var(--color-border);
  color: var(--color-text);
}
.btn-outline:hover { background-color: var(--color-surface); }

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

### 입력

```css
.input {
  width: 100%;
  padding: var(--space-2) var(--space-3);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
  background-color: var(--color-bg);
  color: var(--color-text);
  transition: border-color var(--transition-fast);
}

.input:focus {
  outline: none;
  border-color: var(--color-border-focus);
  box-shadow: 0 0 0 3px var(--color-primary-light);
}

.input::placeholder { color: var(--color-placeholder); }
.input:disabled { opacity: 0.5; cursor: not-allowed; }
```

### 카드

```css
.card {
  background-color: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  box-shadow: var(--shadow-sm);
}
```
