import SwiftUI
import AVFoundation
import CoreMedia
import CoreVideo

/// Experimental contact PPG; not a validated medical measurement.
/// No video is recorded. Camera sample statistics live only in memory.
final class CameraPulseReader: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var running = false
    @Published private(set) var progress = 0.0
    @Published private(set) var resultBPM: Int?
    @Published private(set) var status = "Ready when you are."
    @Published private(set) var signalQuality = "Waiting for camera"
    @Published private(set) var waveform: [Double] = []
    @Published var errorText: String?

    private let cameraQueue = DispatchQueue(label: "posies.camera.ppg", qos: .userInitiated)
    private var session: AVCaptureSession?
    private var device: AVCaptureDevice?
    private var desiredID: UUID?
    private var active = false
    private var firstCameraFrame: Double?
    private var firstCovered: Double?
    private var lastCovered: Double?
    private var lastPublished: Double = 0
    private var samples: [PulseSample] = []
    private let recordingSeconds = 22.0
    private let hardTimeoutSeconds = 39.0

    func begin() {
        cameraQueue.async {
            self.stopCapture(message: nil, failure: nil, bpm: nil)
            let request = UUID()
            self.desiredID = request
            self.publish {
                self.running = true
                self.resultBPM = nil
                self.errorText = nil
                self.progress = 0
                self.waveform = []
                self.signalQuality = "Preparing"
                self.status = "Preparing the rear camera…"
            }
            let permission = AVCaptureDevice.authorizationStatus(for: .video)
            if permission == .authorized {
                self.startCamera(request: request)
            } else if permission == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    self.cameraQueue.async {
                        guard self.desiredID == request else { return }
                        if granted {
                            self.startCamera(request: request)
                        } else {
                            self.stopCapture(
                                message: "Camera access was declined. You can still enter a monitor reading manually.",
                                failure: "Camera permission is off. You can enable it in iPhone Settings.",
                                bpm: nil)
                        }
                    }
                }
            } else {
                self.stopCapture(
                    message: "Camera permission is off.",
                    failure: "Enable Camera access for POTS & Posies in iPhone Settings, or use manual entry.",
                    bpm: nil)
            }
        }
    }

    private func startCamera(request: UUID) {
        guard desiredID == request else { return }
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            stopCapture(message: "Rear camera unavailable.", failure: "This device has no usable rear camera.", bpm: nil)
            return
        }
        guard camera.hasTorch else {
            stopCapture(message: "Flashlight unavailable.", failure: "This rear camera does not have a usable flashlight.", bpm: nil)
            return
        }
        let capture = AVCaptureSession()
        do {
            capture.beginConfiguration()
            capture.sessionPreset = .vga640x480
            let input = try AVCaptureDeviceInput(device: camera)
            guard capture.canAddInput(input) else {
                capture.commitConfiguration()
                stopCapture(message: "Couldn't start camera.", failure: "The rear camera is busy. Close other camera apps and retry.", bpm: nil)
                return
            }
            capture.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            guard capture.canAddOutput(output) else {
                capture.commitConfiguration()
                stopCapture(message: "Couldn't read camera.", failure: "This device cannot provide the video frames needed for the experiment.", bpm: nil)
                return
            }
            capture.addOutput(output)
            output.setSampleBufferDelegate(self, queue: cameraQueue)
            capture.commitConfiguration()
            self.session = capture
            self.device = camera
            firstCameraFrame = nil
            firstCovered = nil
            lastCovered = nil
            lastPublished = 0
            samples.removeAll(keepingCapacity: true)
            capture.startRunning()

            guard capture.isRunning, camera.isTorchAvailable else {
                stopCapture(message: "Flashlight unavailable.", failure: "The flashlight may be cooling down or in use by another app. Try again later.", bpm: nil)
                return
            }
            try camera.lockForConfiguration()
            do {
                try camera.setTorchModeOn(level: 0.22)
                camera.unlockForConfiguration()
            } catch {
                camera.unlockForConfiguration()
                throw error
            }

            active = true
            publish {
                self.signalQuality = "Place fingertip"
                self.status = "Cover the rear camera lens and nearby flash gently."
            }
            // Real-time safety cap even if AVFoundation stops delivering frames.
            cameraQueue.asyncAfter(deadline: .now() + hardTimeoutSeconds + 3) { [weak self] in
                guard let self = self, self.desiredID == request, self.active else { return }
                self.stopCapture(
                    message: "No steady signal found.",
                    failure: "We couldn't find a steady optical signal. Rest your hand, cover the camera and flash, and try again.",
                    bpm: nil)
            }
        } catch {
            stopCapture(message: "Camera couldn't start.", failure: "Camera or flashlight couldn't start: \(error.localizedDescription)", bpm: nil)
        }
    }

    func stop() {
        cameraQueue.async {
            self.desiredID = nil
            self.stopCapture(message: "Ready when you are.", failure: nil, bpm: nil)
        }
    }

    /// Only call on cameraQueue. Every stop path switches the flashlight off.
    private func stopCapture(message: String?, failure: String?, bpm: Int?) {
        active = false
        desiredID = nil
        if let camera = device, camera.hasTorch,
           (try? camera.lockForConfiguration()) != nil {
            camera.torchMode = .off
            camera.unlockForConfiguration()
        }
        session?.stopRunning()
        session = nil
        device = nil
        samples.removeAll(keepingCapacity: true)
        firstCameraFrame = nil
        firstCovered = nil
        lastCovered = nil
        publish {
            self.running = false
            if let message { self.status = message }
            if let failure { self.errorText = failure }
            self.resultBPM = bpm
            if bpm != nil { self.progress = 1; self.signalQuality = "Reading ready" }
            if failure != nil { self.progress = 0; self.signalQuality = "Try again" }
        }
    }

    private func publish(_ changes: @escaping () -> Void) {
        DispatchQueue.main.async(execute: changes)
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard active, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        guard time.isFinite else { return }
        if firstCameraFrame == nil { firstCameraFrame = time }
        if let began = firstCameraFrame, time - began > hardTimeoutSeconds {
            stopCapture(
                message: "Couldn't find a steady signal.",
                failure: "The scan timed out safely and the flashlight turned off. Try a different finger position or enter a monitor reading.",
                bpm: nil)
            return
        }

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let strideBytes = CVPixelBufferGetBytesPerRow(buffer)
        guard let base = CVPixelBufferGetBaseAddress(buffer), width > 48, height > 48 else {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            return
        }
        let pointer = base.assumingMemoryBound(to: UInt8.self)
        var r = 0.0, g = 0.0, b = 0.0, n = 0.0
        for y in stride(from: height * 2 / 5, to: height * 3 / 5, by: 5) {
            for x in stride(from: width * 2 / 5, to: width * 3 / 5, by: 5) {
                let i = y * strideBytes + x * 4
                b += Double(pointer[i])
                g += Double(pointer[i + 1])
                r += Double(pointer[i + 2])
                n += 1
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        guard n > 0 else { return }
        r /= n; g /= n; b /= n

        // Looser optical finger coverage gate than v0.2.0; the old
        // red > green * 1.13 threshold rejected many fully-covered frames.
        // Signal periodicity, not just red color, governs whether BPM appears.
        let covered = r > 68 && r > b * 1.06 && r > g * 0.88
        if !covered {
            if let previous = lastCovered, time - previous > 0.75 {
                samples.removeAll(keepingCapacity: true)
                firstCovered = nil
                lastCovered = nil
            }
            if time - lastPublished > 0.45 {
                lastPublished = time
                publish {
                    self.status = "Move your fingertip to cover the lens and flashlight."
                    self.signalQuality = "Adjust finger position"
                    self.progress = 0
                    self.waveform = []
                }
            }
            return
        }
        if firstCovered == nil { firstCovered = time }
        lastCovered = time

        // Prefer the unclipped green channel, then red if green saturates.
        // Do not store image pixels; these are frame-level numerical averages.
        let intensity = g > 12 && g < 247 ? g : r
        samples.append(PulseSample(time: time, intensity: intensity))
        guard let first = firstCovered else { return }
        let elapsed = time - first
        if elapsed >= recordingSeconds {
            let reading = PulseSignalAnalyzer.estimate(samples)
            stopCapture(
                message: reading == nil
                    ? "Not enough reliable pulse information."
                    : "Experimental estimate ready. Please compare with a trusted monitor.",
                failure: reading == nil
                    ? "We couldn't isolate a repeatable pulse. Try a lighter, steady touch and warmer fingers, or enter your monitor result manually."
                    : nil,
                bpm: reading)
            return
        }

        if time - lastPublished > 0.45 {
            lastPublished = time
            let recent = samples.filter { time - $0.time <= 7 }
            let confidence = PulseSignalAnalyzer.patternConfidence(recent)
            let quality = elapsed < 3 ? "Finding signal" :
                (confidence >= 0.52 ? "Good optical pattern" : "Keep finger steady")
            let portion = max(0, min(1, (elapsed - 2) / (recordingSeconds - 2)))
            let values = Array(recent.suffix(95)).map(\.intensity)
            publish {
                self.signalQuality = quality
                self.status = elapsed < 3 ? "Hold still while we find your fingertip signal." :
                    (confidence >= 0.52 ? "Measuring light changes…" :
                        "Reading light changes. Adjust pressure gently if the signal stays weak.")
                self.progress = portion
                self.waveform = values
            }
        }
    }
}

private struct FingerPlacementGuide: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.potsSurfaceMuted)
                    .frame(width: 220, height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(Color.potsTeal.opacity(0.25)))
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 7) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.potsTeal).frame(width: 29, height: 29)
                            Circle().fill(Color.potsTeal.opacity(0.50)).frame(width: 29, height: 29)
                        }
                        Circle().fill(Color.potsTeal.opacity(0.25)).frame(width: 29, height: 29)
                    }
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.94, green: 0.77, blue: 0.68))
                        .frame(width: 48, height: 120)
                        .rotationEffect(.degrees(23))
                        .overlay(
                            Image(systemName: "hand.point.up.fill")
                                .foregroundStyle(Color.potsTeal)
                                .font(.title2)
                        )
                }
            }
            Text("Place one fingertip over the rear lens and its nearby flash")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Diagram is illustrative. Camera layouts vary by iPhone.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct OpticalSignalWave: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard values.count >= 4,
                      let lo = values.min(), let hi = values.max() else {
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                    return
                }
                let span = max(0.2, hi - lo)
                for (i, v) in values.enumerated() {
                    let x = geometry.size.width * CGFloat(i) / CGFloat(max(1, values.count - 1))
                    let y = geometry.size.height * CGFloat(1 - ((v - lo) / span))
                    let pt = CGPoint(x: x, y: y)
                    if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                }
            }
            .stroke(Color.potsTeal, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(height: 58)
        .accessibilityLabel("Live optical color variation, not a medical heart rhythm waveform")
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
                    VStack(alignment: .leading, spacing: 13) {
                        Label("Fingertip guide", systemImage: "hand.point.up.left")
                            .font(.title3.bold())
                            .foregroundStyle(Color.potsTeal)
                        FingerPlacementGuide()
                        HStack(spacing: 9) {
                            Label("Sit comfortably", systemImage: "chair")
                            Label("Hold still", systemImage: "hand.raised")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        Text("Use a light touch and stop if the flashlight feels warm. A steady optical signal may take a few moments.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 13) {
                        HStack {
                            Text("Camera Pulse · Beta")
                                .font(.headline)
                            Spacer()
                            Label(reader.signalQuality, systemImage:
                                    reader.resultBPM == nil ? "waveform.path" : "checkmark.circle.fill")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.potsTeal)
                        }
                        Text(reader.status).font(.subheadline)
                        if reader.running {
                            OpticalSignalWave(values: reader.waveform)
                            Text("Live optical color signal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            ProgressView(value: reader.progress) {
                                Text("Acquiring a steady sample · approximately 20 seconds")
                                    .font(.caption)
                            }
                            .tint(.potsTeal)
                            Button(role: .cancel) { reader.stop() } label: {
                                Label("Stop and turn off flashlight", systemImage: "stop.circle.fill")
                                    .frame(maxWidth: .infinity, minHeight: 52)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            if let bpm = reader.resultBPM {
                                Text("\(bpm) bpm")
                                    .font(.largeTitle.bold().monospacedDigit())
                                    .accessibilityLabel("Experimental estimate: \(bpm) beats per minute")
                                Text("Unverified experimental estimate. Compare with a trusted external monitor before using.")
                                    .font(.caption).foregroundStyle(.secondary)
                                Button { showEditor = true } label: {
                                    Label("Review before saving", systemImage: "square.and.pencil")
                                        .frame(maxWidth: .infinity, minHeight: 52)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            Button { reader.begin() } label: {
                                Label(reader.resultBPM == nil ? "Start camera pulse check" : "Measure again",
                                      systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity, minHeight: 52)
                            }
                            .buttonStyle(.bordered)
                            Button { showEditor = true } label: {
                                Label("Enter monitor reading manually", systemImage: "pencil")
                            }
                            .buttonStyle(.plain)
                            .font(.subheadline)
                        }
                    }
                }

                Text("Camera Pulse is experimental and not validated for POTS diagnosis, rapid changes, irregular rhythms or clinical decisions. No video or images are stored and no number is saved automatically.")
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
            if phase == .background { reader.stop() }
        }
        .sheet(isPresented: $showEditor) {
            EntryEditor(category: .heartRate, suggestedBPM: reader.resultBPM,
                        suggestedNote: reader.resultBPM == nil ? nil :
                            "Experimental camera pulse estimate; not validated. Confirm with a trusted monitor.")
        }
        .alert("Camera pulse needs attention", isPresented: Binding(
            get: { reader.errorText != nil },
            set: { if !$0 { reader.errorText = nil } }
        )) {
            Button("OK") { reader.errorText = nil }
        } message: {
            Text(reader.errorText ?? "Try again or enter a monitor reading manually.")
        }
    }
}
