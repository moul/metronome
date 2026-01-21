# Roadmap: Metronome v1

**Created:** 2026-01-21
**Milestone:** v1 — Core Metronome MVP
**Core Value:** Precise, reliable timing that musicians can trust

## Overview

6 phases delivering a cross-platform metronome with advanced tap tempo and multi-output modes.

**Phase ordering rationale:**
- Audio engine first — every feature depends on accurate timing
- iOS before cross-platform — prove architecture where feature set is richest
- Multi-output before ecosystem — haptics/flashlight depend on timing engine
- Widgets last — refresh limitations make them "nice to have" not core

## Phases

### Phase 01: Core Engine
**Goal:** Working metronome engine with sample-accurate timing and basic tap tempo
**Delivers:** MetronomeCore Swift Package + Objective-C audio engine
**Requirements:** BPM control, audio output, basic tap tempo (4-tap average)
**Architecture:** Real-time audio in Objective-C, Swift wrapper API
**Risk mitigation:** Addresses audio thread rules (Pitfall #1), buffer scheduling (Pitfall #2)
**Research:** Standard patterns — Apple Hello Metronome sample provides reference
**Plans:** 3 plans

Plans:
- [x] 01-01-PLAN.md — MetronomeCore Swift Package (BPM type, TapTempo, tests)
- [x] 01-02-PLAN.md — Objective-C AudioEngine (sample-accurate scheduling)
- [x] 01-03-PLAN.md — Swift Wrapper + MetronomeEngine integration (checkpoint PASSED)

### Phase 02: iOS App MVP
**Goal:** Functional iOS app proving end-to-end architecture
**Delivers:** SwiftUI app with visual indicator, background audio support
**Requirements:** Visual beat indicator, background audio, downbeat accent
**Architecture:** @Observable ViewModels, AVAudioSession management
**Depends on:** Phase 01 (Core Engine)
**Risk mitigation:** Addresses audio session mismanagement (Pitfall #3)
**Research:** Standard SwiftUI/MVVM patterns

### Phase 03: Advanced Features
**Goal:** Differentiating features that depend on audio timing engine
**Delivers:** Statistical tap tempo, haptic output, flashlight sync, multi-output coordination
**Requirements:** Advanced tap tempo (8-tap window, outlier rejection), haptics, flashlight, mode toggles
**Depends on:** Phase 02 (iOS App MVP)
**Risk mitigation:** Addresses tap tempo noise (Pitfall #5), Core Haptics lifecycle (Pitfall #7)
**Research:** May need Core Haptics scheduled mode timing research

### Phase 04: Cross-Platform Expansion
**Goal:** macOS and watchOS apps with platform-specific adaptations
**Delivers:** macOS app, watchOS app (haptic-primary mode)
**Requirements:** macOS support, watchOS support, Digital Crown control
**Architecture:** Watch as companion/controller, not standalone
**Depends on:** Phase 03 (Advanced Features)
**Risk mitigation:** Addresses platform abstraction (Pitfall #12), watch battery (Pitfall #9)
**Research:** May need watchOS background audio verification

### Phase 05: Ecosystem Integration
**Goal:** Apple ecosystem features leveraging stable state system
**Delivers:** Home Screen widgets, Lock Screen widgets, Shortcuts integration, watchOS complications
**Requirements:** Widgets (preset launchers), Shortcuts ("Start at 120 BPM")
**Architecture:** WidgetKit, App Intents, App Groups for data sharing
**Depends on:** Phase 04 (Cross-Platform)
**Risk mitigation:** Addresses widget expectations (Pitfall #6), Shortcuts fragility (Pitfall #10)
**Design decision:** Widgets as launchers, not live displays (system limits 40-70 refreshes/day)
**Research:** May need WidgetKit capability check for interactive tap tempo

### Phase 06: Polish and Launch
**Goal:** Feature-complete, App Store ready
**Delivers:** Time signatures, subdivisions, sound selection, dark mode, App Store submission
**Requirements:** Common time signatures, subdivisions, multiple sounds, polish
**Depends on:** Phase 05 (Ecosystem Integration)
**Risk mitigation:** Addresses App Store rejection (Pitfall #11)
**Includes:** Pre-submission checklist, permission timing (no camera permission on launch)
**Research:** Standard App Store preparation

## Progress

| Phase | Status | Plans | Completion |
|-------|--------|-------|------------|
| 01 | ✓ Complete | 3/3 | 100% |
| 02 | ○ Pending | 0/? | 0% |
| 03 | ○ Pending | 0/? | 0% |
| 04 | ○ Pending | 0/? | 0% |
| 05 | ○ Pending | 0/? | 0% |
| 06 | ○ Pending | 0/? | 0% |

## Requirement Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| BPM control (30-300) | 01 | ✓ Complete |
| Basic tap tempo | 01 | ✓ Complete |
| Audio output with accent | 01 | ✓ Complete |
| Visual beat indicator | 02 | ○ Pending |
| Background audio | 02 | ○ Pending |
| Advanced tap tempo (statistical) | 03 | ○ Pending |
| Haptic vibration | 03 | ○ Pending |
| Flashlight sync | 03 | ○ Pending |
| Multi-output toggles | 03 | ○ Pending |
| macOS app | 04 | ○ Pending |
| watchOS app | 04 | ○ Pending |
| Home Screen widgets | 05 | ○ Pending |
| Shortcuts integration | 05 | ○ Pending |
| Time signatures | 06 | ○ Pending |
| Subdivisions | 06 | ○ Pending |
| Sound selection | 06 | ○ Pending |

---
*Roadmap created: 2026-01-21*
*Last updated: 2026-01-21 — Phase 01 Complete*
