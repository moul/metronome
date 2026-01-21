import Foundation
import Observation
import MetronomeCore

/// ViewModel providing a single control point for the metronome UI.
///
/// MetronomeViewModel owns and coordinates the MetronomeEngine, AudioEngineBridge,
/// and AudioSessionManager. It ensures proper initialization order (audio session
/// configured before engine starts) and handles audio interruptions.
@MainActor
@Observable
public final class MetronomeViewModel {
    // MARK: - Engine State (Computed Properties)

    /// Current BPM value
    public var bpm: Int {
        engine.currentBPM.value
    }

    /// Whether the metronome is currently playing
    public var isPlaying: Bool {
        engine.isPlaying
    }

    /// Current beat number (0-based)
    public var currentBeat: Int {
        engine.currentBeat
    }

    /// Whether the current beat is an accent (downbeat)
    public var isAccent: Bool {
        engine.isAccent
    }

    /// Beats per bar
    public var beatsPerBar: Int {
        get { engine.beatsPerBar }
        set { engine.beatsPerBar = newValue }
    }

    /// Current tap count for tap tempo
    public var tapCount: Int {
        engine.tapTempo.tapCount
    }

    // MARK: - Private

    private let engine: MetronomeEngine
    private let audioBridge: AudioEngineBridge
    private let sessionManager: AudioSessionManager

    private var soundsLoaded: Bool = false
    private var interruptionObserver: NSObjectProtocol?

    // MARK: - Initialization

    public init() {
        self.engine = MetronomeEngine()
        self.audioBridge = AudioEngineBridge()
        self.sessionManager = AudioSessionManager()

        // Wire up the audio bridge to the engine
        engine.setAudioScheduler(audioBridge)

        setupInterruptionObserver()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Playback Control

    /// Start the metronome.
    ///
    /// Configures audio session and loads sounds before starting.
    ///
    /// - Throws: Errors from audio session configuration or engine start
    public func start() throws {
        // Configure audio session BEFORE starting engine
        try sessionManager.configureForPlayback()

        // Load sounds if not already loaded
        if !soundsLoaded {
            try loadSounds()
        }

        // Start the engine
        try engine.start()
    }

    /// Stop the metronome.
    public func stop() {
        engine.stop()
    }

    /// Toggle play/stop state.
    ///
    /// - Throws: Errors from start() if toggling to play state
    public func toggle() throws {
        if isPlaying {
            stop()
        } else {
            try start()
        }
    }

    // MARK: - BPM Control

    /// Set BPM directly.
    ///
    /// - Parameter bpm: The new BPM value (clamped to valid range)
    public func setBPM(_ bpm: Int) {
        if let validBPM = BPM(value: bpm) {
            engine.setBPM(validBPM)
        }
    }

    /// Increment BPM by amount.
    ///
    /// - Parameter amount: Amount to increment (default 1)
    public func incrementBPM(by amount: Int = 1) {
        engine.incrementBPM(by: amount)
    }

    /// Decrement BPM by amount.
    ///
    /// - Parameter amount: Amount to decrement (default 1)
    public func decrementBPM(by amount: Int = 1) {
        engine.decrementBPM(by: amount)
    }

    // MARK: - Tap Tempo

    /// Record a tap for tap tempo detection.
    ///
    /// - Returns: The calculated BPM if enough taps recorded, nil otherwise
    @discardableResult
    public func recordTap() -> Int? {
        if let bpm = engine.recordTap() {
            return bpm.value
        }
        return nil
    }

    /// Reset tap tempo state.
    public func resetTapTempo() {
        engine.resetTapTempo()
    }

    // MARK: - Private

    private func loadSounds() throws {
        guard let clickURL = Bundle.main.url(forResource: "click", withExtension: "wav"),
              let accentURL = Bundle.main.url(forResource: "accent", withExtension: "wav") else {
            throw AudioSchedulerError.failedToLoadSounds
        }

        try audioBridge.loadSounds(clickURL: clickURL, accentURL: accentURL)
        soundsLoaded = true
    }

    private func setupInterruptionObserver() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: .audioInterruptionEnded,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruptionEnded(notification)
            }
        }
    }

    private func handleInterruptionEnded(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let shouldResume = userInfo["shouldResume"] as? Bool,
              shouldResume else {
            return
        }

        // Attempt to resume playback if we were playing before interruption
        // Note: We don't track wasPlaying here - the system handles pause/resume
        // and we just need to be ready to play again if the user taps play
    }
}
