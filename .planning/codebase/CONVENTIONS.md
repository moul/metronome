# Coding Conventions

**Analysis Date:** 2026-01-21

## Naming Patterns

**Files:**
- Package file: `doc.go` - Contains package-level documentation and copyright headers
- Executable: `main.go` - Contains the main entry point for the application
- Standard Go naming: snake_case for file names (e.g., `main.go`, `doc.go`)

**Functions:**
- camelCase for function names (e.g., `func main()`, flag definitions with underscore prefix for unused variables)
- Single letter or short variables for loop counters and temporary values (e.g., `i`, `bips`)

**Variables:**
- camelCase for local variables and parameters
- ALL_CAPS for flag-bound variables used throughout function scope (convention: `bpm`, `_` for unused assignments)
- Short variable names for temporary calculations: `i` for counter, `bips` for bits, `uptime` for duration

**Types:**
- Not heavily used in this codebase (minimal custom types)
- Flag types use built-in types: `*int`, `*string` for flag.FlagSet bindings

## Code Style

**Formatting:**
- Tab-based indentation for Go files (configured in `.editorconfig`)
- Standard Go formatting enforced by `gofmt` linter
- Line length: No explicit limit enforced (gofmt standard)
- Final newline at end of file required

**Linting:**
- Tool: `golangci-lint` (configured in `.golangci.yml`)
- Enabled linters:
  - `gofmt` - Code formatting
  - `goimports` - Import organization
  - `golint` - Style issues
  - `errcheck` - Unchecked errors
  - `deadcode` - Dead code detection
  - `unused` - Unused variables/functions
  - `varcheck` - Unused variables
  - `staticcheck` - Static analysis
  - `unconvert` - Unnecessary type conversions
  - `ineffassign` - Inefficient assignments
  - `structcheck` - Unused struct fields
  - `misspell` - Spelling errors (US locale)
  - `goconst` - Const duplication (min-len: 5, min-occurrences: 4)
- Run deadline: 1 minute
- Tests excluded from linting: `tests: false`

## Import Organization

**Order:**
1. Standard library imports (e.g., `flag`, `fmt`, `os`, `time`)
2. Third-party packages (e.g., `github.com/peterbourgon/ff`)

**Imports in code:**
- Organized alphabetically by package path
- Single import block with no grouped imports
- Example from `main.go`:
```go
import (
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/peterbourgon/ff"
)
```

**Path Aliases:**
- Not used in this codebase

## Error Handling

**Patterns:**
- Direct panic for fatal errors in main() initialization:
```go
if err := ff.Parse(fs, os.Args[1:]); err != nil {
	panic(err)
}
```
- No explicit error returns at main level (CLI tool with panic-on-error pattern)
- Minimal error handling due to simple CLI nature

## Logging

**Framework:** Console output only (no logging framework)

**Patterns:**
- Direct `fmt.Printf()` for output messages
- Status information printed to stdout with backspace escaping (`\b\r`) for in-place updates
- Example:
```go
fmt.Printf("\b\r\\   bpm=%d bips=%d uptime=%s", *bpm, bips, uptime)
```
- No debug/info/warn/error levels
- Single-purpose output for monitoring

## Comments

**When to Comment:**
- Package-level documentation in `doc.go`
- Inline comments for non-obvious logic (minimal in this codebase)
- License headers at top of files

**JSDoc/TSDoc:**
- Not used (Go documentation style not applied in this minimal project)
- Package documentation present in `doc.go`

**Header pattern:**
```go
// Copyright © 2019 Manfred Touron <manfred.life>.
//
// Licensed under the Apache License, Version 2.0 (the "License");
```

## Function Design

**Size:**
- Minimal - main() is ~30 lines
- Single responsibility per function
- Inline operations preferred over helper functions for simple CLI

**Parameters:**
- Pointers used for flag bindings: `bpm *int`
- Simple parameters for local scope

**Return Values:**
- Not used - main() returns void
- Error handling via panic pattern

## Module Design

**Exports:**
- Single main package (executable)
- No exported functions/types
- Only `main()` entry point exported implicitly

**Barrel Files:**
- Not applicable (single-file executable)

## Constants

**Pattern:**
- No explicit constants defined
- Magic numbers used directly (e.g., 120 for default BPM, 4 for beat subdivision)
- Consider extracting: `duration := time.Minute / time.Duration(*bpm) / 2`

## Special Conventions

**CLI Flag Handling:**
- Uses `flag.FlagSet` with application name (e.g., "metronome")
- Optional config parameter accepted but not yet used: `"config", "", "config file (optional)"`
- Uses `github.com/peterbourgon/ff` for parsing
- Underscore prefix for unused assignments: `_ = fs.String(...)`

**Build Process:**
- Makefile-based with `rules.mk` included
- `go install` for building
- Single module: `moul.io/metronome`
- Go 1.13+ required (from go.mod)

---

*Convention analysis: 2026-01-21*
