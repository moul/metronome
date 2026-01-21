import Foundation
@testable import MetronomeCore

/// Mock implementation of AudioScheduler for testing.
///
/// Tracks method calls and allows simulating beats without real audio.
@MainActor
final class MockAudioScheduler: AudioScheduler {
    var isPlaying: Bool = false
    var bpm: Double = 120
    var beatsPerBar: Int = 4
    var onBeat: ((Int, Bool) -> Void)?

    // Tracking for assertions
    var startCallCount = 0
    var stopCallCount = 0
    var shouldFailOnStart = false

    func start() throws {
        if shouldFailOnStart {
            throw AudioSchedulerError.failedToStartEngine
        }
        startCallCount += 1
        isPlaying = true
    }

    func stop() {
        stopCallCount += 1
        isPlaying = false
    }

    /// Simulate a beat callback for testing.
    ///
    /// - Parameters:
    ///   - beat: The beat number (0-based)
    ///   - isAccent: Whether this is an accent beat
    func simulateBeat(_ beat: Int, isAccent: Bool) {
        onBeat?(beat, isAccent)
    }

    /// Reset all tracking counters.
    func reset() {
        startCallCount = 0
        stopCallCount = 0
        shouldFailOnStart = false
        isPlaying = false
    }
}
