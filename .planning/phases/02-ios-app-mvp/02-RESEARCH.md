# Phase 02: iOS App MVP - Research

**Researched:** 2026-01-21
**Domain:** SwiftUI iOS app with background audio, AVAudioSession management
**Confidence:** HIGH

## Summary

Phase 02 delivers a functional iOS app proving end-to-end architecture. The existing MetronomeCore package provides `MetronomeEngine` with `@Observable` for SwiftUI integration, `AudioScheduler` protocol, and the Objective-C `AudioEngine` with sample-accurate timing. This phase connects these components to a SwiftUI interface with visual beat indication, background audio support, and proper audio session management.

The research confirms SwiftUI patterns with `@Observable` (iOS 17+), `AVAudioSession` configuration for `.playback` category, and visual beat indicator approaches using scale/opacity animations. The existing architecture (Phase 01) already handles the hard audio timing problems - Phase 02 focuses on iOS app shell, audio session lifecycle, and visual feedback.

**Primary recommendation:** Create a minimal SwiftUI app structure with a single `@Observable` ViewModel that wraps `MetronomeEngine`, configure `AVAudioSession` for background playback before audio starts, and implement visual beat indicator using SwiftUI's animation system driven by `currentBeat` changes from the engine.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | UI framework | Native declarative UI, `@Observable` support, single codebase |
| AVFoundation | iOS 17+ | Audio session | `AVAudioSession` for background audio, interruption handling |
| Observation | Swift 5.9+ | State management | `@Observable` macro replaces `ObservableObject`, granular updates |
| MetronomeCore | Local | Business logic | Existing package with `MetronomeEngine`, `BPM`, `TapTempo` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AVAudioEngine | iOS 13+ | Audio playback | Already implemented in Objective-C AudioEngine |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@Observable` | `ObservableObject` | Requires iOS 14+, more boilerplate, less granular updates |
| SwiftUI | UIKit | More code, no cross-platform potential, but more control |
| TimelineView for beats | State animation | TimelineView better for continuous animation, but state-driven is simpler for beat pulses |

**Installation:**
```bash
# No external dependencies needed
# MetronomeCore is local Swift Package
```

## Architecture Patterns

### Recommended Project Structure
```
Metronome.xcodeproj/
Metronome/
  MetronomeApp.swift           # @main entry point
  ContentView.swift            # Main metronome UI
  ViewModels/
    MetronomeViewModel.swift   # Wraps MetronomeEngine, manages audio session
  Views/
    BeatIndicatorView.swift    # Visual pulse on beat
    BPMControlView.swift       # Slider/stepper for BPM
    PlayPauseButton.swift      # Start/stop control
    TapTempoButton.swift       # Tap tempo UI
  Audio/
    AudioSessionManager.swift  # AVAudioSession configuration
    AudioEngine.h              # (existing)
    AudioEngine.m              # (existing)
    AudioEngine-Bridging.swift # (existing)
  Resources/
    click.wav                  # (existing)
    accent.wav                 # (existing)
  Metronome-Bridging-Header.h  # (existing)
MetronomeCore/                 # (existing Swift Package)
```

### Pattern 1: @Observable ViewModel Wrapping MetronomeEngine

**What:** ViewModel that owns MetronomeEngine and AudioEngineBridge, exposes observable state to SwiftUI.

**When to use:** Always - this is the standard pattern for Phase 02.

**Example:**
```swift
// Source: Phase 01 MetronomeEngine + @Observable patterns from nilcoalescing.com
import SwiftUI
import MetronomeCore

@MainActor
@Observable
final class MetronomeViewModel {
    // Expose engine state
    var bpm: Int { engine.currentBPM.value }
    var isPlaying: Bool { engine.isPlaying }
    var currentBeat: Int { engine.currentBeat }
    var isAccent: Bool { engine.isAccent }

    private let engine: MetronomeEngine
    private let audioBridge: AudioEngineBridge
    private let sessionManager: AudioSessionManager

    init() {
        self.engine = MetronomeEngine()
        self.audioBridge = AudioEngineBridge()
        self.sessionManager = AudioSessionManager()

        // Wire up audio scheduler
        engine.setAudioScheduler(audioBridge)
    }

    func start() throws {
        sessionManager.configureForPlayback()
        try loadSoundsIfNeeded()
        try engine.start()
    }

    func stop() {
        engine.stop()
    }

    func setBPM(_ value: Int) {
        if let bpm = BPM(value: value) {
            engine.setBPM(bpm)
        }
    }

    func recordTap() {
        engine.recordTap()
    }
}
```

### Pattern 2: SwiftUI App Entry Point with Environment

**What:** `@main` struct conforming to `App` protocol, injecting ViewModel via environment.

**When to use:** App entry point.

**Example:**
```swift
// Source: Apple SwiftUI App documentation + nilcoalescing.com
import SwiftUI

@main
struct MetronomeApp: App {
    @State private var viewModel = MetronomeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}

