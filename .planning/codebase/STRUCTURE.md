# Codebase Structure

**Analysis Date:** 2026-01-21

## Directory Layout

```
metronome/
├── .circleci/               # CI/CD configuration
│   └── config.yml           # CircleCI workflow definition
├── .github/                 # GitHub templates (issues, PRs)
├── .planning/               # GSD planning documents
│   ├── codebase/            # Architecture & quality analysis
│   └── intel/               # Phase planning documents
├── doc.go                   # Package documentation & ASCII art
├── main.go                  # Main application entry point
├── go.mod                   # Go module definition
├── go.sum                   # Go module checksums
├── Dockerfile               # Multi-stage Docker build config
├── Makefile                 # Build automation entry point
├── rules.mk                 # Shared moul.io Makefile rules
├── package.json             # NPM metadata (non-Node project)
├── .golangci.yml            # GoLangCI linter configuration
├── .goreleaser.yml          # Multi-platform release config
├── .editorconfig            # Editor formatting rules
├── .gitignore               # Git ignore patterns
├── .gitattributes           # Git file attributes
├── .dockerignore             # Docker build ignore patterns
├── README.md                # Project documentation
├── COPYRIGHT                # License information
├── LICENSE-APACHE           # Apache 2.0 license
├── LICENSE-MIT              # MIT license
├── AUTHORS                  # Contributor list (generated)
└── SECURITY.md              # Security policy
```

## Directory Purposes

**Project Root:**
- Purpose: Main application source and build configuration
- Contains: Go source files, build automation, CI/CD config
- Key files: `main.go`, `go.mod`, `Makefile`

**.circleci:**
- Purpose: CI/CD pipeline configuration for GitHub integration
- Contains: CircleCI workflow definitions
- Key files: `config.yml` - defines Go build jobs (versions 1.11, 1.12, current) and Docker builds

**.planning:**
- Purpose: GSD (Generative System Design) analysis and planning
- Contains: Codebase analysis documents and implementation plans
- Key subdirectories:
  - `codebase/`: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md
  - `intel/`: Phase implementation plans and execution logs

**.github:**
- Purpose: GitHub-specific configuration templates
- Contains: Issue templates, PR templates, funding configuration

## Key File Locations

**Entry Points:**
- `main.go`: Main application executable (lines 12-40 contain the CLI entry point)

**Configuration:**
- `go.mod`: Go module definition and version constraints (Go 1.13)
- `Makefile`: Build automation entry point (sources `rules.mk`)
- `rules.mk`: Shared Makefile rules for Go projects, Docker, NPM
- `.golangci.yml`: Linter configuration (enables 11 linters: goconst, misspell, deadcode, structcheck, errcheck, unused, varcheck, staticcheck, unconvert, gofmt, goimports, golint, ineffassign)
- `.goreleaser.yml`: Multi-platform binary release configuration
- `Dockerfile`: Two-stage build: compile in golang:1.16-alpine, run on alpine:3.13
- `.editorconfig`: Editor formatting (spaces, line endings)

**Documentation:**
- `README.md`: Usage instructions, installation methods, license information
- `doc.go`: Go package documentation with ASCII art message from author
- `COPYRIGHT`: License and copyright attribution
- `SECURITY.md`: Security reporting guidelines
- `AUTHORS`: Generated list of contributors from git history

**Build & Release:**
- `.circleci/config.yml`: CircleCI workflow (Go 1.11, 1.12, current; Docker build)
- `.goreleaser.yml`: Goreleaser configuration for cross-platform builds (Linux, Darwin, Windows; 386, amd64, arm, arm64)

**Ignore Files:**
- `.gitignore`: Git ignore patterns
- `.dockerignore`: Docker build context excludes
- `.gitattributes`: Git file attribute rules (line endings, binary markers)

## Naming Conventions

**Files:**
- Source files: lowercase with `.go` extension (`main.go`, `doc.go`)
- Configuration: UPPERCASE with extension (`.golangci.yml`, `Dockerfile`, `Makefile`)
- Documentation: UPPERCASE with `.md` (README.md, COPYRIGHT, SECURITY.md)
- CI/CD: Hidden directories with configuration files (`.circleci/config.yml`)
- License: LICENSE-{TYPE} (LICENSE-APACHE, LICENSE-MIT)

**Go Code:**
- Package: `main` (executable package in root)
- Functions: `main()` (entry point)
- Variables: Lowercase with abbreviations (`bpm`, `fs`, `i`, `start`, `duration`, `bips`, `uptime`)
- Constants: None defined in current code

**Directories:**
- Hidden: `.` prefix (`.circleci`, `.github`, `.planning`, `.git`)
- Configuration: Root level or hidden subdirectories
- No domain-specific directories (no `/pkg`, `/cmd`, `/internal`, `/test` separation)

## Where to Add New Code

**New Features:**
- Primary code: `main.go` - extend the `main()` function or add helper functions to same file
- Tests: Create `main_test.go` in root directory using Go testing conventions
- Example: If adding timer persistence, add functions and types directly in `main.go`

**Config Support:**
- Implementation: The `-config` flag is defined but unused. Extend `main()` to parse the config file after flag parsing
- Location: `main.go` (around line 18-21 where config flag is defined)
- Pattern: Add code after `ff.Parse()` to read and apply config file

**New Utilities or Modules:**
- If complexity grows, create separate `.go` files in root directory
- Example: `timing.go` for timing calculations, `output.go` for display logic
- Keep all code in `main` package unless creating a library

**Tests:**
- Unit tests: Create `main_test.go` or `*_test.go` files in root directory
- Command: `make unittest` or `go test -v -cover -race ./...`
- Pattern: Use stdlib `testing` package (no test framework installed)

## Special Directories

**go mod vendor:**
- Purpose: Not present; dependencies pulled from remote
- Generated: No (uses `go mod download` during build)
- Committed: No

**.planning:**
- Purpose: GSD analysis and planning documents
- Generated: Yes (created by GSD tools)
- Committed: Yes (tracked in git for documentation)

## Build Workflow

**Local Development:**
```bash
make test      # Runs unittest, lint, tidy checks
make build     # Compiles Go binaries and Docker image
make install   # Installs metronome binary to GOPATH
make lint      # Runs golangci-lint
make tidy      # Runs go mod tidy
```

**CI/CD Pipeline (CircleCI):**
1. Runs Go 1.11, 1.12, and current version builds
2. Builds Docker image with `docker build`
3. Uses `moul/build` orb for standard Go/Docker build steps

**Release Process:**
```bash
make release   # Goreleaser multi-platform build:
               # - Compiles for Linux/Darwin/Windows x 386/amd64/arm/arm64
               # - Creates archives with directory wrapping
               # - Generates checksums
               # - Updates Homebrew tap
```

---

*Structure analysis: 2026-01-21*
