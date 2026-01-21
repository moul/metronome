import Foundation

/// Protocol for audio scheduling implementations.
/// Allows MetronomeEngine to work with different audio backends
/// and enables testing with mock implementations.
@MainActor
public protocol AudioScheduler: AnyObject {
    /// Whether the scheduler is currently playing
    var isPlaying: Bool { get }

    /// Current BPM (30-300)
    var bpm: Double { get set }

    /// Beats per bar (for accent on beat 1)
    var beatsPerBar: Int { get set }

    /// Start playing the metronome
    func start() throws

    /// Stop playing
    func stop()

    /// Callback fired on each beat (on main thread)
    /// Parameters: beat number (0-based), isAccent
    var onBeat: ((Int, Bool) -> Void)? { get set }
}

/// Errors that can occur during audio scheduling
public enum AudioSchedulerError: Error, Equatable {
    case failedToLoadSounds
    case failedToStartEngine
    case engineNotReady
}
