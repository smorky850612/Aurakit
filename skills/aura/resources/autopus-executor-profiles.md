# Autopus Executor Profiles

> Absorbed from Autopus-ADK. Stack-specific profiles injected into executor agents
> at Phase 2 to ensure language/framework-correct implementations.

---

## Overview

Executor profiles are configuration overlays that tell the executor agent:
- Which conventions to follow for this language/framework
- What patterns are preferred vs. anti-patterns
- Testing patterns for this stack
- Error handling idioms

Profiles are matched automatically by file extension in the planner's file manifest.

---

## Profile Resolution Order

```
1. Custom profile (.autopus/profiles/{name}.yaml) — highest priority
2. Generated profile (created by planner for this project)
3. Built-in profile (below) — fallback
```

Profile extends syntax:
```yaml
name: my-nextjs-app
extends: typescript  # Inherits all typescript profile rules
overrides:
  test_framework: vitest
  import_style: "@/..."
```

---

## File → Profile Mapping (Auto-detection)

| Pattern | Profile |
|---------|---------|
| `*.go` | `go` |
| `*.ts`, `*.tsx` | `typescript` |
| `*.py` | `python` |
| `*.rs` | `rust` |
| `*.tsx`, `*.jsx` (React components) | `frontend` |
| `*.vue` | `frontend-vue` |
| `*.svelte` | `frontend-svelte` |
| `*.java`, `*.kt` | `jvm` |
| `*.swift` | `swift` |

---

## Built-in Profile: Go

```yaml
name: go
language: Go

conventions:
  error_handling: |
    Always check errors explicitly:
    if err != nil { return fmt.Errorf("context: %w", err) }
    Never ignore errors with _
  naming: |
    Exported: PascalCase
    Unexported: camelCase
    Acronyms: uppercase (URL, HTTP, ID)
  packages: |
    One package per directory
    Package name = directory name (no underscores)
  interfaces: |
    Define at point of use (not in library)
    1-2 methods preferred; embed for composition

patterns:
  preferred:
    - table-driven tests ([]struct{name, input, expected})
    - context.Context as first parameter for all IO
    - defer for cleanup
    - errgroup for concurrent operations
  anti_patterns:
    - panic() in library code
    - global variables (use dependency injection)
    - init() functions
    - interface{} without type assertion

testing:
  framework: testing (stdlib) + testify
  pattern: |
    func TestFunctionName(t *testing.T) {
        tests := []struct {
            name  string
            input InputType
            want  ExpectedType
            wantErr bool
        }{...}
        for _, tt := range tests {
            t.Run(tt.name, func(t *testing.T) {
                got, err := FunctionName(tt.input)
                if tt.wantErr {
                    require.Error(t, err)
                    return
                }
                require.NoError(t, err)
                assert.Equal(t, tt.want, got)
            })
        }
    }

imports:
  style: explicit (no dot imports)
  grouping: stdlib / external / internal
```

---

## Built-in Profile: TypeScript

```yaml
name: typescript
language: TypeScript

conventions:
  types: |
    Prefer type over interface for unions/intersections
    Use interface for extensible object shapes
    Never use 'any' — use 'unknown' + type narrowing
    Prefer readonly where mutation is not needed
  async: |
    async/await over .then() chains
    Always handle errors: try/catch or .catch()
    Never unhandled Promise rejections
  imports: |
    Named imports preferred over default imports
    Barrel files (index.ts) for public API only
    Path aliases (@/) for cross-module imports

patterns:
  preferred:
    - Zod for runtime validation
    - Result/Either types for expected failures
    - const assertions (as const) for literal types
    - Optional chaining (?.) over null checks
  anti_patterns:
    - Non-null assertion (!) without comment
    - Type casting (as) without validation
    - typeof null === 'object' bug patterns
    - Mutation of function parameters

testing:
  framework: vitest (preferred) or jest
  pattern: |
    describe('FunctionName', () => {
      it('should [behavior] when [condition]', () => {
        // Arrange
        const input = createTestInput()
        // Act
        const result = functionName(input)
        // Assert
        expect(result).toEqual(expected)
      })
    })
  mocking: vi.mock() for module mocks; avoid over-mocking

error_handling: |
  Custom error classes extending Error
  Include: message, code (enum), cause (Error | undefined)
  API responses: { success: boolean, data?: T, error?: string }
```

---

## Built-in Profile: Python

