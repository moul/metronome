# Architecture Patterns: Cross-Platform Apple Metronome App

**Domain:** Native iOS/macOS/watchOS metronome with widgets and Shortcuts
**Researched:** 2026-01-21
**Confidence:** HIGH (official Apple docs, proven patterns, verified examples)

## Executive Summary

A cross-platform Apple metronome app requires careful separation of timing-critical audio code from UI/platform code. The recommended architecture uses a **shared Swift Package for core logic** with **platform-specific app targets** for UI. Real-time audio scheduling demands low-level C/Objective-C code in the audio callback path, while Swift handles business logic, state management, and UI.

**Key architectural decisions:**
1. **Single multiplatform target** for app (iOS/macOS/watchOS) with shared SwiftUI views
2. **Separate Swift Package** for core metronome logic (BPM, tap-tempo, timing engine)
3. **Audio engine isolation** - AVAudioEngine with sample-accurate scheduling, audio code NOT in Swift
4. **App Groups** for data sharing between main app, widgets, and Shortcuts
5. **Modern App Intents** framework (no extensions needed) for Shortcuts integration

## Recommended Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Metronome.xcodeproj                      │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         Multiplatform App Target                      │ │
│  │  Destinations: iOS, macOS, watchOS                    │ │
│  │                                                       │ │
│  │  ├── Shared/                                         │ │
│  │  │   ├── Views/ (SwiftUI, platform-adaptive)        │ │
│  │  │   ├── ViewModels/ (@Observable, platform-agnostic)│ │
│  │  │   └── AppIntents/ (Shortcuts support)            │ │
│  │  │                                                   │ │
│  │  ├── iOS/                                            │ │
│  │  │   ├── iOSSpecificViews.swift                     │ │
│  │  │   └── HapticController.swift (Core Haptics)      │ │
│  │  │                                                   │ │
│  │  ├── macOS/                                          │ │
│  │  │   └── macOSMenuBar.swift                         │ │
│  │  │                                                   │ │
│  │  └── watchOS/                                        │ │
│  │      └── watchOSComplicationProvider.swift          │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │         Widget Extension (WidgetKit)                  │ │
│  │  Targets: iOS Widget, macOS Widget, watchOS Widget   │ │
│  │  Data: App Groups shared UserDefaults/FileManager    │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              MetronomeCore (Swift Package)                  │
│                                                             │
│  ├── Sources/MetronomeCore/                                │
│  │   ├── MetronomeEngine.swift (business logic)           │
│  │   ├── BPMCalculator.swift                              │
│  │   ├── TapTempoAnalyzer.swift (statistical analysis)    │
│  │   ├── AudioScheduler.swift (wrapper for audio engine)  │
│  │   └── OutputMode.swift (audio/visual/haptic enums)     │
│  │                                                         │
│  └── Tests/MetronomeCoreTests/                            │
│      └── TapTempoTests.swift                              │
│                                                            │
│  Platform Support: iOS 16+, macOS 13+, watchOS 9+         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         Audio Rendering (Obj-C/C in main app)              │
│                                                             │
│  MetronomeAudioEngine.h/m (Objective-C)                    │
│  - AVAudioEngine setup                                     │
│  - AVAudioPlayerNode scheduling                            │
│  - Sample-accurate buffer scheduling                       │
│  - Audio session configuration (background mode)           │
│                                                            │
└─────────────────────────────────────────────────────────────┘
```

## Component Boundaries

| Component | Responsibility | Communicates With | Language |
|-----------|---------------|-------------------|----------|
| **MetronomeCore Package** | BPM logic, tap-tempo stats, timing calculations | ViewModels (Swift API) | Swift |
| **AudioEngine (Obj-C)** | Real-time audio scheduling, AVAudioEngine, buffer management | MetronomeCore via Swift wrapper | Objective-C |
| **ViewModels** | State management, coordinate outputs (audio/haptic/visual) | Views (via @Observable), MetronomeCore | Swift |
| **Views (SwiftUI)** | UI rendering, platform-adaptive layouts | ViewModels | Swift |
| **HapticController** | Core Haptics timing, sync with audio | ViewModels | Swift |
| **Widget Extension** | Display current BPM, quick actions | App Groups (UserDefaults) | Swift |
| **App Intents** | Shortcuts actions (start/stop, set BPM) | ViewModels directly (no extension needed) | Swift |

## Data Flow Architecture

### 1. Timing & Audio Flow (Critical Path)

```
User Input (BPM change)
    ↓
