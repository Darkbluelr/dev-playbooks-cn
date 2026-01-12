# Project Profile

> This document describes the project's technical profile for AI assistants to quickly understand project context.

---

## Technology Stack

| Category | Technology | Version |
|------|------|------|
| Language | <!-- TypeScript/Python/Go --> | <!-- version --> |
| Framework | <!-- React/Django/Gin --> | <!-- version --> |
| Database | <!-- PostgreSQL/MongoDB --> | <!-- version --> |
| Test Framework | <!-- Jest/pytest/go test --> | <!-- version --> |
| Build Tool | <!-- webpack/vite/make --> | <!-- version --> |

---

## Common Commands

| Command | Purpose |
|------|------|
| `npm run dev` | Start development server |
| `npm run build` | Build production version |
| `npm run test` | Run tests |
| `npm run lint` | Run code linting |

---

## Project Conventions

### Naming Conventions

- **File names**: kebab-case (e.g., `user-service.ts`)
- **Component names**: PascalCase (e.g., `UserProfile`)
- **Function names**: camelCase (e.g., `getUserById`)
- **Constant names**: UPPER_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)

### Directory Structure Conventions

```
src/
├── components/     # UI components
├── services/       # Business logic
├── models/         # Data models
├── utils/          # Utility functions
└── tests/          # Test files
```

---

## Quality Gates

| Gate | Threshold | Command |
|------|------|------|
| Unit Test Coverage | >= 80% | `npm run test:coverage` |
| Type Check | 0 errors | `npm run typecheck` |
| Lint Check | 0 errors | `npm run lint` |
| Build | Success | `npm run build` |

---

## External Services

| Service | Purpose | Environment Variable |
|------|------|----------|
| <!-- e.g., PostgreSQL --> | <!-- Data storage --> | `DATABASE_URL` |
| <!-- e.g., Redis --> | <!-- Cache --> | `REDIS_URL` |

---

## Special Constraints

<!-- Project-specific constraints or rules -->

---

**Profile Version**: v1.0.0
**Last Updated**: {{DATE}}
