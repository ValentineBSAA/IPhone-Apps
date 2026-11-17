import SwiftUI
import UIKit

// Capture the complete lifetime of a touch, even after leaving the tray.
enum BerryTouchPhase { case began, moved, ended, cancelled }

struct BerryTouchEvent {
    let phase: BerryTouchPhase
    let location: CGPoint
    let start: CGPoint

    var distanceSquared: CGFloat {
        let dx = location.x - start.x
        let dy = location.y - start.y
        return dx * dx + dy * dy
    }
}

struct BerryTrayTouchCapture: UIViewRepresentable {
    let slot: Int
    let onTouch: (Int, BerryTouchEvent) -> Void

    func makeUIView(context: Context) -> BerryTouchTrackingView {
        BerryTouchTrackingView()
    }

    func updateUIView(_ view: BerryTouchTrackingView, context: Context) {
        view.onTouch = { [slot, onTouch] event in onTouch(slot, event) }
    }
}

final class BerryTouchTrackingView: UIView {
    var onTouch: ((BerryTouchEvent) -> Void)?
    private var start: CGPoint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isMultipleTouchEnabled = false
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
        isMultipleTouchEnabled = false
        isAccessibilityElement = false
    }

    private func send(_ phase: BerryTouchPhase, touch: UITouch) {
        guard let window else { return }
        let point = touch.location(in: window)
        onTouch?(BerryTouchEvent(phase: phase, location: point, start: start ?? point))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let window else { return }
        start = touch.location(in: window)
        send(.began, touch: touch)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        send(.moved, touch: touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first { send(.ended, touch: touch) }
        start = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first { send(.cancelled, touch: touch) }
        start = nil
    }
}

struct BerryBoardWindowAnchor: UIViewRepresentable {
    let onRect: (CGRect) -> Void

    func makeUIView(context: Context) -> BerryBoardWindowTrackingView {
        BerryBoardWindowTrackingView()
    }

    func updateUIView(_ view: BerryBoardWindowTrackingView, context: Context) {
        view.onRect = onRect
        view.publishIfNeeded()
    }
}

final class BerryBoardWindowTrackingView: UIView {
    var onRect: ((CGRect) -> Void)?
    private var lastRect: CGRect = .null

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        publishIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        publishIfNeeded()
    }

    func publishIfNeeded() {
        guard let window, bounds.width > 0, bounds.height > 0 else { return }
        let rect = convert(bounds, to: window)
        guard rect != lastRect else { return }
        lastRect = rect
        DispatchQueue.main.async { [weak self] in self?.onRect?(rect) }
    }
}
