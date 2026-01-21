# External Integrations

**Analysis Date:** 2026-01-21

## APIs & External Services

**No external APIs or services integrated.**

This is a standalone CLI utility with no external service dependencies.

## Data Storage

**Databases:**
- Not applicable - No database integrations

**File Storage:**
- Local filesystem only - Configuration file path accepted via `-config` flag but not actively used in `main.go`

**Caching:**
- Not applicable - No caching layer

## Authentication & Identity

**Auth Provider:**
- Not applicable - No authentication required

## Monitoring & Observability

**Error Tracking:**
- Not detected

**Logs:**
- Console output only via `fmt.Printf()` in `main.go` for status display (BPM, bips counter, uptime)

## CI/CD & Deployment

**Hosting:**
- Docker Hub (image: `moul/metronome`)
- GitHub Releases (binary downloads)
- Homebrew (via moul/moul tap: `brew install moul/moul/metronome`)
- npm registry (package: `@moul.io/metronome` - metadata only, not functional)

**CI Pipeline:**
- CircleCI (`.circleci/config.yml`)
  - Orchestration: moul/build CircleCI orb v1.12.1
  - Builds: golang-build for Go 1.13, 1.12, 1.11 + docker-build
  - Runs on: master branch and pull requests

**Dependency Management:**
- Renovate bot (`.github/renovate.json`) - Automated Docker and dependency updates
- Configuration: base config, grouped updates

## Environment Configuration

**Required env vars:**
- None required for CLI execution

**Build env vars:**
- `BUILD_DATE` - Docker build argument (image label)
- `VCS_REF` - Docker build argument (git revision label)
- `VERSION` - Docker build argument (version label)
- `CGO_ENABLED=0` - Go build flag (static compilation)

**Go Modules:**
- `GO111MODULE=on` - Explicitly enabled in Dockerfile build stage

**Secrets location:**
- Not applicable - No secrets management required

## Webhooks & Callbacks

**Incoming:**
- Not applicable

**Outgoing:**
- Not applicable

---

*Integration audit: 2026-01-21*
