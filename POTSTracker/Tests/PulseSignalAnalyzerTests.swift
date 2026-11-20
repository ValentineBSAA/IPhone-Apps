import XCTest
@testable import POTSTracker

final class PulseSignalAnalyzerTests: XCTestCase {
    private func stablePulse(bpm: Double, duration: Double = 23, amplitude: Double = 8) -> [PulseSample] {
        let hz = 30.0
        return (0..<Int(duration * hz)).map { index in
            let time = Double(index) / hz
            let pulse = amplitude * sin(2 * Double.pi * bpm / 60 * time)
            let slowLight = 0.45 * sin(2 * Double.pi * 0.22 * time)
            return PulseSample(time: time, intensity: 130 + pulse + slowLight)
        }
    }

    func testSyntheticRestingHeartRateDetected() {
        let result = PulseSignalAnalyzer.estimate(stablePulse(bpm: 72))
        XCTAssertNotNil(result)
        if let result { XCTAssertLessThanOrEqual(abs(result - 72), 3) }
    }

    func testSyntheticFasterHeartRateDetected() {
        let result = PulseSignalAnalyzer.estimate(stablePulse(bpm: 116))
        XCTAssertNotNil(result)
        if let result { XCTAssertLessThanOrEqual(abs(result - 116), 4) }
    }

    func testNoReadingForConstantOrVeryShortSignals() {
        let flat = (0..<600).map { PulseSample(time: Double($0) / 30, intensity: 140) }
        XCTAssertNil(PulseSignalAnalyzer.estimate(flat))
        XCTAssertNil(PulseSignalAnalyzer.estimate(Array(stablePulse(bpm: 72).prefix(40))))
    }

    func testSignalNotAcceptedWhenRateChangesAcrossWindows() {
        let data = (0..<690).map { index -> PulseSample in
            let t = Double(index) / 30.0
            let bpm = t < 11.5 ? 64.0 : 140.0
            return PulseSample(time: t, intensity: 120 + 7 * sin(2 * Double.pi * bpm * (t - (t < 11.5 ? 0 : 11.5)) / 60))
        }
        XCTAssertNil(PulseSignalAnalyzer.estimate(data))
    }

    func testConfidenceDistinguishesRhythmicSignalFromFlatLine() {
        let wave = Array(stablePulse(bpm: 80).prefix(290))
        let flat = wave.map { PulseSample(time: $0.time, intensity: 130) }
        XCTAssertGreaterThan(PulseSignalAnalyzer.patternConfidence(wave), 0.35)
        XCTAssertEqual(PulseSignalAnalyzer.patternConfidence(flat), 0)
    }
}
