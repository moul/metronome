# Project Research Summary

**Project:** Metronome (iOS/macOS/watchOS)
**Domain:** Precision timing audio application for Apple platforms
**Researched:** 2026-01-21
**Confidence:** HIGH

## Executive Summary

Building a cross-platform Apple metronome app requires treating audio timing as a first-class architectural concern. The research reveals that sample-accurate audio scheduling demands low-level code (Objective-C/C) in the audio callback path, while Swift and SwiftUI handle business logic and UI. The recommended stack centers on SwiftUI for cross-platform UI, AVAudioEngine with AVAudioPlayerNode for precision audio, Core Haptics for synchronized haptic feedback, and WidgetKit/App Intents for ecosystem integration. This aligns with Apple's 2025-2026 best practices and the April 2026 iOS 26 SDK requirement.

The key differentiators for this project are achievable but require careful implementation: advanced tap tempo with statistical analysis (outlier rejection, median filtering) goes beyond the simple 2-tap average most apps use, and multi-output synchronization (audio/visual/haptic/flashlight) demands a unified timing architecture. The research validates that professional metronome apps achieve sub-millisecond accuracy using AVAudioEngine's render time as master clock - this is a solved problem with well-documented patterns.

The primary risks are (1) violating audio thread rules which causes rewrites, (2) Bluetooth latency breaking multi-modal sync (126-220ms delay with AirPods), and (3) widget refresh limitations frustrating users expecting real-time display. Mitigation: audio engine in Objective-C from day one, warn users about Bluetooth latency, and design widgets as launchers not live displays.

## Key Findings

### Recommended Stack

The stack is well-established for precision audio apps. SwiftUI (iOS 17+) provides cross-platform UI with ~80% code sharing. AVAudioEngine with AVAudioPlayerNode enables sample-accurate timing - the same approach Apple's own "Hello Metronome" sample uses. Modern Swift 6.2 with `@Observable` eliminates boilerplate. No external dependencies needed; the standard Apple frameworks cover all requirements.

**Core technologies:**
- **SwiftUI** (iOS 17+): Cross-platform UI - single codebase across iOS/macOS/watchOS
- **AVAudioEngine + AVAudioPlayerNode**: Precision audio - sample-accurate scheduling, buffer-based playback
- **Core Haptics (CHHapticEngine)**: Haptic feedback - custom patterns, audio sync via scheduled mode
- **WidgetKit**: Widgets and complications - unified framework for Home Screen, Lock Screen, watchOS
- **App Intents**: Shortcuts integration - in-process execution, no extension needed (iOS 16+)
- **Swift 6.2 + @Observable**: Modern patterns - async/await, strict concurrency, less boilerplate

**Critical version requirements:**
- iOS 17.0 / macOS 14.0 / watchOS 10.0 minimum (covers 85%+ devices)
- Build with Xcode 26+ and iOS 26 SDK (required by April 2026)
- Swift Package Manager exclusively (CocoaPods sunset Dec 2026)

### Expected Features

**Must have (table stakes):**
- BPM control (30-300) with tap tempo
- Audio output with downbeat accent
- Visual beat indicator
- Background audio support
- Time signatures (4/4 minimum, common signatures expected)
- Subdivisions (quarter, eighth, 16th notes)

**Should have (competitive/differentiators):**
- Advanced tap tempo with statistical analysis (outlier rejection, confidence indicator)
- Multi-output modes (audio + visual + haptic + flashlight simultaneously)
- Apple Watch haptic metronome
- Home Screen widgets (quick start, preset tempos)
- Shortcuts integration ("Start metronome at 120 BPM")

**Defer (v2+):**
- Setlist management (live performance workflow)
- Polyrhythms (high complexity, niche audience)
- MIDI/Ableton Link sync (pro integration, significant effort)
- Tempo trainer (auto-increment BPM)
- Practice tracker with analytics

### Architecture Approach

The recommended architecture uses a shared Swift Package for platform-agnostic core logic (BPM calculations, tap-tempo statistics, timing engine) with platform-specific app targets for UI. The critical insight is that real-time audio code must be in Objective-C to avoid Swift runtime overhead in audio callbacks. App Groups enable data sharing between main app, widgets, and extensions.

