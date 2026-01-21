import XCTest
@testable import MetronomeCore

@MainActor
final class MetronomeEngineTests: XCTestCase {

    var engine: MetronomeEngine!
    var mockScheduler: MockAudioScheduler!

    override func setUp() async throws {
        engine = MetronomeEngine()
        mockScheduler = MockAudioScheduler()
        engine.setAudioScheduler(mockScheduler)
    }

    override func tearDown() async throws {
        engine = nil
        mockScheduler = nil
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let freshEngine = MetronomeEngine()
        XCTAssertEqual(freshEngine.currentBPM.value, 120)
        XCTAssertEqual(freshEngine.beatsPerBar, 4)
        XCTAssertFalse(freshEngine.isPlaying)
        XCTAssertEqual(freshEngine.currentBeat, 0)
        XCTAssertFalse(freshEngine.isAccent)
    }

    func testCustomInitialization() {
        let customEngine = MetronomeEngine(bpm: BPM(value: 90)!, beatsPerBar: 3)
        XCTAssertEqual(customEngine.currentBPM.value, 90)
        XCTAssertEqual(customEngine.beatsPerBar, 3)
    }

    func testSchedulerConfiguredOnSet() {
        let scheduler = MockAudioScheduler()
        let freshEngine = MetronomeEngine(bpm: BPM(value: 90)!, beatsPerBar: 3)
        freshEngine.setAudioScheduler(scheduler)

        XCTAssertEqual(scheduler.bpm, 90)
        XCTAssertEqual(scheduler.beatsPerBar, 3)
        XCTAssertNotNil(scheduler.onBeat)
    }

    // MARK: - Playback Tests

    func testStart() throws {
        try engine.start()
        XCTAssertTrue(engine.isPlaying)
        XCTAssertEqual(mockScheduler.startCallCount, 1)
        XCTAssertTrue(mockScheduler.isPlaying)
    }

    func testStop() throws {
        try engine.start()
        engine.stop()
        XCTAssertFalse(engine.isPlaying)
        XCTAssertEqual(mockScheduler.stopCallCount, 1)
        XCTAssertFalse(mockScheduler.isPlaying)
    }

    func testToggleToPlay() throws {
        XCTAssertFalse(engine.isPlaying)
        try engine.toggle()
        XCTAssertTrue(engine.isPlaying)
    }

    func testToggleToStop() throws {
        try engine.start()
        XCTAssertTrue(engine.isPlaying)
        try engine.toggle()
        XCTAssertFalse(engine.isPlaying)
    }

    func testToggleRoundTrip() throws {
        try engine.toggle()
        XCTAssertTrue(engine.isPlaying)

        try engine.toggle()
        XCTAssertFalse(engine.isPlaying)

        try engine.toggle()
        XCTAssertTrue(engine.isPlaying)
    }

    func testStartWithoutSchedulerThrows() {
        let noSchedulerEngine = MetronomeEngine()
        XCTAssertThrowsError(try noSchedulerEngine.start()) { error in
            XCTAssertEqual(error as? MetronomeEngineError, .noAudioScheduler)
        }
    }

    func testStartFailurePropagates() {
        mockScheduler.shouldFailOnStart = true
        XCTAssertThrowsError(try engine.start()) { error in
            XCTAssertEqual(error as? AudioSchedulerError, .failedToStartEngine)
        }
        XCTAssertFalse(engine.isPlaying)
    }

    func testStartResetsCurrentBeat() throws {
        // Simulate some beats
        mockScheduler.simulateBeat(3, isAccent: false)
        XCTAssertEqual(engine.currentBeat, 3)

        // Start should reset
        try engine.start()
        XCTAssertEqual(engine.currentBeat, 0)
        XCTAssertTrue(engine.isAccent)
    }

    func testStopResetsCurrentBeat() throws {
        try engine.start()
        mockScheduler.simulateBeat(3, isAccent: false)
        XCTAssertEqual(engine.currentBeat, 3)

        engine.stop()
        XCTAssertEqual(engine.currentBeat, 0)
        XCTAssertFalse(engine.isAccent)
    }

    // MARK: - BPM Tests

    func testSetBPM() {
        let newBPM = BPM(value: 150)!
        engine.setBPM(newBPM)

        XCTAssertEqual(engine.currentBPM.value, 150)
        XCTAssertEqual(mockScheduler.bpm, 150)
    }