ViewModel.setBPM()
    ↓
MetronomeEngine.updateTempo()
    ↓
AudioScheduler.scheduleNextBeat() [Swift wrapper]
    ↓
MetronomeAudioEngine [Objective-C]
    ↓
AVAudioPlayerNode.scheduleBuffer(atTime:) [sample-accurate scheduling]
    ↓
Audio Hardware (speaker output)
```

**Critical timing constraint:** Audio scheduling MUST happen ahead of playback time. AVAudioEngine requires buffers to be scheduled before the current buffer finishes playing to avoid gaps.

**Pattern:** Pre-schedule 2-3 beats in advance using completion handlers to trigger next buffer scheduling.

### 2. Multi-Output Synchronization

For synchronized audio + haptic + visual output:

```
MetronomeEngine.beat() event
    ├──> AudioScheduler.scheduleBuffer(atTime: T)
    ├──> HapticController.scheduleHaptic(atTime: T)  [Core Haptics scheduled mode]
    └──> ViewModel.visualBeatIndicator = true        [@Observable triggers view update]
```

**Synchronization strategy:**
- Audio: AVAudioEngine's render time as master clock
- Haptics: Core Haptics scheduled mode with absolute timestamp from audio clock
- Visual: SwiftUI animation triggered immediately (human perception latency < audio latency)

### 3. Widget Data Sharing

```
Main App State Change (BPM updated)
    ↓
ViewModel persists to App Group UserDefaults
    ↓
WidgetCenter.shared.reloadTimelines(ofKind: "MetronomeWidget")
    ↓
Widget reads from App Group UserDefaults
    ↓
Widget displays updated BPM
```

**App Group configuration:**
- Group identifier: `group.io.moul.metronome`
- Shared data: Current BPM, playing state, last tap-tempo result
- Storage: UserDefaults for simple state, FileManager for audio samples (if widgets need them)

### 4. Shortcuts Integration (App Intents)

```
User: "Set metronome to 120 BPM" (Siri/Shortcuts)
    ↓
SetBPMIntent.perform() [App Intents framework, in-process]
    ↓
Directly calls ViewModel.setBPM(120)
    ↓
App updates (no extension process needed)
```

**Modern approach (iOS 16+):** App Intents framework runs in-process, no separate extension needed. Metadata extracted at build time.

## Platform-Specific Code Isolation

### iOS-Specific

**Location:** `Metronome/iOS/`

```swift
// HapticController.swift - iOS only
import CoreHaptics

@available(iOS 13.0, *)
class HapticController {
    private var engine: CHHapticEngine?

    func scheduleHaptic(atTime time: TimeInterval) {
        // Core Haptics scheduling in sync with audio
    }
}

// FlashlightController.swift - iOS only
import AVFoundation

class FlashlightController {
    func flashOnBeat() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        try? device.lockForConfiguration()
        device.torchMode = .on
        // Schedule turn-off after beat duration
    }
}
```

### macOS-Specific

**Location:** `Metronome/macOS/`

```swift
// MenuBarController.swift - macOS only
import AppKit

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?

    func setupMenuBar() {
        // macOS menu bar integration for quick BPM changes
    }
}
```

### watchOS-Specific

**Location:** `Metronome/watchOS/`

```swift
// ComplicationProvider.swift - watchOS only
import WidgetKit