**Major components:**
1. **MetronomeCore (Swift Package)** — BPM logic, tap-tempo statistical analysis, output coordination
2. **AudioEngine (Objective-C)** — AVAudioEngine setup, sample-accurate buffer scheduling, real-time safe
3. **ViewModels (@Observable)** — State management, coordinate outputs, platform-agnostic business logic
4. **Views (SwiftUI)** — Cross-platform UI with adaptive layouts, minimal #if os() usage
5. **Platform Controllers** — iOS: Core Haptics + Flashlight, macOS: Menu bar, watchOS: Digital Crown + complications
6. **Widget Extension (WidgetKit)** — Static display of saved tempos, quick-launch presets

### Critical Pitfalls

1. **Audio thread violations** — Never use Swift/Objective-C runtime, locks, or memory allocation in audio callbacks. Use C/Objective-C for audio code, pre-allocate all buffers. Get this wrong = complete rewrite.

2. **Incorrect buffer scheduling** — AVAudioPlayerNode completion handlers fire too late. Use timer-based scheduling, pre-schedule 2-3 beats ahead, use render time as master clock. Study Apple's "Hello Metronome" pattern.

3. **Audio session mismanagement** — Must configure `.playback` category AND activate session. Handle interruptions properly (phone calls, alarms). No guarantee of interruption-end notification - use foreground state as fallback.

4. **Bluetooth audio latency** — AirPods add 126-220ms latency. Visual/haptic sync breaks. Mitigation: warn users, recommend wired audio for precision work, consider latency compensation setting.

