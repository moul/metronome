import Foundation
import Observation

/// Main coordinator for the metronome.
///
/// MetronomeEngine manages BPM, tap tempo, and audio playback. It serves as the
/// single point of control for all metronome functionality and provides
/// @Observable properties for SwiftUI integration.
@MainActor
@Observable
public final class MetronomeEngine {
    // MARK: - Public State

    /// Current BPM
    public private(set) var currentBPM: BPM

    /// Whether the metronome is playing
    public private(set) var isPlaying: Bool = false

    /// Current beat number (0-based, resets each bar)
    public private(set) var currentBeat: Int = 0

    /// Whether current beat is an accent (downbeat)
    public private(set) var isAccent: Bool = false

    /// Beats per bar (time signature numerator)
    public var beatsPerBar: Int {
        didSet {
            audioScheduler?.beatsPerBar = beatsPerBar
        }
    }

    /// Tap tempo analyzer
    public let tapTempo: TapTempo

    // MARK: - Private

    private var audioScheduler: AudioScheduler?

    // MARK: - Initialization

    /// Create engine with default settings.
    ///
    /// - Parameters:
    ///   - bpm: Initial BPM (default 120)
    ///   - beatsPerBar: Beats per bar for accent pattern (default 4)
    public init(bpm: BPM = BPM(value: 120)!, beatsPerBar: Int = 4) {
        self.currentBPM = bpm
        self.beatsPerBar = beatsPerBar
        self.tapTempo = TapTempo()
    }

    // MARK: - Configuration

    /// Set the audio scheduler implementation.
    ///
    /// Must be called before starting playback. The scheduler is configured
    /// with the current BPM, beatsPerBar, and beat callback.
    ///
    /// - Parameter scheduler: The audio scheduler to use
    public func setAudioScheduler(_ scheduler: AudioScheduler) {
        self.audioScheduler = scheduler
        scheduler.bpm = Double(currentBPM.value)
        scheduler.beatsPerBar = beatsPerBar
        scheduler.onBeat = { [weak self] beat, isAccent in
            self?.handleBeat(beat, isAccent: isAccent)
        }
    }

    // MARK: - Playback Control

    /// Start the metronome.
    ///
    /// - Throws: MetronomeEngineError.noAudioScheduler if no scheduler is set,
    ///           or passes through errors from the audio scheduler
    public func start() throws {
        guard let scheduler = audioScheduler else {
            throw MetronomeEngineError.noAudioScheduler
        }
        try scheduler.start()
        isPlaying = true
        currentBeat = 0
        isAccent = true
    }

    /// Stop the metronome.
    public func stop() {
        audioScheduler?.stop()
        isPlaying = false
        currentBeat = 0
        isAccent = false
    }

    /// Toggle play/stop.
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
    /// Updates both the engine state and the audio scheduler immediately.
    ///
    /// - Parameter bpm: The new BPM value
    public func setBPM(_ bpm: BPM) {
        currentBPM = bpm
        audioScheduler?.bpm = Double(bpm.value)
    }

    /// Increment BPM by amount.
    ///
    /// If the result would exceed BPM.max (300), the BPM is not changed.
    ///
    /// - Parameter amount: Amount to increment (default 1)
    public func incrementBPM(by amount: Int = 1) {
        if let newBPM = BPM(value: currentBPM.value + amount) {
            setBPM(newBPM)
        }
    }

    /// Decrement BPM by amount.
    ///
    /// If the result would go below BPM.min (30), the BPM is not changed.
    ///
    /// - Parameter amount: Amount to decrement (default 1)
    public func decrementBPM(by amount: Int = 1) {
        if let newBPM = BPM(value: currentBPM.value - amount) {
            setBPM(newBPM)
        }
    }

    // MARK: - Tap Tempo

    /// Record a tap and update BPM if enough taps.
    ///
    /// Delegates to the TapTempo analyzer. If enough taps have been recorded
    /// (minimum 4), the calculated BPM is applied to the engine.
    ///
    /// - Returns: The calculated BPM if available, nil otherwise
    @discardableResult
    public func recordTap() -> BPM? {
        if let bpm = tapTempo.recordTap() {
            setBPM(bpm)
            return bpm
        }
        return nil
    }

    /// Reset tap tempo state.
    ///
    /// Clears all recorded taps, allowing a fresh tempo detection sequence.
    public func resetTapTempo() {
        tapTempo.reset()
    }

    // MARK: - Private

    private func handleBeat(_ beat: Int, isAccent: Bool) {
        self.currentBeat = beat
        self.isAccent = isAccent
    }
}

/// Errors from MetronomeEngine
public enum MetronomeEngineError: Error, Equatable {
    /// No audio scheduler has been set via setAudioScheduler()
    case noAudioScheduler
}