struct MetronomeComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "MetronomeComplication",
            provider: Provider()
        ) { entry in
            // Complication view
        }
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}
```

**Important:** watchOS 26 moved to full arm64 architecture and supports push updates to complications via APNs. Migrate from deprecated ClockKit to modern WidgetKit.

### Shared SwiftUI Views

**Location:** `Metronome/Shared/Views/`

**Pattern:** Use `#if os()` sparingly. Prefer SwiftUI's adaptive layouts and environment values.

```swift
// BPMControlView.swift - Shared across platforms
struct BPMControlView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        #if os(watchOS)
        // Simplified watch interface
        DigitalCrownBPMPicker()
        #else
        if sizeClass == .compact {
            // iPhone portrait
            VerticalBPMSlider()
        } else {
            // iPad, macOS
            HorizontalBPMSlider()
        }
        #endif
    }
}
```

## State Management Pattern

**Recommended:** MVVM with modern `@Observable` macro (iOS 17+, macOS 14+)

```swift
// MetronomeViewModel.swift
import Observation
import MetronomeCore

@Observable
class MetronomeViewModel {
    var currentBPM: Int = 120
    var isPlaying: Bool = false
    var outputModes: Set<OutputMode> = [.audio, .visual]

    private let engine: MetronomeEngine
    private let audioScheduler: AudioScheduler
    private let hapticController: HapticController?

    init() {
        self.engine = MetronomeEngine()
        self.audioScheduler = AudioScheduler()

        #if os(iOS)
        self.hapticController = HapticController()
        #else
        self.hapticController = nil
        #endif
    }

    func start() {
        isPlaying = true
        engine.start(bpm: currentBPM)
        audioScheduler.scheduleNextBeat()
    }

    func recordTap() {
        let calculatedBPM = engine.tapTempo.recordTap()
        if let bpm = calculatedBPM {
            currentBPM = bpm
        }
    }
}
```

**Why `@Observable` over `ObservableObject`:**
- Less boilerplate (no `@Published` needed)
- More granular updates (only changed properties trigger view updates)
- Better performance
- Recommended for all new code as of 2026

**For older OS support:** Fall back to `ObservableObject` with `@Published` properties.

## Audio Engine Architecture (Critical for Metronome)

### Challenge: Sample-Accurate Timing

AVAudioEngine scheduling must happen ahead of playback time. The completion handler for `scheduleBuffer(atTime:completionHandler:)` is **not called early enough** to schedule the next buffer without gaps.

**Solution:** Always keep 2-3 buffers scheduled ahead.

```objc
// MetronomeAudioEngine.m (Objective-C for real-time safety)
@interface MetronomeAudioEngine ()
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioPlayerNode *playerNode;
@property (nonatomic, strong) AVAudioPCMBuffer *clickBuffer;
@property (nonatomic) NSInteger beatInterval; // in samples
@property (nonatomic) NSInteger scheduledBeats;
@end

@implementation MetronomeAudioEngine

- (void)start {
    [self.engine prepare];
    [self.engine startAndReturnError:nil];

    // Schedule first 3 beats
    [self scheduleNextBeat];
    [self scheduleNextBeat];
    [self scheduleNextBeat];
}

- (void)scheduleNextBeat {
    AVAudioFramePosition currentFrame = self.playerNode.lastRenderTime.sampleTime;
    AVAudioFramePosition targetFrame = currentFrame + (self.beatInterval * self.scheduledBeats);

    AVAudioTime *time = [AVAudioTime timeWithSampleTime:targetFrame
                                              atRate:self.engine.manualRenderingFormat.sampleRate];

    __weak typeof(self) weakSelf = self;
    [self.playerNode scheduleBuffer:self.clickBuffer
                             atTime:time
                            options:AVAudioPlayerNodeBufferInterrupts
                  completionHandler:^{
        // Schedule next beat to keep buffer full
        [weakSelf scheduleNextBeat];
        weakSelf.scheduledBeats--;
    }];

    self.scheduledBeats++;
}

@end
```

