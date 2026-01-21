# Testing Patterns

**Analysis Date:** 2026-01-21

## Test Framework

**Runner:**
- Go standard library testing package (not explicitly configured)
- No third-party test framework detected

**Assertion Library:**
- Go standard library assertions (no external assertion library found)

**Run Commands:**
```bash
make test              # Run all tests (via rules.mk go.unittest)
make go.unittest       # Run tests with coverage
golangci-lint run      # Run linting
```

**Actual commands from rules.mk:**
```bash
# For unit tests
go test -v -cover -coverprofile=/tmp/profile.out -covermode=atomic -race ./...

# For linting
golangci-lint run --verbose ./...
```

## Test File Organization

**Location:**
- No test files currently present in codebase
- Expected pattern: Co-located with source files (standard Go convention)
- Pattern: `[filename]_test.go` alongside `[filename].go`

**Naming:**
- Test functions follow pattern: `func Test[FunctionName](t *testing.T)`
- Table-driven tests would use: `func Test[FunctionName](t *testing.T)` with `t.Run()` subtests

**Structure:**
```
moul.io/metronome/
├── main.go
├── main_test.go          # (not present, but expected location)
├── doc.go
└── doc_test.go           # (not present, but expected location)
```

## Test Structure

**Current State:**
- No existing test files in codebase
- Zero test coverage as of analysis date

**Expected patterns (Go standard):**
```go
// Example structure if tests were present:
package main

import (
	"testing"
)

func TestMain(t *testing.T) {
	// Test logic here
}

func TestFlagParsing(t *testing.T) {
	// Test flag parsing
}
```

**Patterns (when implemented):**
- Setup: Directly in test function (no shared setup framework)
- Teardown: `defer` statements if cleanup needed
- Assertion: Direct boolean checks or helper functions

## Mocking

**Framework:**
- No mocking framework currently used
- Standard Go approach: interface-based mocking

**Patterns (if needed):**
- Interfaces used for dependency injection (not visible in current code)
- Mock implementations would satisfy interfaces
- Example pattern for time mocking:
```go
// For testing time.Tick() usage, would need to abstract into interface
type TimeSource interface {
	Tick(d time.Duration) <-chan time.Time
}
```

**What to Mock:**
- External dependencies (if refactored): flag parsing, I/O operations
- Time functions for deterministic testing
- Environment variables if accessed

**What NOT to Mock:**
- Standard library functions (time.Now, time.Minute)
- Flag parsing (unless behavior changes significantly)

## Fixtures and Factories

**Test Data:**
- Not used in current codebase
- Would likely use simple inline test values for BPM, durations, etc.

**Location:**
- Would reside in test files alongside implementations
- Could be in `testutil` package if shared across multiple test files

## Coverage

**Requirements:**
- No explicit coverage target enforced
- README shows codecov badge: [![codecov](https://codecov.io/gh/moul/metronome/branch/master/graph/badge.svg)]
- Coverage tracking enabled: `covermode=atomic` in Makefile
- Coverage file generated: `/tmp/coverage.txt`

**View Coverage:**
```bash
make go.unittest       # Generates coverage.txt
go tool cover -html=coverage.out  # (would view HTML report if available)
```

## Test Types

**Unit Tests:**
- Scope: Individual functions (main, flag parsing, duration calculation)
- Approach: Table-driven tests for different BPM values
- Would test:
  - Flag parsing with various inputs
  - Duration calculation accuracy
  - Counter behavior
  - Time formatting

**Integration Tests:**
- Scope: Flag parsing integration with ff library
- Would verify: Full end-to-end parsing and startup

**E2E Tests:**
- Not applicable for CLI tool (could be done with shell scripts)
- Manual testing: Running `metronome -bpm 120` and verifying output

## Common Patterns

**Async Testing:**
```go
// For testing time.Tick() behavior
func TestMetronomeLoop(t *testing.T) {
	// Would need to refactor time.Tick into injectable dependency
	// Then create mock that controls timing
}
```

**Error Testing:**
```go
// For testing ff.Parse error handling
func TestFlagParsingError(t *testing.T) {
	// Mock flag parsing to return error
	// Verify panic is called
}
```

**Table-driven tests (if implemented):**
```go
func TestDurationCalculation(t *testing.T) {
	tests := []struct {
		name string
		bpm  int
		want time.Duration
	}{
		{"120 BPM", 120, 250 * time.Millisecond},
		{"60 BPM", 60, 500 * time.Millisecond},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Test logic
		})
	}
}
```

## CI/CD Testing

**Pipeline:**
- CircleCI configured in `.circleci/config.yml`
- Uses custom Moul build orb: `moul/build@1.12.1`
- Jobs:
  - `moul/golang-build` for multiple Go versions (1.12, 1.11, current)
  - `moul/docker-build` for Docker image testing
- Tests run as part of build process (via `rules.mk`)

**Test flags:**
```bash
go test -v -cover -coverprofile=/tmp/profile.out -covermode=atomic -race ./...
```
- `-v`: Verbose output
- `-cover`: Coverage measurement
- `-race`: Race condition detection
- `-covermode=atomic`: Atomic mode for concurrent testing

## Gaps & Recommendations

**Critical gaps:**
1. **No test files exist** - Files: `main.go` and `doc.go` have zero coverage
2. **No unit tests** - Flag parsing untested
3. **No integration tests** - ff library integration untested
4. **No edge case testing** - BPM boundary values not tested
5. **No error scenario testing** - Invalid input handling not covered

**Priority areas for testing:**
1. Main function flag parsing - High priority
2. Duration calculation logic - Medium priority
3. Time formatting and output - Medium priority
4. Error handling for invalid BPM values - Medium priority

---

*Testing analysis: 2026-01-21*
