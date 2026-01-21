import Foundation
import AVFoundation
import MetronomeCore

/// Swift wrapper around the Objective-C AudioEngine.
///
/// This class bridges the Objective-C AudioEngine implementation with the Swift
/// AudioScheduler protocol, allowing MetronomeEngine to use it without coupling
/// to the concrete implementation.
@MainActor
public final class AudioEngineBridge: AudioScheduler {
    private let engine: AudioEngine

    public var isPlaying: Bool {
        engine.isPlaying
    }

    public var bpm: Double {
        get { Double(engine.bpm) }
        set { engine.bpm = Int(newValue) }
    }

    public var beatsPerBar: Int {
        get { Int(engine.beatsPerBar) }
        set { engine.beatsPerBar = newValue }
    }

    public var onBeat: ((Int, Bool) -> Void)? {
        didSet {
            if let callback = onBeat {
                engine.setOnBeatCallback { beatNumber, isAccent in
                    callback(Int(beatNumber), isAccent)
                }
            } else {
                engine.setOnBeatCallback(nil)
            }
        }
    }

    public init() {
        self.engine = AudioEngine()
    }

    /// Load click sounds from URLs.
    ///
    /// Must be called before `start()`.
    ///
    /// - Parameters:
    ///   - clickURL: URL to the normal click sound (WAV file)
    ///   - accentURL: URL to the accent sound (WAV file)
    /// - Throws: AudioSchedulerError.failedToLoadSounds if loading fails
    public func loadSounds(clickURL: URL, accentURL: URL) throws {
        var error: NSError?
        let success = engine.loadClickSound(from: clickURL, accentURL: accentURL, error: &error)
        if !success {
            throw error ?? AudioSchedulerError.failedToLoadSounds
        }
    }

    public func start() throws {
        var error: NSError?
        let success = engine.start(&error)
        if !success {
            throw error ?? AudioSchedulerError.failedToStartEngine
        }
    }

    public func stop() {
        engine.stop()
    }
}