```yaml
name: python
language: Python

conventions:
  style: PEP 8 + Black formatter
  types: |
    Full type hints on all public functions
    Use Optional[T] not T | None for Python < 3.10
    Pydantic for data validation/serialization
  docstrings: |
    Google style for public functions
    Args/Returns/Raises sections
  imports: |
    absolute imports only
    __all__ for public API

patterns:
  preferred:
    - dataclasses or Pydantic models over dicts
    - Context managers (with) for resource management
    - Generator functions for large datasets
    - pathlib over os.path
  anti_patterns:
    - Mutable default arguments
    - Star imports (from module import *)
    - Bare except clauses
    - String formatting with % or .format() (use f-strings)

testing:
  framework: pytest
  pattern: |
    def test_function_name_when_condition():
        # Arrange
        input_data = create_test_input()
        # Act
        result = function_name(input_data)
        # Assert
        assert result == expected
  fixtures: pytest fixtures over setUp/tearDown
  mocking: unittest.mock.patch or pytest-mock

error_handling: |
  Custom exceptions inheriting from appropriate base (ValueError, RuntimeError)
  Raise specific exceptions, not generic Exception
  Log at the point of handling, not at the point of raising
```

---

## Built-in Profile: Rust

```yaml
name: rust
language: Rust

conventions:
  error_handling: |
    Use Result<T, E> everywhere IO can fail
    Custom error types with thiserror crate
    ? operator for propagation
    Never use unwrap() in library code (use expect() with message)
  naming: |
    Types/Traits: PascalCase
    Functions/variables: snake_case
    Constants: SCREAMING_SNAKE_CASE
  ownership: |
    Prefer borrowing over cloning
    Use Arc<Mutex<T>> only when necessary
    Document lifetime parameters

patterns:
  preferred:
    - Builder pattern for complex constructors
    - impl Trait for return types in public API
    - serde for serialization (derive Serialize/Deserialize)
    - tokio for async
  anti_patterns:
    - Rc<RefCell<T>> in async code (use Arc<Mutex<T>>)
    - unwrap() without error context
    - mem::forget() without explicit reason

testing:
  framework: built-in + proptest for property testing
  pattern: |
    #[cfg(test)]
    mod tests {
        use super::*;
        
        #[test]
        fn test_function_name() {
            let result = function_name(input);
            assert_eq!(result, expected);
        }
    }
```

---

## Built-in Profile: Frontend (React/Next.js)

```yaml
name: frontend
language: TypeScript (JSX)

conventions:
  components: |
    Atomic Design: atom → molecule → organism → template → page
    Single responsibility: one concern per component
    Props: explicit interface, no implicit any
    File: PascalCase.tsx, test: PascalCase.test.tsx
  state: |
    Local state: useState for UI-only state
    Server state: React Query / SWR
    Global state: Zustand (avoid Redux unless complex)
    Form state: React Hook Form
  styling: |
    Tailwind CSS utility classes (project standard)
    CSS variables for theme tokens (see design-system.md)
    No inline styles except dynamic values

patterns:
  preferred:
    - Custom hooks for reusable logic (useFeatureName)
    - Composition over inheritance
    - Server Components for data fetching (Next.js App Router)
    - Suspense + loading.tsx for async boundaries
    - Error boundaries for UI error handling
  anti_patterns:
    - useEffect for derived state (use useMemo)
    - Prop drilling beyond 2 levels (use context or state manager)
    - Direct DOM manipulation (use refs sparingly)
    - Mega-components > 150 lines

accessibility:
  required:
    - img: alt attribute (empty for decorative)
    - input/select/textarea: id + label[htmlFor]
    - buttons: descriptive text or aria-label
    - errors: role="alert" or aria-live="polite"
    - focus management after modal/dialog open
  
testing:
  framework: Vitest + React Testing Library
  pattern: |
    // Test behavior, not implementation
    it('shows error message when login fails', async () => {
      renderWithProviders(<LoginForm />)
      
      await userEvent.type(screen.getByLabelText('Email'), 'bad@')
      await userEvent.click(screen.getByRole('button', { name: 'Login' }))
      
      expect(screen.getByRole('alert')).toHaveTextContent('Invalid email')
    })
  principles:
    - Query by role/label (not test-id) when possible
    - Avoid testing implementation details
    - Mock API calls, not component internals
```

---

## Profile Injection in Phase 2

When executor receives file assignment, planner injects the profile:

```
[EXECUTOR CONTEXT]
File: src/components/LoginForm.tsx
Profile: frontend (React/Next.js)
Spec: SPEC-003 AC-01

[PROFILE RULES ACTIVE]
- Atomic Design: this is an organism (form with multiple inputs)
- Accessibility: form inputs require label+htmlFor
- Error state: use role="alert" on error messages
- Testing: RTL queries by role/label

[BEGIN IMPLEMENTATION]
```

---

## Custom Profile Example

Create `.autopus/profiles/my-project.yaml`:

```yaml
name: my-project-ts
extends: typescript
description: Custom profile for this monorepo

overrides:
  test_framework: jest
  import_style: "@project/"
  
additional_rules:
  - "Use BaseRepository class for all data access"
  - "API responses must use ApiResult<T> wrapper"
  - "All services must be injectable (constructor injection)"

forbidden_patterns:
  - "fetch(" # Use our http-client wrapper instead
  - "console.log" # Use logger service
```