5. **Widget refresh limitations** — 40-70 refreshes per day, system-controlled timing. Widgets cannot show "live" BPM. Design as launcher with preset tempos, not real-time display.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Core Engine (Foundation)
**Rationale:** Audio timing is the hardest problem and foundational to everything else. Must be correct from the start - errors here cause rewrites.
**Delivers:** Working metronome engine with sample-accurate timing, basic tap tempo
**Addresses:** BPM control, audio output, basic tap tempo (table stakes)
**Avoids:** Audio thread violations (Pitfall #1), incorrect buffer scheduling (Pitfall #2)
**Architecture:** MetronomeCore package + Objective-C audio engine

### Phase 2: iOS App MVP
**Rationale:** Prove the architecture end-to-end on primary platform before expanding. iOS has fullest feature set (haptics, flashlight).
**Delivers:** Functional iOS app with core metronome, visual indicator, background audio
**Uses:** SwiftUI, @Observable ViewModels, AVAudioSession
**Implements:** Views, ViewModels, audio session management
**Avoids:** Audio session mismanagement (Pitfall #3)

### Phase 3: Advanced Features
**Rationale:** Now that core works, add differentiating features that depend on audio timing engine
**Delivers:** Statistical tap tempo, haptic output, flashlight sync, multi-output coordination
**Addresses:** Advanced tap tempo (differentiator), multi-output modes (differentiator)
**Avoids:** Tap tempo done wrong (Pitfall #5), Core Haptics lifecycle issues (Pitfall #7)
**Note:** Bluetooth latency warning should be added here

### Phase 4: Cross-Platform Expansion
**Rationale:** Core architecture proven on iOS. Expand to macOS and watchOS with platform-specific adaptations.
**Delivers:** macOS app (menu bar optional), watchOS app (haptic-primary)
**Implements:** Platform abstractions, watchOS complications
**Avoids:** macOS/iOS code sharing issues (Pitfall #12), watchOS battery drain (Pitfall #9)
**Architecture decision:** Watch as controller/companion, not standalone metronome

### Phase 5: Ecosystem Integration
**Rationale:** App is solid, now integrate with Apple ecosystem. Requires stable preset/state system.
**Delivers:** Home Screen widgets, Lock Screen widgets, Shortcuts integration, watchOS complications
**Uses:** WidgetKit, App Intents, App Groups
**Avoids:** Widget real-time expectations (Pitfall #6), Shortcuts fragility (Pitfall #10)
**Design:** Widgets as launchers with preset tempos, not live displays

### Phase 6: Polish and Launch
**Rationale:** Feature-complete, focus on UX refinement, additional time signatures, sound options
**Delivers:** Multiple time signatures, subdivisions, sound selection, dark mode, App Store ready
**Avoids:** App Store rejection issues (Pitfall #11)
**Includes:** Pre-submission checklist, permission timing (no camera permission on launch)

### Phase Ordering Rationale

- **Audio engine first:** Every feature depends on accurate timing. Technical risk must be retired early.
- **iOS before cross-platform:** Prove architecture where feature set is richest, then adapt.
- **Haptics/flashlight before widgets:** Multi-output depends on timing engine; widgets depend on state system.
- **Widgets last before polish:** Widget refresh limitations mean they're "nice to have" not core differentiator.
- **Pitfall alignment:** Critical pitfalls (#1, #2, #3) addressed in early phases when architecture is malleable.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Haptic sync):** Core Haptics scheduled mode timing with audio clock needs implementation research
- **Phase 4 (watchOS):** Background audio limitations on watchOS need verification with actual device testing
- **Phase 5 (Widgets):** Interactive widget tap tempo may not be feasible - need WidgetKit capability check

Phases with standard patterns (skip research-phase):
- **Phase 1 (Audio engine):** Well-documented with Apple sample code, proven patterns
- **Phase 2 (iOS app):** Standard SwiftUI/MVVM, no unusual requirements
- **Phase 6 (Polish):** Standard App Store preparation

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official Apple docs, current 2025-2026 best practices, production-proven |
| Features | HIGH | Verified across multiple App Store apps and user reviews |
| Architecture | HIGH | Apple sample code (Hello Metronome), multiple verified implementations |
| Pitfalls | MEDIUM-HIGH | Mix of official docs (audio session) and community consensus (Bluetooth latency) |

**Overall confidence:** HIGH

### Gaps to Address

- **watchOS background audio limits:** Research says "limited" but exact constraints unclear. Test during Phase 4.
- **Bluetooth latency compensation:** Real-time measurement techniques need investigation if latency compensation feature is pursued.
- **Interactive widget tap tempo:** WidgetKit may not support the rapid interaction needed. May need to drop this feature or simplify to "tap to open app in tap tempo mode."
- **Audio Workgroups API:** Modern iOS approach for optimal thread scheduling not deeply researched. May improve performance on Apple Silicon.

## Sources

### Primary (HIGH confidence)
- [Apple Hello Metronome Sample](https://developer.apple.com/library/archive/samplecode/HelloMetronome/Introduction/Intro.html) - reference audio scheduling pattern
- [Audio Guidelines By App Type](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioGuidelinesByAppType/AudioGuidelinesByAppType.html) - audio session management
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date) - widget refresh limitations
- [App Intents Documentation](https://developer.apple.com/documentation/appintents) - Shortcuts integration
- [Four Common Mistakes in Audio Development](https://atastypixel.com/four-common-mistakes-in-audio-development/) - audio thread rules

### Secondary (MEDIUM confidence)
- [Metronome-using-AVAudioEngine](https://github.com/Alexander-Nagel/Metronome-using-AVAudioEngine) - buffer scheduling patterns
- [AirPods Pro 2 Audio Latency](https://stephencoyle.net/airpods-pro-2) - measured Bluetooth latency data
- [Making Sense of Time in AVAudioPlayerNode](https://medium.com/@mehsamadi/making-sense-of-time-in-avaudioplayernode-475853f84eb6) - timing deep-dive
- [ISMIR Music Tempo Estimation](https://transactions.ismir.net/articles/10.5334/tismir.43) - tap tempo algorithms

### Tertiary (LOW confidence)
- KVR Audio forums - tap tempo algorithm discussions (needs validation)
- User reports of iOS 26/watchOS 26 issues - may be transient bugs

---
*Research completed: 2026-01-21*
*Ready for roadmap: yes*
