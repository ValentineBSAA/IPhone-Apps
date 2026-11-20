import Foundation

/// Offline, in-memory experimental optical-pulse processing.
/// Designed for unit testing with synthetic samples; not clinically validated.
struct PulseSample {
    let time: Double
    let intensity: Double
}

enum PulseSignalAnalyzer {
    static let minimumSeconds = 15.0
    private static let hz = 24.0

    /// Returns nil if the optical data doesn't show a repeatable, consistent pulse.
    static func estimate(_ source: [PulseSample]) -> Int? {
        guard let data = evenlySpaced(source), data.count >= Int(minimumSeconds * hz) else { return nil }
        guard let whole = rate(data),
              let early = rate(Array(data.prefix(data.count / 2))),
              let late = rate(Array(data.suffix(data.count / 2))),
              abs(early.bpm - late.bpm) <= 13,
              abs(whole.bpm - early.bpm) <= 13,
              abs(whole.bpm - late.bpm) <= 13,
              whole.confidence >= 0.13 else { return nil }
        return Int(whole.bpm.rounded())
    }

    /// Approximate pattern confidence for guidance only, never a medical score.
    static func patternConfidence(_ source: [PulseSample]) -> Double {
        guard let data = evenlySpaced(source), data.count >= Int(5 * hz),
              let result = rate(data) else { return 0 }
        return min(1, result.confidence / 0.36)
    }

    private static func evenlySpaced(_ source: [PulseSample]) -> [Double]? {
        let clean = source.filter { $0.time.isFinite && $0.intensity.isFinite }
            .sorted { $0.time < $1.time }
        guard clean.count >= 90, let first = clean.first, let last = clean.last,
              last.time - first.time >= 5 else { return nil }
        let length = Int((last.time - first.time) * hz)
        guard length >= 110, length <= 60 * 30 else { return nil }
        var cursor = 0
        var result = [Double]()
        result.reserveCapacity(length)
        for i in 0..<length {
            let t = first.time + Double(i) / hz
            while cursor + 2 < clean.count && clean[cursor + 1].time < t { cursor += 1 }
            let a = clean[cursor], b = clean[cursor + 1]
            let factor = max(0, min(1, (t - a.time) / max(0.00001, b.time - a.time)))
            result.append(a.intensity + factor * (b.intensity - a.intensity))
        }
        return result
    }

    private static func rate(_ data: [Double]) -> (bpm: Double, confidence: Double)? {
        let n = data.count
        guard n >= 115 else { return nil }
        var sums = [Double](repeating: 0, count: n + 1)
        for i in 0..<n { sums[i + 1] = sums[i] + data[i] }
        // Remove lighting drift while preserving 45-180 BPM oscillations.
        let radius = 20
        var wave = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let start = max(0, i - radius), end = min(n, i + radius + 1)
            wave[i] = data[i] - (sums[end] - sums[start]) / Double(end - start)
        }
        let energy = wave.reduce(0.0) { $0 + $1 * $1 }
        guard energy / Double(n) >= 0.025 else { return nil }

        var bestFrequency = 0.0, bestPower = 0.0
        // Search plausible resting pulse rates. A measured result outside this
        // exploratory band fails rather than being forced into the display.
        for bpm in stride(from: 45.0, through: 180.0, by: 1.0) {
            let frequency = bpm / 60.0
            let step = 2 * Double.pi * frequency / hz
            var real = 0.0, imaginary = 0.0
            for i in 0..<n {
                let window = 0.5 - 0.5 * cos(2 * Double.pi * Double(i) / Double(max(1, n - 1)))
                let phase = Double(i) * step
                let value = wave[i] * window
                real += value * cos(phase)
                imaginary += value * sin(phase)
            }
            let power = real * real + imaginary * imaginary
            if power > bestPower {
                bestPower = power
                bestFrequency = bpm
            }
        }
        // Hann window reduces effective signal energy; calibrated conservatively
        // for real optical signals. Reject near-flat, noisy input.
        let confidence = bestPower / max(1e-9, Double(n) * energy)
        guard confidence >= 0.09, bestFrequency > 0 else { return nil }
        return (bestFrequency, confidence)
    }
}
