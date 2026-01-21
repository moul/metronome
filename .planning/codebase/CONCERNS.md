# Codebase Concerns

**Analysis Date:** 2026-01-21

## Tech Debt

**Resource Leak via time.Tick():**
- Issue: `time.Tick()` creates an underlying ticker that cannot be stopped and will continue running indefinitely until the program exits, leaking resources in long-running scenarios.
- Files: `main.go:27`
- Impact: In containerized or daemon environments, this will leak goroutines and timer resources. If the application is restarted multiple times within a process, tickers accumulate in memory.
- Fix approach: Replace `time.Tick()` with `time.NewTicker()` to allow explicit cleanup via `Ticker.Stop()`. Wrap in a defer statement to ensure ticker cleanup on exit.

**Unhandled Error via Panic:**
- Issue: Flag parsing errors trigger `panic(err)` instead of graceful error handling with contextual messaging.
- Files: `main.go:20`
- Impact: Users see a full panic stack trace instead of a clean error message. Complicates troubleshooting for misconfigured flags or invalid arguments.
- Fix approach: Replace `panic(err)` with proper error logging and controlled exit via `fmt.Fprintf(os.Stderr, ...)` followed by `os.Exit(1)`.

**Unused Config Flag Parameter:**
- Issue: Flag for config file is declared but never used (`_` blank identifier on line 17).
- Files: `main.go:17`
- Impact: Users may pass a `--config` parameter expecting it to be processed, but it is silently ignored. Creates confusion and false expectations.
- Fix approach: Either implement config file parsing logic to use this parameter, or remove it entirely. If retaining for future use, add a deprecation notice.

**Hardcoded Default BPM and No Fallback:**
- Issue: Default BPM is hardcoded to 120 with no validation. Flag comment mentions "if zero, will ask you to type" but zero-value handling is not implemented.
- Files: `main.go:16, 24`
- Impact: Zero BPM will cause division by zero (time.Minute / time.Duration(0)) resulting in runtime panic. Feature described in comment is incomplete.
- Fix approach: Add input validation to reject zero or negative BPM values. Implement interactive input prompt for zero BPM if feature is intended, or add guard clause.

## Known Bugs

**Format String Truncation Issue:**
- Issue: Backspace character sequence `\b\r` is used to overwrite terminal output (lines 32, 34, 36), but this approach is fragile across different terminal emulators and may not clear properly.
- Files: `main.go:32-36`
- Impact: On some terminals (non-ANSI compatible), previous output may not be fully cleared, creating garbled display. Breaks on Windows cmd.exe without special mode.
- Workaround: Requires ANSI escape sequence support. Windows requires Virtual Terminal Processing enabled.

**Infinite Loop Without Graceful Shutdown:**
- Issue: The main loop `for range time.Tick(duration)` has no exit condition and cannot be stopped cleanly except via process termination (SIGKILL).
- Files: `main.go:27-39`
- Impact: CTRL+C (SIGINT) is not handled gracefully. Docker container shutdown may force-kill the process. No cleanup opportunity for proper logging or state finalization.
- Workaround: Process requires force termination.

## Performance Bottlenecks

**Timer Precision Under Load:**
- Issue: `time.Tick()` provides no strong timing guarantees under system load. Frequency may drift if the loop body takes significant time to execute.
- Files: `main.go:27-39`
- Impact: BPM accuracy degrades under high CPU load or I/O contention. The timing between beats may become inconsistent.
- Improvement path: For critical timing, use a time-checked approach with `time.Sleep()` or consider OS-level timer API for precise scheduling if timing requirements are strict.

## Fragile Areas

**Terminal Output Handling:**
- Files: `main.go:32-36`
- Why fragile: Hard-coded ANSI escape sequences with backspace control characters. No cross-platform abstraction. Output may corrupt if terminal buffer is read concurrently.
- Safe modification: If modifying output format, test across multiple terminal types (Linux, macOS, Windows PowerShell, cmd.exe). Consider using a terminal library (e.g., `bubbletea` or `lipgloss`) for portable terminal control.
- Test coverage: No unit tests for terminal output behavior.

**Flag Parsing and Configuration:**
- Files: `main.go:14-21`
- Why fragile: Relies on external `peterbourgon/ff` library with minimal error handling. Config file parameter is accepted but unused, creating contract violation with user expectations.
- Safe modification: Validate all flags before use. Implement config file logic or remove the flag. Add integration tests for flag parsing scenarios.
- Test coverage: No tests for invalid flag combinations or edge cases.

## Scaling Limits

**Single-Threaded Blocking Loop:**
- Current capacity: One metronome instance per process
- Limit: Cannot handle multiple simultaneous tempo streams or interactive tempo changes without restarting
- Scaling path: Refactor to use goroutines and channels for independent timer streams. Consider signal handling for runtime BPM adjustment (SIGUSR1/SIGUSR2).

## Dependencies at Risk

**Deprecated Go Version (1.13):**
- Risk: `go.mod` specifies Go 1.13 (released in 2019). This version is no longer supported and has known security vulnerabilities.
- Impact: Builds may fail in modern CI/CD environments. Security patches are unavailable.
- Migration plan: Update `go.mod` to Go 1.20 or later. Verify no deprecated APIs are used. Re-test with latest stable Go version.

**Outdated golangci-lint Configuration:**
- Risk: `.golangci.yml` uses deprecated linters (`golint` deprecated in favor of `revive`, `misspell` deprecated, `deadcode` and `structcheck` deprecated in favor of `unused`).
- Impact: Linter configuration will be ignored by recent golangci-lint versions. No static analysis performed by CI/CD.
- Migration plan: Update `.golangci.yml` to use current linters. Run `golangci-lint linters` to verify available options.

**Go 1.16 Docker Image:**
- Risk: Dockerfile uses `golang:1.16-alpine` and `alpine:3.13`, both EOL (End-of-Life).
- Impact: Security vulnerabilities in base images are not patched. Multi-stage builds may fail with newer packages.
- Migration plan: Update Dockerfile to use `golang:1.21-alpine3.19` (or latest stable) and `alpine:3.19` (or latest stable).

## Test Coverage Gaps

**No Unit Tests:**
- What's not tested: BPM calculation, timer loop behavior, flag parsing, duration computation (`time.Minute / time.Duration(*bpm) / 2`)
- Files: No test files exist in the repository
- Risk: Changes to timing logic could introduce off-by-one errors or incorrect frequency calculations. Regressions are undetectable.
- Priority: High

**No Integration Tests:**
- What's not tested: Docker build and runtime behavior, cross-platform binary execution, flag combinations
- Risk: Releases may contain broken artifacts or platform-specific issues.
- Priority: High

**No Error Handling Tests:**
- What's not tested: Invalid BPM values, missing dependencies, terminal failures
- Risk: Edge cases crash without useful error messages.
- Priority: Medium

---

*Concerns audit: 2026-01-21*
