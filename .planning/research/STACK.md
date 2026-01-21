# Technology Stack

**Project:** Metronome (iOS/macOS/watchOS)
**Researched:** 2026-01-21
**Confidence:** HIGH

## Executive Summary

For a 2025/2026 cross-platform Apple metronome app, the standard stack centers on **SwiftUI** for UI (with unified support across iOS 26, macOS 26, watchOS 26), **AVAudioEngine** for precise audio timing, **Core Haptics** for haptic feedback, **WidgetKit** for widgets and complications, and **App Intents** for Shortcuts integration. Swift 6.2 with strict concurrency checking provides modern async/await patterns. This stack represents current Apple best practices and is well-positioned for the April 2026 SDK requirements.

---

## Recommended Stack

### Core Language & Tools

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Swift** | 6.2+ | Primary language | Modern concurrency (async/await, actors), strict compile-time safety, required for Swift Testing framework. Swift 6.2 (released Sept 2025) adds single-threaded-by-default mode and @concurrent attribute for explicit parallelism. |
| **Xcode** | 26.2+ | IDE & build system | Latest stable (Dec 2025). Includes AI assistant (ChatGPT integration), 24% smaller download, 40% faster workspace loading. Required for iOS 26 SDK by April 2026 App Store mandate. |
| **Swift Package Manager** | Built-in (Xcode 26) | Dependency management | Industry standard as of 2025. CocoaPods becomes read-only Dec 2026, making SPM the only maintained option. Tight Xcode integration, semantic versioning, can reduce build times by 30%. |

**Confidence:** HIGH - Current stable releases, official Apple requirements for 2026.

