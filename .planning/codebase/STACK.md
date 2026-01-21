# Technology Stack

**Analysis Date:** 2026-01-21

## Languages

**Primary:**
- Go 1.13+ - Core application language, single entry point at `main.go`

## Runtime

**Environment:**
- Go 1.13+ (minimal requirement from `go.mod`)
- Linux, macOS, Windows (multi-platform support via GoReleaser)

**Package Manager:**
- Go Modules - Dependency management
- Lockfile: `go.sum` (present)

## Frameworks

**Core:**
- None - Bare Go standard library application with minimal dependencies

**Build/Dev:**
- GoReleaser 1.x - Multi-platform binary releases and Homebrew formula generation (`.goreleaser.yml`)
- golangci-lint - Code linting and analysis (`.golangci.yml`)
- Makefile - Build automation via `rules.mk`

## Key Dependencies

**Critical:**
- `github.com/peterbourgon/ff` v1.6.0 - Command-line flag parsing library, only external dependency

**Standard Library:**
- `flag` - Built-in flag parsing (extended by ff)
- `time` - Timing/ticker functionality for metronome beats
- `fmt` - Output formatting
- `os` - OS-level operations

## Configuration

**Build Configuration:**
- `.golangci.yml` - Linting rules (deadline: 1m, enabled linters: goconst, misspell, deadcode, structcheck, errcheck, unused, varcheck, staticcheck, unconvert, gofmt, goimports, golint, ineffassign)
- `.goreleaser.yml` - Release configuration with cross-compilation for linux/darwin/windows on 386/amd64/arm/arm64
- `Makefile` - Entry point for build targets, sources `rules.mk` from moul.io
- `package.json` - Metadata only (not a Node.js project), defines npm package at `@moul.io/metronome`

**Runtime Configuration:**
- CLI flags via `ff` parser in `main.go`:
  - `-bpm` (default: 120) - Beats per minute for metronome
  - `-config` (optional) - Configuration file path (declared but not used in main logic)

**Docker:**
- Multi-stage Dockerfile:
  - Build stage: `golang:1.16-alpine` with git, gcc, make
  - Runtime stage: `alpine:3.13` (minimalist)
  - Binary copied to `/bin/metronome`
  - Entrypoint: `/bin/metronome`

## Platform Requirements

**Development:**
- Go 1.13 or later
- Make
- Git
- golangci-lint (optional, for linting)

**Production:**
- Alpine Linux 3.13 (in Docker), or standalone binary for any supported OS

**Docker Environment:**
- Build time: golang:1.16-alpine (includes go compiler, gcc, musl-dev, git, make)
- Runtime: alpine:3.13 (base OS image)
- Build variables: BUILD_DATE, VCS_REF, VERSION (for container labels)

---

*Stack analysis: 2026-01-21*