    func testIncrementBPM() {
        engine.incrementBPM(by: 10)
        XCTAssertEqual(engine.currentBPM.value, 130)
        XCTAssertEqual(mockScheduler.bpm, 130)
    }

    func testDecrementBPM() {
        engine.decrementBPM(by: 10)
        XCTAssertEqual(engine.currentBPM.value, 110)
        XCTAssertEqual(mockScheduler.bpm, 110)
    }

    func testIncrementBPMDefaultAmount() {
        engine.incrementBPM()
        XCTAssertEqual(engine.currentBPM.value, 121)
    }

    func testDecrementBPMDefaultAmount() {
        engine.decrementBPM()
        XCTAssertEqual(engine.currentBPM.value, 119)
    }

    func testIncrementBPMAtMaxDoesNothing() {
        engine.setBPM(BPM(value: 300)!)
        engine.incrementBPM(by: 1)
        XCTAssertEqual(engine.currentBPM.value, 300)
    }

    func testDecrementBPMAtMinDoesNothing() {
        engine.setBPM(BPM(value: 30)!)
        engine.decrementBPM(by: 1)
        XCTAssertEqual(engine.currentBPM.value, 30)
    }

    func testBPMChangePropagatesWhilePlaying() throws {
        try engine.start()
        engine.setBPM(BPM(value: 180)!)
        XCTAssertEqual(mockScheduler.bpm, 180)
    }

    // MARK: - Beat Callback Tests

    func testBeatCallbackUpdatesState() throws {
        try engine.start()

        mockScheduler.simulateBeat(0, isAccent: true)
        XCTAssertEqual(engine.currentBeat, 0)
        XCTAssertTrue(engine.isAccent)

        mockScheduler.simulateBeat(1, isAccent: false)
        XCTAssertEqual(engine.currentBeat, 1)
        XCTAssertFalse(engine.isAccent)

        mockScheduler.simulateBeat(2, isAccent: false)
        XCTAssertEqual(engine.currentBeat, 2)
        XCTAssertFalse(engine.isAccent)

        mockScheduler.simulateBeat(3, isAccent: false)
        XCTAssertEqual(engine.currentBeat, 3)
        XCTAssertFalse(engine.isAccent)
    }

    func testBeatCallbackBarAccent() throws {
        try engine.start()

        // Beat 4 starts new bar (0-indexed, so beat 4 is position 0 of next bar)
        mockScheduler.simulateBeat(4, isAccent: true)
        XCTAssertEqual(engine.currentBeat, 4)
        XCTAssertTrue(engine.isAccent)
    }

    // MARK: - Tap Tempo Integration Tests

    func testTapTempoAvailable() {
        XCTAssertNotNil(engine.tapTempo)
        XCTAssertEqual(engine.tapTempo.tapCount, 0)
    }

    func testRecordTapInsufficientTaps() {
        // Less than 4 taps returns nil
        XCTAssertNil(engine.recordTap())
        XCTAssertNil(engine.recordTap())
        XCTAssertNil(engine.recordTap())
        XCTAssertEqual(engine.tapTempo.tapCount, 3)
    }

    func testResetTapTempo() {
        _ = engine.recordTap()
        _ = engine.recordTap()
        XCTAssertEqual(engine.tapTempo.tapCount, 2)

        engine.resetTapTempo()
        XCTAssertEqual(engine.tapTempo.tapCount, 0)
    }

    // MARK: - BeatsPerBar Tests

    func testBeatsPerBarPropagates() {
        engine.beatsPerBar = 3
        XCTAssertEqual(mockScheduler.beatsPerBar, 3)
    }

    func testBeatsPerBarOnInit() {
        let engine6 = MetronomeEngine(beatsPerBar: 6)
        XCTAssertEqual(engine6.beatsPerBar, 6)
    }

    func testBeatsPerBarPropagatesOnSchedulerSet() {
        let freshEngine = MetronomeEngine(beatsPerBar: 5)
        let freshScheduler = MockAudioScheduler()
        freshEngine.setAudioScheduler(freshScheduler)
        XCTAssertEqual(freshScheduler.beatsPerBar, 5)
    }
}
