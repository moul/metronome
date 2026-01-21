# Architecture

**Analysis Date:** 2026-01-21

## Pattern Overview

**Overall:** Single-file CLI application with minimal dependencies

**Key Characteristics:**
- Monolithic entry point with all business logic in `main.go`
- Procedural design with sequential execution
- Flag-based configuration via CLI arguments
- No layering or abstraction; direct use of stdlib packages
- Minimal external dependencies (only peterbourgon/ff for flag parsing)

## Layers

**Entry Point & Main Logic:**
- Purpose: Parse command-line flags and execute metronome timing logic
- Location: `main.go`
- Contains: Flag parsing, main event loop, output formatting
- Depends on: `flag` (stdlib), `ff` (peterbourgon/ff), `fmt`, `os`, `time`
- Used by: Invoked directly as CLI command

**Package Documentation:**
- Purpose: Module declaration and author message
- Location: `doc.go`
- Contains: Package-level documentation and ASCII art message
- Depends on: None
- Used by: Referenced by Go documentation tools

## Data Flow

**CLI Invocation → Flag Parsing → Event Loop:**

1. Application starts via `main()` in `main.go`
2. Flag set created with `flag.NewFlagSet("metronome", flag.ExitOnError)`
3. Two flags defined:
   - `-bpm`: Beats per minute (default: 120)
   - `-config`: Optional config file path (defined but unused)
4. Flags parsed via `ff.Parse()` which provides environment variable and file support
5. Duration calculated: `time.Minute / time.Duration(*bpm) / 2` (half-beat intervals)
6. Infinite loop iterates every half-beat duration:
   - Calculates current beat count: `bips := i / 2`
   - Calculates elapsed time: `uptime := time.Since(start)`
   - Outputs animated metronome display based on counter position (4-state cycle: backslash, space, forward-slash, pipe)
   - Increments counter

**Output Pattern:**
- Displays four rotating characters: `\`, ` `, `/`, `|` to simulate swinging metronome
- Shows current BPM, beat count (bips), and uptime on each line
- Uses carriage return `\r` and backspace `\b` for in-place line updates

**State Management:**
- Single counter `i` tracks half-beat intervals (mod 4 for animation, divide by 2 for beat count)
- `start` timestamp records application startup for uptime calculation
- Flag values (`bpm`, `config`) are read-only after parsing
- No persistent state; timing driven entirely by `time.Tick()` channel

## Key Abstractions

**None explicitly defined:** The application contains no abstractions, interfaces, or helper functions. All logic is procedural and inline.

## Entry Points

**CLI Binary:**
- Location: `main.go` (lines 12-40)
- Triggers: Invoked as `metronome [flags]`
- Responsibilities:
  - Parse `-bpm` flag to set beats per minute
  - Accept optional `-config` flag (not yet implemented)
  - Calculate and display metronome timing indefinitely

## Error Handling

**Strategy:** Panic on flag parsing errors

**Patterns:**
- `flag.NewFlagSet(..., flag.ExitOnError)`: Causes flag set to exit on parse errors
- `if err := ff.Parse(...); err != nil { panic(err) }`: Panics if ff flag parsing fails
- No explicit error recovery or user-friendly error messages
- No validation of BPM value (accepts any integer)

## Cross-Cutting Concerns

**Logging:** None. Output is only the animated metronome display via `fmt.Printf`

**Validation:** None. BPM flag accepts any integer value without bounds checking

**Configuration:**
- Runtime: Via `-bpm` and `-config` flags
- `-config` flag defined but not implemented
- ff library supports environment variables and config files, but no parsing logic present
- Default BPM is 120

**Build & Deployment:**
- Docker multi-stage build in `Dockerfile`: compiles in `golang:1.16-alpine`, runs on `alpine:3.13`
- Go modules (`go.mod`) defines dependency on `peterbourgon/ff v1.6.0`
- Multi-platform release via goreleaser: Linux, Darwin, Windows on 386, amd64, arm, arm64
- CircleCI pipeline builds Go 1.12, 1.11, and current versions with Docker build

---

*Architecture analysis: 2026-01-21*
