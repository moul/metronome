import XCTest
@testable import MetronomeCore

final class BPMTests: XCTestCase {

    func testValidBPMCreation() {
        let bpm = BPM(value: 120)
        XCTAssertNotNil(bpm)
        XCTAssertEqual(bpm?.value, 120)
    }

    func testInvalidBPMLow() {
        let bpm = BPM(value: 29)
        XCTAssertNil(bpm, "BPM below minimum (30) should return nil")
    }

    func testInvalidBPMHigh() {
        let bpm = BPM(value: 301)
        XCTAssertNil(bpm, "BPM above maximum (300) should return nil")
    }

    func testBPMBoundaries() {
        let minBPM = BPM(value: 30)
        XCTAssertNotNil(minBPM, "BPM of 30 should be valid")
        XCTAssertEqual(minBPM?.value, 30)

        let maxBPM = BPM(value: 300)
        XCTAssertNotNil(maxBPM, "BPM of 300 should be valid")
        XCTAssertEqual(maxBPM?.value, 300)
    }

    func testBeatInterval() {
        let bpm60 = BPM(value: 60)
        XCTAssertNotNil(bpm60)
        XCTAssertEqual(bpm60!.beatInterval, 1.0, accuracy: 0.001,
                      "BPM 60 should have 1 second beat interval")

        let bpm120 = BPM(value: 120)
        XCTAssertNotNil(bpm120)
        XCTAssertEqual(bpm120!.beatInterval, 0.5, accuracy: 0.001,
                      "BPM 120 should have 0.5 second beat interval")
    }

    func testBeatIntervalSamples() {
        let bpm60 = BPM(value: 60)
        XCTAssertNotNil(bpm60)

        let samples = bpm60!.beatIntervalSamples(sampleRate: 44100.0)
        XCTAssertEqual(samples, 44100,
                      "BPM 60 at 44.1kHz should be 44100 samples per beat")
    }

    func testEquatable() {
        let bpm1 = BPM(value: 120)
        let bpm2 = BPM(value: 120)
        let bpm3 = BPM(value: 130)

        XCTAssertEqual(bpm1, bpm2, "Two BPM instances with same value should be equal")
        XCTAssertNotEqual(bpm1, bpm3, "BPM instances with different values should not be equal")
    }

    func testHashable() {
        let bpm1 = BPM(value: 120)
        let bpm2 = BPM(value: 120)
        let bpm3 = BPM(value: 130)

        var set = Set<BPM>()
        if let bpm1 = bpm1 { set.insert(bpm1) }
        if let bpm2 = bpm2 { set.insert(bpm2) }
        if let bpm3 = bpm3 { set.insert(bpm3) }

        XCTAssertEqual(set.count, 2, "Set should contain 2 unique BPM values")
    }

    func testDoublePrecisionBPM() {
        let preciseBPM = BPM(value: 120.5)
        XCTAssertNotNil(preciseBPM)
        XCTAssertEqual(preciseBPM?.value, 121,
                      "BPM 120.5 should round to 121 when accessed as integer")
    }

    func testConstants() {
        XCTAssertEqual(BPM.min, 30)
        XCTAssertEqual(BPM.max, 300)
        XCTAssertEqual(BPM.default, 120)
    }
}