### Audio Session Configuration (Background Audio)

```swift
// AudioSessionManager.swift
import AVFoundation

class AudioSessionManager {
    static func configureForMetronome() {
        let session = AVAudioSession.sharedInstance()

        do {
            // Category: .playback for background audio
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
```

**Required:** Enable "Audio, AirPlay, and Picture in Picture" background mode in Xcode capabilities.

### Why Objective-C for Audio Code?

Real-time audio threads require "realtime safe" code:
- No memory allocation
- No locks
- No Swift runtime overhead
- Predictable execution time

**Recommendation:** Keep audio rendering in Objective-C, expose Swift-friendly wrapper API.

## Build Order & Phasing

Based on dependency graph, recommended build order:

### Phase 1: Core Logic Package
**Build first, test independently**
- MetronomeCore Swift Package
- BPM calculator
- Tap-tempo statistical analysis
- Unit tests (no UI, no audio)

**Why first:** Platform-independent, highly testable, no external dependencies.

### Phase 2: Audio Engine
**Build second, integrate with Core**
- Objective-C audio engine
- AVAudioEngine setup
- Sample-accurate scheduling
- Audio session configuration
- Swift wrapper API

**Why second:** Depends on Core for BPM calculations, but independent of UI.

### Phase 3: iOS App with Basic UI
**Build third, proves core architecture**
- SwiftUI views
- ViewModel with @Observable
- Audio + Visual output
- Basic tap-tempo UI

**Why third:** Proves the core architecture works end-to-end on one platform.

### Phase 4: Cross-Platform Expansion
**Build fourth, add platforms**
- macOS support (shared views + menu bar)
- watchOS support (simplified UI + Digital Crown)
- Haptic output (iOS only)
- Flashlight output (iOS only)

**Why fourth:** Core architecture proven, now adapt to platform specifics.

### Phase 5: Extensions
**Build fifth, extend beyond app**
- Home Screen widgets (iOS/macOS/watchOS)
- App Intents for Shortcuts
- watchOS complications (WidgetKit-based)

**Why fifth:** Requires app to be functional first, uses App Groups for data sharing.

### Phase 6: Polish & Advanced Features
**Build last, refinement**
- Advanced tap-tempo visualizations
- Custom time signatures
- Accent patterns
- Setlist management

## Pitfalls & Anti-Patterns to Avoid

### 1. Audio Timing Pitfall: Swift in Audio Callback

**Anti-pattern:** Calling Swift code from audio render callback

```swift
// DON'T: Swift closure in audio callback
playerNode.scheduleBuffer(buffer, atTime: time) {
    self.viewModel.incrementBeatCount() // Swift runtime overhead!
}
```

**Pattern:** Use Objective-C for callback, post notification to Swift layer

```objc
// DO: Objective-C callback, async notify Swift
[self.playerNode scheduleBuffer:buffer atTime:time completionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BeatOccurred" object:nil];
    });
}];
```

### 2. Widget Data Sharing Pitfall: Main Bundle Access

**Anti-pattern:** Widget trying to read from main app's bundle

```swift
// DON'T: Widget can't access main app's UserDefaults
let bpm = UserDefaults.standard.integer(forKey: "currentBPM")
```

**Pattern:** Use App Group container

```swift
// DO: Shared App Group container
let shared = UserDefaults(suiteName: "group.io.moul.metronome")
let bpm = shared?.integer(forKey: "currentBPM") ?? 120
```

### 3. Haptic Synchronization Pitfall: Immediate Mode

**Anti-pattern:** Playing haptics immediately on beat event

```swift
// DON'T: Immediate mode causes audio/haptic desync
func onBeat() {
    hapticEngine.playPattern(pattern) // Not synced with audio!
}
```

**Pattern:** Use scheduled mode with audio clock timestamp

