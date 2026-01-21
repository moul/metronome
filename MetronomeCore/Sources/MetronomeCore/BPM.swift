import Foundation

/// A value type representing Beats Per Minute (BPM) with validation.
///
/// BPM values are constrained to the range 30-300, which covers the practical
/// range for musical tempos from very slow to very fast.
public struct BPM: Equatable, Hashable, Sendable {

    // MARK: - Constants

    /// Minimum valid BPM value
    public static let min = 30

    /// Maximum valid BPM value
    public static let max = 300

    /// Default BPM value (common moderate tempo)
    public static let `default` = 120

    // MARK: - Properties

    /// Internal storage with precise value
    private let rawValue: Double

    /// The BPM value as an integer (rounded from internal precision)
    public var value: Int {
        Int(rawValue.rounded())
    }

    /// The interval between beats in seconds
    public var beatInterval: TimeInterval {
        60.0 / rawValue
    }

    // MARK: - Initialization

    /// Creates a BPM value from an integer.
    ///
    /// - Parameter value: The BPM value (must be between 30 and 300)
    /// - Returns: A BPM instance, or nil if the value is out of range
    public init?(value: Int) {
        guard value >= Self.min && value <= Self.max else {
            return nil
        }
        self.rawValue = Double(value)
    }

    /// Creates a BPM value from a precise double value.
    ///
    /// - Parameter value: The precise BPM value (must be between 30 and 300)
    /// - Returns: A BPM instance, or nil if the value is out of range
    public init?(value: Double) {
        guard value >= Double(Self.min) && value <= Double(Self.max) else {
            return nil
        }
        self.rawValue = value
    }

    // MARK: - Audio Scheduling

    /// Calculate the number of audio samples between beats at a given sample rate.
    ///
    /// - Parameter sampleRate: The audio sample rate (e.g., 44100.0 Hz)
    /// - Returns: The number of samples per beat
    public func beatIntervalSamples(sampleRate: Double) -> Int64 {
        Int64((beatInterval * sampleRate).rounded())
    }
}