struct ContentView: View {
    @Environment(MetronomeViewModel.self) private var viewModel

    var body: some View {
        VStack {
            BeatIndicatorView()
            BPMControlView()
            PlayPauseButton()
            TapTempoButton()
        }
    }
}
```

### Pattern 3: Visual Beat Indicator with Scale/Opacity Animation

**What:** View that pulses on beat changes using SwiftUI animation.

**When to use:** Displaying visual beat feedback.

**Example:**
```swift
// Source: hackingwithswift.com/books/ios-swiftui/customizing-animations-in-swiftui
struct BeatIndicatorView: View {
    @Environment(MetronomeViewModel.self) private var viewModel
    @State private var animationTrigger = false

    var body: some View {
        ZStack {
            // Beat number display
            Text("\(viewModel.currentBeat + 1)")
                .font(.system(size: 72, weight: .bold))

            // Pulsing circle
            Circle()
                .stroke(viewModel.isAccent ? Color.red : Color.blue, lineWidth: 4)
                .scaleEffect(animationTrigger ? 1.5 : 1.0)
                .opacity(animationTrigger ? 0.0 : 1.0)
                .animation(.easeOut(duration: 0.3), value: animationTrigger)
        }
        .frame(width: 150, height: 150)
        .onChange(of: viewModel.currentBeat) { _, _ in
            // Trigger animation on each beat
            animationTrigger = true
            // Reset for next beat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animationTrigger = false
            }
        }
    }
}
```

### Pattern 4: AVAudioSession Configuration for Background Audio

**What:** Configure audio session before starting playback to enable background audio.

**When to use:** Before calling `engine.start()`.

**Example:**
```swift
// Source: Apple AVAudioSession documentation, mux.com/blog/background-audio-handling
import AVFoundation

class AudioSessionManager {
    private var isConfigured = false

    func configureForPlayback() {
        guard !isConfigured else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            // .playback category enables background audio
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            isConfigured = true
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func deactivate() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
            isConfigured = false
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}
```

### Anti-Patterns to Avoid

- **Calling MetronomeEngine methods directly from View:** Use ViewModel as intermediary
- **Configuring AVAudioSession after engine.start():** Configure before starting
- **Using Timer for visual animation timing:** Use SwiftUI's `onChange` with engine state
- **Activating audio session on app launch:** Wait for user action (start button)
- **Not handling audio session errors:** Always catch and log errors

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Beat timing | Custom Timer | MetronomeEngine callbacks | Engine already handles sample-accurate timing |
| Observable state | Manual bindings | @Observable macro | Automatic property tracking |
| Background audio | Custom code | AVAudioSession.playback | Apple's standard approach |
| Audio scheduling | scheduleBuffer loops | Existing AudioEngine | Phase 01 solved this |
| Pulse animation | CADisplayLink | SwiftUI .animation | Declarative, simpler |

**Key insight:** Phase 01 already solved the hard audio timing problems. Phase 02 connects the existing engine to UI - don't reimplement timing logic.

## Common Pitfalls

### Pitfall 1: Audio Session Not Activated Before Starting Engine

**What goes wrong:** Metronome doesn't play, or stops immediately when app backgrounds.

**Why it happens:** `AVAudioSession.setActive(true)` not called before `engine.start()`.

**How to avoid:** Always configure and activate audio session in ViewModel before starting engine.

**Warning signs:** Works in foreground, stops when screen locks.

### Pitfall 2: Audio Session Category Wrong

**What goes wrong:** Audio stops in background, or interferes with other apps incorrectly.

**Why it happens:** Using `.ambient` or `.soloAmbient` instead of `.playback`.

**How to avoid:** Use `.playback` category - it's designed for apps where audio is the primary feature.

**Warning signs:** Audio stops when screen locks; other audio apps interrupted unexpectedly.

### Pitfall 3: Not Handling Audio Interruptions

**What goes wrong:** Metronome doesn't resume after phone call or alarm.

**Why it happens:** Not observing `AVAudioSession.interruptionNotification`.

**How to avoid:** Register for interruption notifications, check `shouldResume` flag before auto-resuming.

**Warning signs:** After phone call ends, user must manually restart metronome.

### Pitfall 4: Background Mode Capability Not Enabled

**What goes wrong:** Audio stops immediately when app moves to background.

**Why it happens:** "Audio, AirPlay, and Picture in Picture" not enabled in Xcode capabilities.

**How to avoid:** Enable capability in Xcode: Project > Target > Signing & Capabilities > + Background Modes > Audio.

**Warning signs:** Audio plays fine in foreground, stops instantly on backgrounding.

### Pitfall 5: Visual Animation Not Synced with Beat Callback

**What goes wrong:** Visual indicator doesn't match audio beats.

**Why it happens:** Using separate timer instead of reacting to `engine.currentBeat` changes.

**How to avoid:** Use `onChange(of: viewModel.currentBeat)` to trigger animation.

**Warning signs:** Visual and audio drift apart over time.

## Code Examples

Verified patterns from official sources:

### Audio Session Configuration (Complete)
```swift
// Source: Apple documentation + mux.com/blog/background-audio-handling
import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    func configureForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        // Register for interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Audio was interrupted - engine handles this automatically
            break
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Safe to resume - post notification for ViewModel to restart
                NotificationCenter.default.post(name: .audioInterruptionEnded, object: nil)
            }
        @unknown default:
            break
        }
    }
}

