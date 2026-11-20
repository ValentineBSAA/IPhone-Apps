import SwiftUI
import AVFoundation
import CoreMedia
import CoreVideo

/// Experimental contact photoplethysmography (PPG). Not a medical device.
/// Raw frames stay only in memory, and only a user-confirmed estimate can be
/// copied into a new manual entry. No HealthKit capability is required.
final class CameraPulseReader: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var running = false
    @Published private(set) var progress = 0.0
    @Published private(set) var resultBPM: Int?
    @Published private(set) var status = "Ready for a short fingertip check."
    @Published private(set) var errorText: String?

    private struct Sample {
        let time: Double
        let value: Double
    }

    private let cameraQueue = DispatchQueue(label: "posies.camera.ppg", qos: .userInitiated)
    private var session: AVCaptureSession?
    private var device: AVCaptureDevice?
    private var active = false
    private var firstValid: Double?
    private var lastValid: Double?
    private var lastUI: Double = 0
    private var samples: [Sample] = []
    private let captureSeconds = 24.0

    func begin() {
        DispatchQueue.main.async {
            self.progress = 0
            self.resultBPM = nil
            self.errorText = nil
            self.status = "Requesting access to the rear camera…"
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { allowed in
                if allowed {
                    self.startCamera()
                } else {
                    self.presentError("Camera permission was declined. Enable Camera in iPhone Settings to try again.")
                }
            }
        default:
            presentError("Camera access is off. Enable Camera for POTS & Posies in iPhone Settings.")
        }
    }

    private func startCamera() {
        cameraQueue.async {
            guard !self.active else { return }
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  device.hasTorch else {
                self.presentError("This iPhone does not provide the rear camera and torch needed for this experiment.")
                return
            }
            let session = AVCaptureSession()
            do {
                session.beginConfiguration()
                session.sessionPreset = .low
                let input = try AVCaptureDeviceInput(device: device)
                guard session.canAddInput(input) else {
                    session.commitConfiguration()
                    self.presentError("The camera cannot start on this device.")
                    return
                }
                session.addInput(input)
                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                guard session.canAddOutput(output) else {
                    session.commitConfiguration()
                    self.presentError("The camera cannot provide pulse sample frames.")
                    return
                }
                session.addOutput(output)
                output.setSampleBufferDelegate(self, queue: self.cameraQueue)
                session.commitConfiguration()
                self.device = device
                self.session = session
                self.samples.removeAll(keepingCapacity: true)
                self.firstValid = nil
                self.lastValid = nil
                self.lastUI = 0
                self.active = true
                session.startRunning()

                guard device.isTorchAvailable else {
                    self.endCapture(error: "The flashlight is unavailable. Close other camera apps and try again.")
                    return
                }
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                try device.setTorchModeOn(level: 0.3)
                DispatchQueue.main.async {
                    self.running = true
                    self.status = "Rest your fingertip gently over the rear camera and light. Hold still."
                }
            } catch {
                self.endCapture(error: "Camera or flashlight could not start: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        cameraQueue.async {
            self.endCapture(error: nil)
        }
    }

    private func endCapture(error: String?) {
        // Called only from cameraQueue; torch is turned off on every exit path.
        active = false
        if let device = device, device.hasTorch {
            if (try? device.lockForConfiguration()) != nil {
                device.torchMode = .off
                device.unlockForConfiguration()
            }
        }
        session?.stopRunning()
        session = nil
        device = nil
        samples.removeAll()
        firstValid = nil
        lastValid = nil
        DispatchQueue.main.async {
            self.running = false
            if let error {
                self.errorText = error
                self.status = "No reading recorded."
            } else if self.resultBPM == nil {
                self.status = "Stopped. No reading was recorded."
            }
        }
    }

    private func presentError(_ message: String) {
        DispatchQueue.main.async {
            self.errorText = message
            self.running = false
            self.status = "No reading recorded."
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard active, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        guard time.isFinite else { return }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        let w = CVPixelBufferGetWidth(buffer)
        let h = CVPixelBufferGetHeight(buffer)
        let rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        guard let base = CVPixelBufferGetBaseAddress(buffer), w > 48, h > 48 else {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            return
        }
        let bytes = base.assumingMemoryBound(to: UInt8.self)
        // Small central region, sampled rather than retaining camera imagery.
        var red = 0.0, green = 0.0, blue = 0.0, n = 0.0
        for y in stride(from: h * 2 / 5, to: h * 3 / 5, by: 5) {
            for x in stride(from: w * 2 / 5, to: w * 3 / 5, by: 5) {
                let i = y * rowBytes + x * 4
                blue += Double(bytes[i])
                green += Double(bytes[i + 1])
                red += Double(bytes[i + 2])
                n += 1
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        guard n > 0 else { return }
        red /= n; green /= n; blue /= n
        // Filter obvious uncovered/dark frames. Do not produce a synthetic bpm.
        let covered = red > 90 && red > green * 1.13 && red > blue * 1.13
        if !covered {
            if let lastValid, time - lastValid > 1.0 {
                samples.removeAll(keepingCapacity: true)
                firstValid = nil
                self.lastValid = nil
            }
            if time - lastUI > 0.7 {
                lastUI = time
                DispatchQueue.main.async {
                    self.status = "Cover the rear camera and light gently with one fingertip."
                    self.progress = 0
                }
            }
            return
        }
        if firstValid == nil { firstValid = time }
        lastValid = time
        // The green channel frequently carries useful pulse modulation.
        // This value is only held transiently, never saved as a video.
        samples.append(Sample(time: time, value: green > 18 ? green : red))
        guard let began = firstValid else { return }
        let elapsed = max(0, time - began)
        if elapsed >= captureSeconds {
            let estimate = Self.estimate(samples)
            DispatchQueue.main.async {
                self.resultBPM = estimate
                self.progress = 1
                self.status = estimate == nil
                    ? "Signal not reliable enough. No heart rate was estimated. You can retry or use a validated monitor."
                    : "Experimental estimate only. Compare with a reliable monitor before using."
            }
            endCapture(error: nil)
            return
        }
        if time - lastUI >= 0.5 {
            lastUI = time
            DispatchQueue.main.async {
                self.progress = min(1, elapsed / self.captureSeconds)
                self.status = "Reading fingertip color changes. Keep your hand still."
            }
        }
    }

    /// Conservative time-domain autocorrelation estimate on uniformly
    /// resampled data. Rejects low-modulation and inconsistent half-windows.
    private static func estimate(_ samples: [Sample]) -> Int? {
        guard samples.count > 240, let first = samples.first, let last = samples.last,
              last.time - first.time >= 18 else { return nil }
        let hz = 24.0
        let count = Int((last.time - first.time) * hz)
        guard count >= 400 else { return nil }
        var values = [Double]()
        values.reserveCapacity(count)
        var j = 0
        for i in 0..<count {
            let t = first.time + Double(i) / hz
            while j + 1 < samples.count - 1 && samples[j + 1].time < t { j += 1 }
            let a = samples[j], b = samples[j + 1]
            let u = min(1, max(0, (t - a.time) / max(0.001, b.time - a.time)))
            values.append(a.value * (1 - u) + b.value * u)
        }
        guard let all = pulseRate(values),
              let early = pulseRate(Array(values.prefix(values.count / 2))),
              let late = pulseRate(Array(values.suffix(values.count / 2))),
              abs(early - late) <= 12,
              abs(all - early) <= 12,
              abs(all - late) <= 12 else { return nil }
        return Int(all.rounded())
    }

    private static func pulseRate(_ values: [Double]) -> Double? {
        let n = values.count
        guard n >= 190 else { return nil }
        var sums = [Double](repeating: 0, count: n + 1)
        for i in 0..<n { sums[i + 1] = sums[i] + values[i] }
        var wave = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let lo = max(0, i - 19), hi = min(n, i + 20)
            wave[i] = values[i] - (sums[hi] - sums[lo]) / Double(hi - lo)
        }
        let energy = wave.reduce(0.0) { $0 + $1 * $1 } / Double(n)
        guard energy > 0.045, energy < 1200 else { return nil }
        var correlations = [Double]()
        for lag in 8...32 {
            var dot = 0.0, aa = 0.0, bb = 0.0
            for i in lag..<n {
                let a = wave[i], b = wave[i - lag]
                dot += a * b; aa += a * a; bb += b * b
            }
            correlations.append(dot / sqrt(max(1e-9, aa * bb)))
        }
        guard let bestCorrelation = correlations.max(), bestCorrelation >= 0.47 else { return nil }

        // Prefer the earliest strong local maximum to avoid choosing a 2x/3x
        // period harmonic and reporting 50 bpm when the real pulse is 150.
        for index in correlations.indices {
            let score = correlations[index]
            guard score >= max(0.47, bestCorrelation * 0.90) else { continue }
            let leftOK = index == 0 || score >= correlations[index - 1]
            let rightOK = index == correlations.count - 1 || score >= correlations[index + 1]
            guard leftOK && rightOK else { continue }
            let bpm = 60.0 * 24.0 / Double(index + 8)
            return (45...180).contains(bpm) ? bpm : nil
        }
        return nil
    }
}

struct CameraPulseView: View {
    @StateObject private var reader = CameraPulseReader()
    @State private var showEditor = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Experimental Camera Pulse", systemImage: "heart.text.square")
                            .font(.title3.bold())
                            .foregroundStyle(Color.potsTeal)
                        Text("The rear camera reads tiny light changes through a fingertip while the flashlight is on. This may estimate a resting pulse, but accuracy is unverified for POTS, fast changes, or irregular rhythms.")
                            .font(.subheadline)
                        Text("Sit comfortably. Cover the camera and light gently with one finger. Do not press hard. Stop immediately if the flashlight becomes warm or you feel uncomfortable.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("No video, pictures, waveform or estimated value is saved automatically. You choose whether to open a draft.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(reader.status).font(.subheadline)
                        if reader.running {
                            ProgressView(value: reader.progress) {
                                Text("Approximately 24 seconds of stable signal")
                                    .font(.caption)
                            }
                            .tint(.potsTeal)
                            Button(role: .cancel) { reader.stop() } label: {
                                Label("Stop and turn flashlight off", systemImage: "stop.circle.fill")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            if let bpm = reader.resultBPM {
                                Text("\(bpm) bpm")
                                    .font(.largeTitle.bold().monospacedDigit())
                                Text("Unvalidated camera estimate. Do not use for medical decisions; compare it with a trusted monitor.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button {
                                    showEditor = true
                                } label: {
                                    Label("Review in heart-rate entry", systemImage: "square.and.pencil")
                                        .frame(maxWidth: .infinity, minHeight: 52)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            Button {
                                reader.begin()
                            } label: {
                                Label(reader.resultBPM == nil ? "Start camera pulse check" : "Measure again",
                                      systemImage: "camera.metering.center.weighted")
                                    .frame(maxWidth: .infinity, minHeight: 52)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                Text("For symptoms, clinical decisions, or an unexpected reading, use a validated heart-rate monitor and professional guidance. This experiment cannot measure blood pressure or diagnose POTS.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
        }
        .background(Color.potsBackground.ignoresSafeArea())
        .navigationTitle("Camera Pulse · Beta")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { reader.stop() }
        .onChange(of: scenePhase) { phase in
            if phase != .active { reader.stop() }
        }
        .sheet(isPresented: $showEditor) {
            EntryEditor(category: .heartRate, suggestedBPM: reader.resultBPM,
                        suggestedNote: "Experimental camera pulse estimate; not medically validated. Confirm with an independent monitor.")
        }
        .alert("Camera pulse unavailable", isPresented: Binding(
            get: { reader.errorText != nil },
            set: { if !$0 { reader.errorText = nil } }
        )) {
            Button("OK") { reader.errorText = nil }
        } message: {
            Text(reader.errorText ?? "Try again or record a reading manually.")
        }
    }
}