**Sources:**
- [Xcode 26 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes)
- [State of Swift 2026](https://devnewsletter.com/p/state-of-swift-2026)
- [Swift Package Manager in 2025](https://commitstudiogs.medium.com/whats-new-in-swift-package-manager-spm-for-2025-d7ffff2765a2)
- [CocoaPods Transition](https://jfrog.com/blog/swiftpm-cocoapods-enterprise-development-apple-platforms/)

### UI Framework

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **SwiftUI** | iOS 26+ | Cross-platform UI | THE standard for new Apple apps in 2025/2026. Declarative syntax, single codebase across iOS/macOS/watchOS. Apple's unified "26" versioning (covering 2025-2026) ensures API consistency across platforms. Mature enough for production with enterprise apps now using it. |

**NOT UIKit** - UIKit is not being deprecated, but SwiftUI is the recommended framework for new projects. SwiftUI enables ~80% code sharing across platforms vs UIKit's platform-specific implementations. UIKit should only be considered if you need UIKit-specific APIs not yet available in SwiftUI (rare in 2025).

**Confidence:** HIGH - SwiftUI is explicitly positioned as "the future" by Apple, with watchOS fully SwiftUI-native since watchOS 6.

**Sources:**
- [SwiftUI in 2025: Why It's Powerful](https://medium.com/@k.keawjunchai/swiftui-in-2025-why-its-powerful-but-still-not-for-everyone-3f5a324e577e)
- [UIKit vs SwiftUI in 2026](https://medium.com/@chandra.welim/uikit-vs-swiftui-in-2026-the-honest-truth-b742eb3d3525)
- [iOS 26 Explained](https://www.index.dev/blog/ios-26-developer-guide)

### Audio Engine (Critical for Metronome)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **AVAudioEngine** | iOS 13+ | Precise audio timing | Required for sample-accurate metronome timing. Higher-level APIs (AVAudioPlayer, system sounds) lack the precision needed for professional metronomes. AVAudioEngine with AVAudioPlayerNode enables scheduling audio buffers with sub-millisecond accuracy using `scheduleBuffer(at:options:completionHandler:)`. |
| **AVAudioPlayerNode** | iOS 13+ | Audio playback scheduling | Companion to AVAudioEngine. Provides precise time-domain control (render time, node time, sample time). Apple's "Hello Metronome" sample code uses this approach. |
| **AVFoundation** | iOS 16+ | Audio session management | Background audio support, audio interruption handling, mixing with other apps. Configure audio session category as `.playback` with `.mixWithOthers` option. |

**NOT Timer/DispatchSourceTimer** - High-level timers become unstable in background (timing slows, then recovers). Audio subsystem's real-time callbacks are the only reliable approach for precision timing.

**NOT Audio Queue Services or Raw Audio Units** - Unnecessarily low-level for modern Swift development. AVAudioEngine provides sufficient control while remaining Swifty.

**Confidence:** HIGH - Industry standard for precision audio apps. Multiple production metronome apps use this stack.

**Sources:**
- [Apple Hello Metronome Sample](https://developer.apple.com/library/archive/samplecode/HelloMetronome/Introduction/Intro.html)
- [Sample-accurate Metronome using AVAudioEngine](https://github.com/Alexander-Nagel/Metronome-using-AVAudioEngine)
- [Making Sense of Time in AVAudioPlayerNode](https://medium.com/@mehsamadi/making-sense-of-time-in-avaudioplayernode-475853f84eb6)
- [iOS Timer Precision Issues](https://developer.apple.com/forums/thread/772060)

### Haptic Feedback

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Core Haptics (CHHapticEngine)** | iOS 13+ | Custom haptic patterns | Enables sophisticated haptic compositions with precise control over intensity, sharpness, timing, duration. Can synchronize haptics with audio beats for a unified sensory experience. Perfect for metronome's rhythmic feedback. |
| **UIImpactFeedbackGenerator** | iOS 10+ | Simple haptic triggers | Fallback for basic haptics on older devices or for quick UI feedback. Use for non-rhythmic interactions (button taps, gesture confirmations). |

**When to use each:**
- **CHHapticEngine**: Metronome beats (precise timing, audio sync, pattern creation)
- **UIImpactFeedbackGenerator**: UI interactions (settings changes, button presses)

**Confidence:** HIGH - Core Haptics is the standard for rhythm apps since iOS 13.

**Sources:**
- [CHHapticEngine Documentation](https://developer.apple.com/documentation/corehaptics/chhapticengine)
- [Haptic Feedback in iOS: Comprehensive Guide](https://medium.com/@mi9nxi/haptic-feedback-in-ios-a-comprehensive-guide-6c491a5f22cb)
- [Core Haptics: Coding Sensory Experiences](https://medium.com/appledeveloperacademy-ufpe/core-haptics-coding-sensory-experiences-with-vibrations-5fe245b4a743)

### Widgets & Complications

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **WidgetKit** | iOS 16+ | Home Screen widgets, Lock Screen widgets, watchOS complications | Unified framework for all widget types since watchOS 9. Single codebase serves iOS Home Screen, iOS Lock Screen, and watchOS complications. Replaced ClockKit for watch complications in 2022. |
| **App Intents** | iOS 16+ | Interactive widgets, configuration | Modern approach for widget interactivity and configuration. Integrates with Shortcuts, Spotlight, Action button. Required for iOS 26's App Intent features. |

**Widget Families for Metronome:**
- **iOS**: `accessoryRectangular` (Lock Screen), `systemSmall` (Home Screen)
- **watchOS**: `accessoryCircular`, `accessoryRectangular`, `accessoryCorner`

**NOT ClockKit** - Deprecated for watchOS complications. WidgetKit provides automatic migration path.

**Confidence:** HIGH - WidgetKit is the only supported path forward for complications as of watchOS 9 (2022).

**Sources:**
- [Creating accessory widgets and watch complications](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications)
- [Complications and widgets: Reloaded WWDC22](https://developer.apple.com/videos/play/wwdc2022/10050/)
- [Migrating ClockKit complications to WidgetKit](https://developer.apple.com/documentation/widgetkit/converting-a-clockkit-app)

### Shortcuts & Automation

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **App Intents** | iOS 16+ | Siri, Shortcuts, Spotlight, Action button integration | Gateway to Apple Intelligence and system-level integration. Announced at WWDC25 as the primary integration point across Apple's ecosystem. Enables "Start metronome at 120 BPM" voice commands, Focus Mode automation, and Action button shortcuts. |

**Example App Intents for Metronome:**
- `StartMetronomeIntent(bpm: Int)`
- `SetTempoIntent(bpm: Int)`
- `TapTempoIntent()`
- `StopMetronomeIntent()`

**Confidence:** HIGH - App Intents is the only modern path for Shortcuts integration. SiriKit is being phased out.

**Sources:**
- [App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [Get to know App Intents WWDC25](https://developer.apple.com/videos/play/wwdc2025/244/)
- [Accelerating app interactions with App Intents](https://developer.apple.com/documentation/AppIntents/AcceleratingAppInteractionsWithAppIntents)

### Architecture & Patterns

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **MVVM** | N/A | Architecture pattern | Natural fit for SwiftUI's declarative data-binding. Industry standard for SwiftUI apps in 2025. `@Observable` macro (iOS 17+) eliminates boilerplate vs old `ObservableObject`. |
| **Swift Concurrency** | Swift 5.5+ | Async operations, thread safety | Modern async/await replaces GCD/OperationQueue. `@MainActor` for UI code, `actor` for shared mutable state (audio engine, tempo settings). Swift 6.2's strict concurrency checking eliminates data races at compile time. |
| **Combine** (optional) | iOS 13+ | Reactive streams | Consider only if you need complex reactive pipelines. For most metronome use cases, Swift async/await + `@Observable` are sufficient and more modern. |

**NOT Core Data / SwiftData** - Metronome state is simple (current BPM, tap history, user preferences). UserDefaults + Codable or a lightweight settings manager suffices. Database frameworks add unnecessary complexity.

**Confidence:** HIGH - MVVM + Swift Concurrency is the dominant pattern for new SwiftUI apps.

**Sources:**
- [The Ultimate Guide to Modern iOS Architecture in 2025](https://medium.com/@csmax/the-ultimate-guide-to-modern-ios-architecture-in-2025-9f0d5fdc892f)
- [Mastering Swift Concurrency 2025](https://medium.com/@kumarsuraj19111997/mastering-swift-concurrency-async-await-tasks-actors-sendable-structured-concurrency-3dff135ce588)
- [Swift 6.2: Approachable Concurrency](https://mjtsai.com/blog/2025/11/03/swift-6-2-approachable-concurrency/)

### Testing

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Swift Testing** | Swift 6+ (Xcode 16+) | Unit tests | Apple's new testing framework (announced WWDC24). Modern async/await support, parallel test execution by default, expressive APIs. Apple recommends this for all new unit test development in 2025. |
| **XCTest** | iOS 14+ | UI tests, performance tests | Still required for UI automation (XCUIApplication) and performance testing (XCTMetric). Swift Testing doesn't support these yet as of early 2025. Use for UI tests only; migrate unit tests to Swift Testing. |

**Test Strategy:**
- **Unit tests**: Swift Testing (tempo calculations, tap-tempo statistics, BPM validation)
- **UI tests**: XCTest (widget rendering, settings screens, user flows)
- **Audio tests**: XCTest with mocked audio nodes (timing precision verification)

**Confidence:** MEDIUM - Swift Testing is very new (2024) but Apple-endorsed. XCTest remains necessary for UI testing.

**Sources:**
- [Swift Testing - Xcode](https://developer.apple.com/xcode/swift-testing)
- [Swift Testing vs. XCTest Comparison](https://blogs.infosys.com/digital-experience/mobility/swift-testing-vs-xctest-a-comprehensive-comparison.html)
- [What's new in Testing, 2025 Edition](https://rachelbrindle.com/2025/06/26/whats-new-in-testing-swift-6-2/)

### Data Persistence

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **UserDefaults** | iOS 2+ | Simple settings storage | Sufficient for metronome app (last BPM, user preferences, tap history). Synchronizes across devices via iCloud automatically if enabled. |
| **Codable** | Swift 4+ | Settings serialization | Type-safe encoding/decoding of settings structs. Built into Swift, no framework needed. |

**NOT SwiftData or Core Data** - Overkill for a metronome. These are designed for complex relational data with migrations. Metronome has simple key-value settings.

**Confidence:** HIGH - UserDefaults is the standard for simple app preferences.

---

## Platform-Specific Considerations

### iOS (iPhone)

| Feature | Technology | Notes |
|---------|-----------|-------|
| Background audio | AVFoundation audio session | Category: `.playback`, mode: `.default` |
| Lock screen controls | Now Playing Center (MPNowPlayingInfoCenter) | Display BPM, tempo name, play/pause controls |
| Flashlight | AVCaptureDevice.torchMode | For visual beat feedback |
| Haptics | CHHapticEngine | Full haptic capabilities |

### macOS

| Feature | Technology | Notes |
|---------|-----------|-------|
| Menu bar app | NSStatusItem + SwiftUI popover | Optional: Quick BPM control from menu bar |
| Keyboard shortcuts | SwiftUI `.keyboardShortcut()` | Space bar to start/stop, arrow keys for BPM |
| Sound output | AVAudioEngine (same as iOS) | Works identically on macOS |
| NO Haptics | N/A | Macs don't have Taptic Engine; skip haptic code on macOS |

### watchOS

| Feature | Technology | Notes |
|---------|-----------|-------|
| Digital Crown | WKInterfacePicker / Digital Crown events | BPM adjustment via crown rotation |
| Haptics | WKInterfaceDevice.play(.click) | Simpler than iOS; use predefined patterns |
| Complications | WidgetKit accessory families | Circular, rectangular, corner families |
| Background execution | Background audio task | Limited background audio on watchOS; test thoroughly |

---

## Deployment Targets

### Recommended Minimum Versions

| Platform | Minimum Version | Why |
|----------|----------------|-----|
| **iOS** | 17.0 | Provides access to @Observable (eliminates ObservableObject boilerplate), latest WidgetKit features. Covers ~85% of active devices (Jan 2026). Avoids iOS 18 which only covers 14.1% if set as minimum. |
| **macOS** | 14.0 (Sonoma) | Aligns with iOS 17 SDK features. |
| **watchOS** | 10.0 | WidgetKit complications, modern SwiftUI features. |

**Rationale:** Following "current minus one" rule (support latest + previous major version). iOS 17/macOS 14/watchOS 10 provide all necessary APIs while maintaining broad compatibility. You can safely target iOS 17 while building with Xcode 26 and iOS 26 SDK (required by April 2026).

**Confidence:** HIGH - Standard industry practice balancing modern features with user reach.

**Sources:**
- [iOS 26 SDK Requirements: April 2026 Deadline](https://ravi6997.medium.com/ios-26-sdk-requirements-what-developers-need-to-know-for-april-2026-16dec793c44d)
- [Picking your minimum iOS version to support](https://www.avanderlee.com/workflow/minimum-ios-version/)
- [iOS 26 Market Share Statistics](https://ioscompatibility.com/ios-26-market-share)

---

## Installation & Project Setup

### 1. Create Multi-Platform Project

```bash
# In Xcode 26:
# File > New > Project > Multiplatform > App
# Enable: iOS, macOS, watchOS
# Interface: SwiftUI
# Language: Swift
```

### 2. SPM Dependencies (if needed)

For a metronome app, you likely won't need external dependencies. But if needed:

**Package.swift example:**
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Metronome",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    dependencies: [
        // Example: Audio utilities (only if needed)
        // .package(url: "https://github.com/AudioKit/AudioKit", from: "5.6.0")
    ],
    targets: [
        .target(
            name: "Metronome",
            dependencies: []
        )
    ]
)
```

### 3. Project Structure

```
Metronome/
├── Shared/
│   ├── Models/
│   │   ├── MetronomeEngine.swift      // Audio engine wrapper
│   │   ├── TapTempoAnalyzer.swift     // Statistical tap analysis
│   │   └── MetronomeSettings.swift    // Codable settings
│   ├── ViewModels/
│   │   └── MetronomeViewModel.swift   // @Observable view model
│   └── Views/
│       ├── MetronomeView.swift        // Main UI (shared)
│       └── SettingsView.swift
├── iOS/
│   ├── MetronomeApp.swift             // iOS app entry point
│   ├── FlashlightManager.swift        // iOS-specific flashlight
│   └── Widgets/
│       └── MetronomeWidget.swift
├── macOS/
│   ├── MetronomeApp.swift             // macOS app entry point
│   └── MenuBarController.swift
├── watchOS/
│   ├── MetronomeApp.swift             // watchOS app entry point
│   └── Complications/
│       └── MetronomeComplication.swift
└── Tests/
    ├── MetronomeEngineTests.swift     // Swift Testing
    └── MetronomeUITests.swift         // XCTest (UI)
```

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| **UI Framework** | SwiftUI | UIKit/AppKit | SwiftUI is the modern standard; UIKit requires platform-specific code (no code sharing). Use UIKit only if you need APIs not in SwiftUI (rare in 2025). |
| **Audio Timing** | AVAudioEngine | DispatchSourceTimer | Timers are unreliable in background; become unstable. AVAudioEngine uses audio subsystem's real-time callbacks. |
| **Audio Timing** | AVAudioEngine | Audio Units (raw) | Too low-level for Swift. AVAudioEngine provides sufficient control with better Swift APIs. |
| **Haptics** | Core Haptics | UIFeedbackGenerator only | Core Haptics enables custom patterns, precise timing, audio sync. UIFeedbackGenerator is limited to simple impacts. |
| **Widgets** | WidgetKit | ClockKit (watchOS) | ClockKit deprecated in watchOS 9 (2022). WidgetKit is the only supported path. |
| **Shortcuts** | App Intents | SiriKit (legacy) | App Intents is the modern replacement. SiriKit being phased out. |
| **Testing** | Swift Testing | XCTest (for unit tests) | Swift Testing is Apple's recommendation for new tests. XCTest only needed for UI/performance tests. |
| **Data** | UserDefaults | Core Data / SwiftData | Metronome doesn't need relational database. UserDefaults + Codable is simpler and sufficient. |
| **Dependency Mgmt** | SPM | CocoaPods | CocoaPods becomes read-only Dec 2026. SPM is the only actively maintained option. |
| **Architecture** | MVVM | VIPER / Clean Arch | MVVM is natural fit for SwiftUI. VIPER is overkill for a focused app like metronome. |

---

## Critical Implementation Notes

### 1. Audio Timing Precision

**Problem:** Metronome must maintain sample-accurate timing across all BPMs (40-300+).

**Solution:** Use AVAudioEngine's `scheduleBuffer(at:options:completionHandler:)` with pre-calculated sample times. Never use `Timer` or `DispatchQueue.asyncAfter` for beat scheduling.

**Code Pattern:**
```swift
let sampleRate = audioEngine.mainMixerNode.outputFormat(forBus: 0).sampleRate
let samplesPerBeat = AVAudioFramePosition(sampleRate * 60.0 / Double(bpm))
let when = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: sampleRate)
audioPlayerNode.scheduleBuffer(buffer, at: when, options: [], completionHandler: nil)
```

### 2. Background Audio

**Problem:** iOS suspends apps; audio must continue.

**Solution:** Configure audio session + enable background mode.

**Required:**
1. Add "Audio, AirPlay, and Picture in Picture" background mode in Xcode capabilities
2. Configure audio session:
   ```swift
   try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
   try AVAudioSession.sharedInstance().setActive(true)
   ```

### 3. Haptic-Audio Synchronization

**Problem:** Haptics must fire in perfect sync with audio beats.

**Solution:** Use `CHHapticPattern` with `.audioContinuous` parameter type to sync with audio timeline.

**Code Pattern:**
```swift
let event = CHHapticEvent(
    eventType: .hapticTransient,
    parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
    ],
    relativeTime: timeUntilNextBeat
)
```

### 4. Cross-Platform Code Sharing

**Problem:** Maximize code reuse while handling platform differences.

**Solution:** Use `#if os()` compiler directives sparingly; prefer protocol-based abstraction.

**Example:**
```swift
protocol HapticFeedbackProvider {
    func playBeatHaptic()
}

#if os(iOS)
class iOSHapticProvider: HapticFeedbackProvider { /* CHHapticEngine */ }
#elseif os(watchOS)
class watchOSHapticProvider: HapticFeedbackProvider { /* WKInterfaceDevice */ }
#elseif os(macOS)
class macOSHapticProvider: HapticFeedbackProvider { /* No-op */ }
#endif
```

---

## Timeline Considerations

### April 2026 Deadline

**CRITICAL:** App Store requires iOS 26 SDK by April 2026. This means:
- Must use Xcode 26+
- Must build against iOS 26 SDK
- Does NOT require dropping support for older iOS versions (you can still target iOS 17 minimum)

### Swift 6 Migration

If starting now (Jan 2026), build with Swift 6.2 from day one to benefit from:
- Strict concurrency checking (eliminates data races)
- Modern async/await patterns
- Swift Testing framework compatibility

No need to support Swift 5; it's 2026.

### CocoaPods Sunset

CocoaPods Trunk becomes read-only Dec 2, 2026. Use SPM exclusively; don't start new projects with CocoaPods.

---

## Confidence Assessment

| Stack Component | Confidence | Rationale |
|----------------|-----------|-----------|
| SwiftUI | HIGH | Official recommendation, mature, cross-platform standard |
| AVAudioEngine | HIGH | Industry-standard for precision audio, proven in production metronome apps |
| Core Haptics | HIGH | De facto standard for rhythm haptics since iOS 13 |
| WidgetKit | HIGH | Only supported framework for widgets/complications as of watchOS 9 |
| App Intents | HIGH | WWDC25 emphasis, primary integration path going forward |
| Swift 6.2 | HIGH | Current stable release with major concurrency improvements |
| Swift Testing | MEDIUM | Very new (2024), but Apple-endorsed; lacks UI testing support currently |
| MVVM | HIGH | Dominant architecture for SwiftUI apps |
| Deployment targets (iOS 17+) | HIGH | Balances modern features with 85%+ device coverage |

---

## Open Questions / Future Research

1. **watchOS Background Audio Limitations**: watchOS has tighter background execution limits than iOS. Need to verify how long metronome can run in background on watch. May require phase-specific testing.

2. **Apple Watch Ultra Features**: Does Apple Watch Ultra's rugged design enable longer haptic sessions? Could be differentiator but needs hardware testing.

3. **Flashlight API Changes**: iPhone flashlight (AVCaptureDevice.torchMode) - verify no changes in iOS 26. Likely stable but should confirm during implementation phase.

4. **Siri Natural Language**: App Intents + Apple Intelligence might enable "Set metronome to allegro" (tempo name → BPM). Worth exploring in later phases.

---

## Sources

### Primary Sources (HIGH confidence):
- [Xcode 26 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes) - Official Apple documentation
- [Swift Testing - Xcode](https://developer.apple.com/xcode/swift-testing) - Official Apple framework page
- [App Intents Documentation](https://developer.apple.com/documentation/appintents) - Official Apple API reference
- [Creating accessory widgets and watch complications](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications) - Official Apple guide
- [CHHapticEngine Documentation](https://developer.apple.com/documentation/corehaptics/chhapticengine) - Official Apple API reference

### Secondary Sources (MEDIUM confidence - verified community consensus):
- [iOS 26 Explained: Apple's Biggest Update for Developers](https://www.index.dev/blog/ios-26-developer-guide) - Developer analysis
- [The Ultimate Guide to Modern iOS Architecture in 2025](https://medium.com/@csmax/the-ultimate-guide-to-modern-ios-architecture-in-2025-9f0d5fdc892f) - Architecture patterns
- [SwiftUI in 2025: Why It's Powerful](https://medium.com/@k.keawjunchai/swiftui-in-2025-why-its-powerful-but-still-not-for-everyone-3f5a324e577e) - SwiftUI state analysis
- [Swift Package Manager in 2025](https://commitstudiogs.medium.com/whats-new-in-swift-package-manager-spm-for-2025-d7ffff2765a2) - SPM updates

### Technical Implementation Sources:
- [Apple Hello Metronome Sample](https://developer.apple.com/library/archive/samplecode/HelloMetronome/Introduction/Intro.html) - Official sample code
- [Sample-accurate Metronome using AVAudioEngine](https://github.com/Alexander-Nagel/Metronome-using-AVAudioEngine) - Community implementation
- [Making Sense of Time in AVAudioPlayerNode](https://medium.com/@mehsamadi/making-sense-of-time-in-avaudioplayernode-475853f84eb6) - Timing deep-dive

---

**End of Stack Research**
**Next Step:** Use this stack to inform phase structure in roadmap creation.
