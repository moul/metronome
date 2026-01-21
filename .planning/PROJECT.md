# Metronome

## What This Is

A minimal yet powerful metronome app for Apple platforms (iOS, macOS, watchOS) that looks simple but packs professional-grade features under the hood. Focused on precision timing, advanced tap tempo with statistical analysis, and multiple output modes for different practice scenarios.

## Core Value

**Precise, reliable timing that musicians can trust.** If everything else fails, the metronome must keep perfect time — no drift, no glitches, no excuses.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. -->

**Core Timing:**
- [ ] BPM control (30-300 range) with precise audio output
- [ ] Visual beat indicator (pulsating, number display)
- [ ] Background audio support (keeps playing when screen locks)
- [ ] Downbeat accent (first beat distinct)

**Advanced Tap Tempo:**
- [ ] Statistical analysis of taps (not just last 2)
- [ ] 8-tap rolling window with outlier rejection
- [ ] Median filtering for accuracy
- [ ] Confidence indicator (shows when tempo is stable)

**Multi-Output Modes:**
- [ ] Audio output (click sound with accent)
- [ ] Visual output (screen flash/pulse)
- [ ] Haptic vibration (iOS only)
- [ ] Flashlight sync (camera LED on beat)
- [ ] All modes toggleable independently

**Apple Ecosystem:**
- [ ] iOS app (primary target)
- [ ] macOS app (shared codebase)
- [ ] watchOS app (haptic-primary mode)
- [ ] Home Screen widgets (quick-launch presets)
- [ ] Shortcuts integration ("Start at 120 BPM")

**Polish:**
- [ ] Common time signatures (4/4, 3/4, 6/8, etc.)
- [ ] Basic subdivisions (quarter, eighth, 16th notes)
- [ ] Multiple click sounds (6+ options)
- [ ] Save/recall tempo presets

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- **Tuner** — Separate use case, causes feature creep
- **MIDI/Ableton Link sync** — High complexity, niche audience, defer to v2+
- **Polyrhythms** — Advanced feature, high complexity, defer to v2+
- **Setlist management** — Live performance workflow, not core metronome
- **Practice tracker with analytics** — Separate concern from core metronome
- **Tempo trainer (auto-increment)** — Nice-to-have for v2, not differentiating
- **Social features** — Metronome is solitary practice tool
- **Subscriptions** — One-time purchase or freemium model only
- **Ads** — Breaks concentration during practice

## Context

This project reimagines an existing Go CLI metronome (`moul.io/metronome`) as a native Apple app. The CLI is simple and functional but lacks the visual feedback, haptic integration, and platform features that make a great mobile metronome.

**Design philosophy:** "Most powerful yet simple-looking app" — dense functionality behind a clean, minimal interface. Default view shows only BPM, tap button, and start/stop. Advanced features revealed through swipe/gesture or settings.

**Technical foundation:** Research confirmed AVAudioEngine with sample-accurate scheduling is the proven approach (Apple's "Hello Metronome" sample uses this). Real-time audio code must be Objective-C to avoid Swift runtime overhead.

**Market insight:** Users abandon metronome apps due to timing drift, overwhelming UI, subscription models, and missing background audio. The bar for "table stakes" is high.

## Constraints

- **Tech stack**: Swift 6.2 + SwiftUI + AVAudioEngine + Core Haptics + WidgetKit + App Intents
- **Minimum targets**: iOS 17, macOS 14, watchOS 10 (covers 85%+ devices, provides @Observable)
- **Deadline**: Build with iOS 26 SDK by April 2026 (Apple requirement)
- **No external dependencies**: Standard Apple frameworks cover all requirements
- **Audio precision**: Must maintain sub-millisecond accuracy across all BPMs
- **Bluetooth limitation**: 126-220ms latency with wireless audio — must warn users or provide latency compensation

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Objective-C for audio callbacks | Swift runtime overhead breaks real-time audio timing | — Pending |
| Single multiplatform target | Xcode 14+ pattern maximizes code sharing | — Pending |
| Swift Package for core logic | Testable, platform-independent, clean architecture | — Pending |
| Widgets as launchers not live displays | System limits to 40-70 refreshes/day | — Pending |
| Watch as companion not standalone | Battery constraints make standalone audio impractical | — Pending |

---
*Last updated: 2026-01-21 after initial project definition*
