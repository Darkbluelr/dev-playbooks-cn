# Code Navigation Strategy (Four-Step Method)

Drawing from VS Code's `copilot-instructions.md`, this document defines the standard process for quickly locating code in brownfield projects.

---

## Core Principle

> **Understand first, modify later**: Before modifying any code, you must first understand the structure and intent of the existing code.

---

## Four-Step Location Method

### Step 1: Semantic Search

**Purpose**: Quickly narrow scope based on intent

**Method**:
```bash
# Using fuzzy search tools
rg -i "user.*auth" --type ts
rg -i "login|signin|authenticate" --type ts

# Or use IDE semantic search
# VS Code: Cmd+Shift+F → Enter keywords
```

**Tips**:
- Use business terms rather than technical terms
- Try synonyms (login/signin/authenticate)
- Search comments and docstrings

### Step 2: Exact Search (Exact Grep)

**Purpose**: Find specific function/class/variable definitions

**Method**:
```bash
# Search function definitions
rg "function\s+createUser" --type ts
rg "const\s+createUser\s*=" --type ts

# Search class definitions
rg "class\s+UserService" --type ts

# Search interface definitions
rg "interface\s+User\b" --type ts

# Search exports
rg "export\s+(default\s+)?(function|class|const|interface)\s+\w*User" --type ts
```

**Tips**:
- Use `\b` to ensure word boundaries
- Search exports to find public APIs
- Combine with file path filtering: `rg "pattern" src/user/`

### Step 3: Trace Imports

**Purpose**: Understand dependency relationships and call chains

**Method**:
```bash
# Find who references this module
rg "from ['\"].*userService['\"]" --type ts
rg "import.*UserService" --type ts

# Find what this module references
rg "^import" src/services/userService.ts

# Use IDE's "Find References" feature
# VS Code: Right-click → Find All References (Shift+F12)
```

**Tips**:
- Start tracing from entry points (main.ts, index.ts)
- Note relative imports vs absolute imports
- Check re-exports (`export * from` in index.ts)

### Step 4: Review Tests

**Purpose**: Understand expected behavior and edge cases

**Method**:
```bash
# Find related test files
rg -l "UserService" tests/ src/**/test/

# View test case descriptions
rg "describe\(|it\(|test\(" tests/user.service.test.ts

# View mocks and fixtures
rg "mock|stub|fixture" tests/user.service.test.ts
```

**Tips**:
- Tests are the best documentation
- Check `beforeEach` to understand initialization
- Check `expect` to understand expected behavior
- Edge case tests reveal hidden constraints

---

## Location Strategy Selection

| Scenario | Recommended Strategy | Reason |
|----------|---------------------|--------|
| Don't know where feature is | Semantic Search → Exact Search | From broad to narrow |
| Know function name | Exact Search → Trace Imports | Direct location |
| Understanding call relationships | Trace Imports → Review Tests | Context understanding |
| Understanding expected behavior | Review Tests | Tests as documentation |
| Verifying impact before modification | Trace Imports | Impact analysis |

---

## Project Structure Recognition

### Common Directory Structure Patterns

**Layered Architecture**:
```
src/
├── controllers/   # Entry layer
├── services/      # Business logic layer
├── repositories/  # Data access layer
├── models/        # Data models
└── utils/         # Utility functions
```

**Feature Slice Architecture**:
```
src/
├── user/
│   ├── user.controller.ts
│   ├── user.service.ts
│   └── user.repository.ts
├── order/
│   ├── order.controller.ts
│   └── ...
```

**VS Code Architecture**:
```
src/vs/
├── base/          # Base utilities
├── platform/      # Platform services
├── editor/        # Editor
└── workbench/     # Workbench
    ├── browser/   # UI
    ├── services/  # Services
    └── contrib/   # Contribution modules
```

### Quick Entry Point Identification

```bash
# Find main files
rg -l "main|bootstrap|app" --type ts -g "*.ts" | head -10

# Find route definitions
rg "app\.(get|post|put|delete)|router\." --type ts

# Find service registrations
rg "register|provide|bind" --type ts | head -20
```

---

## Tool Recommendations

### Command Line Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| `rg` (ripgrep) | Fast text search | `brew install ripgrep` |
| `fd` | Fast file finding | `brew install fd` |
| `tree` | Directory structure visualization | `brew install tree` |
| `bat` | Syntax-highlighted viewing | `brew install bat` |

### IDE Features

| Feature | VS Code Shortcut | Purpose |
|---------|-----------------|---------|
| Global Search | Cmd+Shift+F | Semantic search |
| Go to Definition | F12 | Precise location |
| Find References | Shift+F12 | Trace imports |
| Symbol Search | Cmd+T | Quick jump |
| File Search | Cmd+P | Quick open |

---

## Checklist

Before starting to modify code, confirm completion of:

- [ ] Used semantic search to find relevant areas
- [ ] Used exact search to locate specific definitions
- [ ] Traced imports to understand dependencies
- [ ] Reviewed tests to understand expected behavior
- [ ] Identified project structure patterns
- [ ] Confirmed entry points and call chains
- [ ] Evaluated modification impact scope