```swift
// DO: Schedule haptic at same time as audio
func scheduleBeat(atTime audioTime: AVAudioTime) {
    let hapticTime = CHHapticTimeImmediate + audioTime.timeIntervalSinceNow
    try? hapticEngine.start()
    try? player.start(atTime: hapticTime)
}
```

### 4. Cross-Platform Pitfall: Over-using #if os()

**Anti-pattern:** Every view wrapped in platform checks

```swift
// DON'T: Brittle, hard to maintain
struct MetronomeView: View {
    var body: some View {
        #if os(iOS)
        iOSLayout()
        #elseif os(macOS)
        macOSLayout()
        #elseif os(watchOS)
        watchOSLayout()
        #endif
    }
}
```

**Pattern:** SwiftUI adaptive layouts with environment

```swift
// DO: Single view, adapts naturally
struct MetronomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        AdaptiveStack(sizeClass: sizeClass) {
            BPMControl()
            PlayButton()
            TapTempoButton()
        }
    }
}
```

### 5. Background Audio Pitfall: Not Activating Session

**Anti-pattern:** Setting category but not activating session

```swift
// DON'T: Category set but session not active
try AVAudioSession.sharedInstance().setCategory(.playback)
// App suspended in background!
```

**Pattern:** Activate session before starting playback

```swift
// DO: Activate session
try AVAudioSession.sharedInstance().setCategory(.playback)
try AVAudioSession.sharedInstance().setActive(true)
// Now background audio works
```

## Modern Apple Ecosystem Integration (2026)

### App Intents vs SiriKit Intents

**Use App Intents** (iOS 16+, macOS 13+, watchOS 9+)

```swift
// SetBPMIntent.swift - Modern approach, no extension needed
import AppIntents

struct SetBPMIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Metronome BPM"

    @Parameter(title: "Beats Per Minute")
    var bpm: Int

    func perform() async throws -> some IntentResult {
        // Runs in-process, can directly access app state
        await MainActor.run {
            MetronomeViewModel.shared.setBPM(bpm)
        }
        return .result()
    }
}
```

**Benefits:**
- No separate extension process
- Direct access to app state
- Swift-native API
- Metadata extracted at build time
- Better performance

### Widget Architecture (WidgetKit)

**Modern approach:** Single widget with multiple size families

```swift
// MetronomeWidget.swift
import WidgetKit
import SwiftUI

struct MetronomeWidget: Widget {
    let kind: String = "MetronomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MetronomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Metronome")
        .description("Quick view of current metronome settings")
        .supportedFamilies([
            .systemSmall,        // iOS Home Screen
            .systemMedium,
            .accessoryCircular,  // iOS Lock Screen, watchOS
            .accessoryRectangular // iOS Lock Screen
        ])
    }
}
```

**Data flow:** App Groups + WidgetCenter.shared.reloadTimelines()

**watchOS complications:** Use WidgetKit (not deprecated ClockKit). Supports push updates via APNs in watchOS 26.

### Swift Concurrency Integration

For async operations (file I/O, network), use modern concurrency:

```swift
@Observable
class MetronomeViewModel {
    func loadPresets() async {
        let presets = await PresetLoader.loadFromDisk()
        await MainActor.run {
            self.availablePresets = presets
        }
    }
}
```

**Key patterns:**
- `@MainActor` for UI updates
- `async/await` for async operations
- Avoid actors for audio threads (use Objective-C callbacks)

## Xcode Project Configuration

### Multiplatform Target Setup

**Modern approach (Xcode 14+):** Single target with multiple destinations

```
Targets:
├── Metronome (iOS, macOS, watchOS)
│   ├── Build Phases → Compile Sources
│   │   └── Filter each file by destination
│   └── Supported Destinations: iPhone, iPad, Mac, Apple Watch
│
├── MetronomeWidget (Widget Extension)
│   └── Supported Destinations: iPhone, iPad, Mac, Apple Watch
│
└── MetronomeCore (Swift Package)
    └── Package.swift platform specification
```

