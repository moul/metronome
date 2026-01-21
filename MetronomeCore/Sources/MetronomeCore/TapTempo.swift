import Foundation

/// Analyzes tap timing to calculate tempo (BPM).
///
/// Records tap timestamps and calculates BPM from intervals between taps.
/// Requires at least 4 taps before returning a BPM value. Automatically resets
/// if there's a gap of more than 2 seconds between taps.
@MainActor
public class TapTempo {

    // MARK: - Constants

    /// Maximum number of taps to keep in the sliding window
    private let maxTaps = 8

    /// Time interval (seconds) after which taps are automatically reset
    private let resetInterval: TimeInterval = 2.0

    /// Minimum number of taps required before calculating BPM
    private let minTapsForBPM = 4

    // MARK: - Properties

    /// Recorded tap timestamps
    private var taps: [Date] = []

    /// Time provider for testability
    private let timeProvider: () -> Date

    // MARK: - Public Properties

    /// The current number of recorded taps
    public var tapCount: Int {
        taps.count
    }

    /// Whether enough taps have been recorded to calculate BPM
    public var isReady: Bool {
        tapCount >= minTapsForBPM
    }

    // MARK: - Initialization

    /// Creates a new TapTempo analyzer.
    ///
    /// - Parameter timeProvider: Function that returns current time (for testing)
    public init(timeProvider: @escaping () -> Date = { Date() }) {
        self.timeProvider = timeProvider
    }

    // MARK: - Public Methods

    /// Records a tap and returns the calculated BPM if enough taps have been recorded.
    ///
    /// - Returns: A BPM value if at least 4 taps have been recorded and the calculated
    ///            BPM is valid (30-300), otherwise nil
    public func recordTap() -> BPM? {
        let now = timeProvider()

        // Check if we should reset due to gap
        if let lastTap = taps.last {
            let gap = now.timeIntervalSince(lastTap)
            if gap > resetInterval {
                taps.removeAll()
            }
        }

        // Add the new tap
        taps.append(now)

        // Keep only the most recent taps
        if taps.count > maxTaps {
            taps.removeFirst(taps.count - maxTaps)
        }

        // Need at least minTapsForBPM to calculate
        guard taps.count >= minTapsForBPM else {
            return nil
        }

        // Calculate intervals between consecutive taps
        var intervals: [TimeInterval] = []
        for i in 1..<taps.count {
            let interval = taps[i].timeIntervalSince(taps[i-1])
            intervals.append(interval)
        }

        // Calculate average interval
        let averageInterval = intervals.reduce(0.0, +) / Double(intervals.count)

        // Convert to BPM (beats per minute)
        let calculatedBPM = 60.0 / averageInterval

        // Return BPM if it's in valid range
        return BPM(value: calculatedBPM)
    }

    /// Resets all recorded taps.
    public func reset() {
        taps.removeAll()
    }
}