extension Notification.Name {
    static let audioInterruptionEnded = Notification.Name("audioInterruptionEnded")
}
```

### SwiftUI View with @Bindable for Controls
```swift
// Source: nilcoalescing.com/blog/ObservableInSwiftUI + donnywals.com
struct BPMControlView: View {
    @Environment(MetronomeViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 20) {
            Text("\(viewModel.bpm) BPM")
                .font(.largeTitle)

            Slider(
                value: Binding(
                    get: { Double(viewModel.bpm) },
                    set: { viewModel.setBPM(Int($0)) }
                ),
                in: 30...300,
                step: 1
            )
            .padding(.horizontal)

            HStack(spacing: 40) {
                Button("-") { viewModel.decrementBPM() }
                    .font(.title)
                Button("+") { viewModel.incrementBPM() }
                    .font(.title)
            }
        }
    }
}
```

### Loading Sound Resources
```swift
// Source: Phase 01 AudioEngineBridge pattern
extension MetronomeViewModel {
    private func loadSoundsIfNeeded() throws {
        guard let clickURL = Bundle.main.url(forResource: "click", withExtension: "wav"),
              let accentURL = Bundle.main.url(forResource: "accent", withExtension: "wav") else {
            throw AudioSchedulerError.failedToLoadSounds
        }
        try audioBridge.loadSounds(clickURL: clickURL, accentURL: accentURL)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ObservableObject + @Published | @Observable macro | iOS 17 (2023) | Less boilerplate, granular updates |
| AppDelegate lifecycle | SwiftUI App protocol | iOS 14 (2020) | Declarative app structure |
| @ObservedObject in views | @Environment with @Observable | iOS 17 (2023) | Cleaner dependency injection |
| UIViewRepresentable for animations | Native SwiftUI animations | iOS 17+ | Better integration |

**Deprecated/outdated:**
- `ObservableObject` + `@Published`: Still works but more boilerplate than `@Observable`
- `@ObservedObject`: Use `@Environment` or `let` for `@Observable` classes
- `environmentObject()`: Use `.environment()` for `@Observable` classes

## Open Questions

Things that couldn't be fully resolved:

1. **Xcode project structure with local Swift Package**
   - What we know: Need to add MetronomeCore as local package dependency
   - What's unclear: Whether sibling directory works or needs to be subdirectory
   - Recommendation: Add as subdirectory or use File > Add Package Dependencies > Add Local

2. **Bridging header configuration in new Xcode project**
   - What we know: Bridging header exists at `Metronome/Metronome-Bridging-Header.h`
   - What's unclear: Build settings path format needed
   - Recommendation: Set "Objective-C Bridging Header" to `$(SRCROOT)/Metronome/Metronome-Bridging-Header.h`

3. **Audio interruption handling across iOS versions**
   - What we know: Behavior varies; "ended" notification not always sent
   - What's unclear: Current iOS 17+ specific behavior
   - Recommendation: Handle both notification and foreground return as resume triggers

## Sources

### Primary (HIGH confidence)
- Phase 01 code: `MetronomeCore/`, `Metronome/Audio/` - Existing implementation
- [Migrating to the Observable macro](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro) - Official Apple docs
- [AVAudioSession.playback](https://developer.apple.com/documentation/avfoundation/avaudiosession/category/1616509-playback) - Official Apple docs
- [Configuring background execution modes](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes) - Official Apple docs

### Secondary (MEDIUM confidence)
- [Using @Observable in SwiftUI views](https://nilcoalescing.com/blog/ObservableInSwiftUI/) - Developer tutorial with code examples
- [@Observable in SwiftUI explained](https://www.donnywals.com/observable-in-swiftui-explained/) - Detailed patterns
- [Background audio handling with iOS AVPlayer](https://www.mux.com/blog/background-audio-handling-with-ios-avplayer) - Audio session patterns
- [Customizing animations in SwiftUI](https://www.hackingwithswift.com/books/ios-swiftui/customizing-animations-in-swiftui) - Pulse animation pattern

### Tertiary (LOW confidence)
- N/A - All patterns verified with authoritative sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using existing Phase 01 code + standard SwiftUI patterns
- Architecture: HIGH - Standard MVVM + @Observable, verified with official docs
- Pitfalls: HIGH - Audio session issues well documented in PITFALLS.md

**Research date:** 2026-01-21
**Valid until:** 2026-02-21 (30 days - stable domain)