**Package.swift for MetronomeCore:**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MetronomeCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "MetronomeCore",
            targets: ["MetronomeCore"]),
    ],
    targets: [
        .target(
            name: "MetronomeCore",
            dependencies: []),
        .testTarget(
            name: "MetrononomeCoreTests",
            dependencies: ["MetronomeCore"]),
    ]
)
```

### App Groups Entitlements

**Required for widgets and complications:**

```xml
<!-- Metronome.entitlements -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.io.moul.metronome</string>
</array>
```

**Must be added to:**
- Main app target
- Widget extension target
- watchOS app target

## Alternative Architectures Considered

### Alternative 1: Separate Targets per Platform

**What:** Individual iOS app, macOS app, watchOS app targets

**Why not:**
- More code duplication
- Harder to maintain shared logic
- Xcode project complexity
- Deployment complexity (3 separate apps vs 1 universal app)

**When to use:** If platforms have radically different features/UX (not the case for metronome)

### Alternative 2: Shared Framework Instead of Package

**What:** Xcode framework target instead of Swift Package

**Why not:**
- Swift Packages are simpler to configure
- Better SPM ecosystem integration
- Cleaner dependency management
- Easier to test independently

**When to use:** If you need Objective-C code in shared layer (though can use Obj-C in main target)

### Alternative 3: React Native / Flutter

**What:** Cross-platform framework for iOS/Android

**Why not:**
- No Android requirement (Apple platforms only)
- Real-time audio difficult in JavaScript/Dart
- Larger binary size
- Less native feel
- Cannot access watchOS, widgets, complications effectively

**When to use:** If targeting Android too, and audio precision not critical

### Alternative 4: Audio Unit Extension

**What:** Implement metronome as Audio Unit (AUv3)

**Why not:**
- Overkill for standalone metronome app
- Requires DAW host app to use
- More complex architecture
- Not needed for this use case

**When to use:** If building metronome to be used inside other music apps (DAWs)

## Summary: Recommended Architecture

**Project structure:**
- Single multiplatform app target (iOS/macOS/watchOS)
- Swift Package for core logic (testable, reusable)
- Objective-C audio engine (real-time safe)
- SwiftUI views (shared with platform-specific overrides)
- Widget extensions (WidgetKit, App Groups)
- App Intents (no extension needed)

**Build order:**
1. Core package (BPM, tap-tempo logic)
2. Audio engine (Objective-C)
3. iOS app (proves architecture)
4. Cross-platform expansion
5. Extensions (widgets, Shortcuts)
6. Polish

**Critical patterns:**
- Objective-C for audio render callbacks (real-time safety)
- @Observable for ViewModels (modern state management)
- Scheduled mode for haptic/audio sync (Core Haptics)
- App Groups for widget/app data sharing
- Pre-schedule audio buffers (avoid timing gaps)

## Sources

**Cross-Platform Architecture:**
- [Setting up a multi-platform SwiftUI project](https://blog.scottlogic.com/2021/03/04/Multiplatform-SwiftUI.html)
- [Improving multiplatform SwiftUI code](https://www.jessesquires.com/blog/2023/03/23/improve-multiplatform-swiftui-code/)
- [Creating a single-target, cross-platform framework](https://shareup.app/blog/creating-a-single-target-cross-platform-framework-for-ios-and-macos/)
- [Configuring a multiplatform app | Apple Developer Documentation](https://developer.apple.com/documentation/xcode/configuring-a-multiplatform-app-target)

**Swift Package Manager:**
- [Modularizing iOS Applications with SwiftUI and SPM](https://nimblehq.co/blog/modern-approach-modularize-ios-swiftui-spm)
- [Modular Project Structure with Swift Package Manager](https://santoshbotre01.medium.com/modular-project-structure-with-swift-package-manager-spm-c81fb62c8619)
- [Package — Swift Package Manager](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html)

**Audio Engine & Timing:**
- [Metronome-using-AVAudioEngine (GitHub)](https://github.com/Alexander-Nagel/Metronome-using-AVAudioEngine)
- [Hello Metronome (Apple Sample Code)](https://developer.apple.com/library/archive/samplecode/HelloMetronome/Introduction/Intro.html)
- [Making Sense of Time in AVAudioPlayerNode](https://medium.com/@mehsamadi/making-sense-of-time-in-avaudioplayernode-475853f84eb6)
- [AVAudioEngine Tutorial for iOS | Kodeco](https://www.kodeco.com/21672160-avaudioengine-tutorial-for-ios-getting-started)

**Widgets & App Groups:**
- [Sharing data with a Widget](https://useyourloaf.com/blog/sharing-data-with-a-widget/)
- [Share files between iOS app, Widget and WatchKit extensions](https://blog.eidinger.info/share-files-between-your-ios-app-widget-and-watchkit-extensions)
- [iOS Share CoreData with Extension and App Groups](https://medium.com/@pietromessineo/ios-share-coredata-with-extension-and-app-groups-69f135628736)

**App Intents & Shortcuts:**
- [App Intents | Apple Developer Documentation](https://developer.apple.com/documentation/appintents)
- [Accelerating app interactions with App Intents](https://developer.apple.com/documentation/AppIntents/AcceleratingAppInteractionsWithAppIntents)
- [Dive into App Intents - WWDC22](https://developer.apple.com/videos/play/wwdc2022/10032/)
- [App Intents Spotlight integration using Shortcuts](https://www.avanderlee.com/swiftui/app-intents-spotlight-integration-using-shortcuts/)

**Core Haptics:**
- [Core Haptics | Apple Developer Documentation](https://developer.apple.com/documentation/corehaptics/)
- [Introducing Core Haptics - WWDC19](https://developer.apple.com/videos/play/wwdc2019/520/)
- [Haptic Feedback in iOS: A Comprehensive Guide](https://medium.com/@mi9nxi/haptic-feedback-in-ios-a-comprehensive-guide-6c491a5f22cb)

**SwiftUI State Management:**
- [MVVM in SwiftUI for a Better Architecture](https://matteomanferdini.com/swiftui-mvvm/)
- [Modern MVVM iOS App Architecture with Combine and SwiftUI](https://www.vadimbulavin.com/modern-mvvm-ios-app-architecture-with-combine-and-swiftui/)
- [State Management in SwiftUI: The Complete Guide](https://dev.to/sebastienlato/state-management-in-swiftui-the-complete-guide-18fj)

**Background Audio:**
- [Configuring an Audio Session (Apple Documentation)](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionBasics/AudioSessionBasics.html)
- [Configuring background execution modes](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes)
- [iOS playing audio in the background](https://www.sagorin.org/ios-playing-audio-in-background-audio/)

**watchOS & Complications:**
- [What's new in watchOS 26 - WWDC25](https://developer.apple.com/videos/play/wwdc2025/334/)
- [watchOS 26 Moves Apple Watch to New Architecture](https://www.macrumors.com/2025/06/16/watchos-26-moves-apple-watch-to-new-architecture/)

**Swift Concurrency:**
- [The Complete Guide to Swift Concurrency: Swift 6](https://medium.com/@thakurneeshu280/the-complete-guide-to-swift-concurrency-from-threading-to-actors-in-swift-6-a9cf006a19ac)
- [Swift actors | Swift by Sundell](https://www.swiftbysundell.com/articles/swift-actors/)
- [Concurrency: Actors and Audio Units - Swift Forums](https://forums.swift.org/t/concurrency-actors-and-audio-units/42664)

**Additional Resources:**
- [Flashlight torch API](https://www.hackingwithswift.com/example-code/media/how-to-turn-on-the-camera-flashlight-to-make-a-torch)
- [Very accurate iOS metronome with Amazing Audio Engine](https://musicalogic.wordpress.com/2016/01/17/a-very-accurate-ios-metronome-based-on-the-amazing-audio-engine-and-pure-data/)
