import XCTest
@testable import MetronomeCore

@MainActor
final class TapTempoTests: XCTestCase {

    func testNoTapsReturnsNil() {
        let tapTempo = TapTempo()
        let bpm = tapTempo.recordTap()
        XCTAssertNil(bpm, "First tap should return nil (need 4 taps minimum)")
    }

    func testFewTapsReturnsNil() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        // Record 3 taps at 0.5 second intervals
        _ = tapTempo.recordTap()
        currentTime = currentTime.addingTimeInterval(0.5)
        _ = tapTempo.recordTap()
        currentTime = currentTime.addingTimeInterval(0.5)
        let bpm = tapTempo.recordTap()

        XCTAssertNil(bpm, "3 taps should return nil (need 4 taps minimum)")
        XCTAssertEqual(tapTempo.tapCount, 3)
        XCTAssertFalse(tapTempo.isReady)
    }

    func testFourTapsReturnsBPM() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        // Record 4 taps at 0.5 second intervals (120 BPM)
        _ = tapTempo.recordTap()
        currentTime = currentTime.addingTimeInterval(0.5)
        _ = tapTempo.recordTap()
        currentTime = currentTime.addingTimeInterval(0.5)
        _ = tapTempo.recordTap()
        currentTime = currentTime.addingTimeInterval(0.5)
        let bpm = tapTempo.recordTap()

        XCTAssertNotNil(bpm, "4 taps should return a BPM value")
        XCTAssertEqual(bpm?.value, 120, accuracy: 1,
                      "0.5 second intervals should yield ~120 BPM")
        XCTAssertTrue(tapTempo.isReady)
    }

    func testEightTapsUsesSlidingWindow() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        // Record 10 taps at 0.5 second intervals
        for _ in 0..<10 {
            _ = tapTempo.recordTap()
            currentTime = currentTime.addingTimeInterval(0.5)
        }

        XCTAssertEqual(tapTempo.tapCount, 8,
                      "Should keep only last 8 taps in sliding window")
    }

    func testResetClearsState() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        // Record some taps
        for _ in 0..<4 {
            _ = tapTempo.recordTap()
            currentTime = currentTime.addingTimeInterval(0.5)
        }

        XCTAssertEqual(tapTempo.tapCount, 4)

        tapTempo.reset()

        XCTAssertEqual(tapTempo.tapCount, 0, "Reset should clear all taps")
        XCTAssertFalse(tapTempo.isReady)
    }

    func testGapResetsAutomatically() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        // Record 3 taps
        for _ in 0..<3 {
            _ = tapTempo.recordTap()
            currentTime = currentTime.addingTimeInterval(0.5)
        }

        XCTAssertEqual(tapTempo.tapCount, 3)

        // Wait 3 seconds (exceeds 2 second reset interval)
        currentTime = currentTime.addingTimeInterval(3.0)

        // Next tap should reset
        _ = tapTempo.recordTap()

        XCTAssertEqual(tapTempo.tapCount, 1,
                      "Gap > 2 seconds should auto-reset before new tap")
    }

    func testTapCountProperty() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        XCTAssertEqual(tapTempo.tapCount, 0)

        _ = tapTempo.recordTap()
        XCTAssertEqual(tapTempo.tapCount, 1)

        currentTime = currentTime.addingTimeInterval(0.5)
        _ = tapTempo.recordTap()
        XCTAssertEqual(tapTempo.tapCount, 2)
    }

    func testIsReadyProperty() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        XCTAssertFalse(tapTempo.isReady, "Should not be ready initially")

        for _ in 0..<3 {
            _ = tapTempo.recordTap()
            currentTime = currentTime.addingTimeInterval(0.5)
            XCTAssertFalse(tapTempo.isReady, "Should not be ready before 4 taps")
        }

        _ = tapTempo.recordTap()
        XCTAssertTrue(tapTempo.isReady, "Should be ready after 4 taps")
    }

    func testSlowTempo() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        // Record 4 taps at 2 second intervals (30 BPM)
        for _ in 0..<4 {
            _ = tapTempo.recordTap()
            currentTime = currentTime.addingTimeInterval(2.0)
        }

        let bpm = tapTempo.recordTap()
        XCTAssertNotNil(bpm)
        XCTAssertEqual(bpm?.value, 30, accuracy: 1,
                      "2 second intervals should yield ~30 BPM")
    }

    func testFastTempo() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        // Record 4 taps at 0.2 second intervals (300 BPM)
        for _ in 0..<4 {
            _ = tapTempo.recordTap()
            currentTime = currentTime.addingTimeInterval(0.2)
        }

        let bpm = tapTempo.recordTap()
        XCTAssertNotNil(bpm)
        XCTAssertEqual(bpm?.value, 300, accuracy: 1,
                      "0.2 second intervals should yield ~300 BPM")
    }

    func testInvalidTempoReturnsNil() {
        var currentTime = Date()
        let tapTempo = TapTempo(timeProvider: { currentTime })

        // Record 4 taps at 0.1 second intervals (600 BPM - invalid)
        for _ in 0..<4 {
            _ = tapTempo.recordTap()
            currentTime = currentTime.addingTimeInterval(0.1)
        }

        let bpm = tapTempo.recordTap()
        XCTAssertNil(bpm, "BPM above 300 should return nil")
    }
}
