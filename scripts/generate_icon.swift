// Generates a full-bleed, opaque 1024x1024 AppIcon.png using native macOS AppKit.
// This source is intentionally checked in so the GitHub Actions build can reproduce the icon.
import AppKit
import Foundation

let size: CGFloat = 1024
let canvas = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    let background = NSBezierPath(rect: rect)
    NSGradient(
        starting: NSColor(calibratedRed: 0.055, green: 0.087, blue: 0.15, alpha: 1),
        ending: NSColor(calibratedRed: 0.015, green: 0.035, blue: 0.075, alpha: 1)
    )!.draw(in: background, angle: 135)

    // Inner panel: recognizably Repo Pulse at iPhone home-screen sizes.
    let panel = NSBezierPath(roundedRect: NSRect(x: 183, y: 257, width: 658, height: 510),
                             xRadius: 114, yRadius: 114)
    NSColor(calibratedRed: 0.060, green: 0.15, blue: 0.22, alpha: 0.80).setFill()
    panel.fill()
    panel.lineWidth = 18
    NSColor(calibratedRed: 0.25, green: 0.82, blue: 0.80, alpha: 0.86).setStroke()
    panel.stroke()

    // Subtle top-left rim, screen-like framing, and fluorescent rhythm line.
    let rim = NSBezierPath()
    rim.move(to: NSPoint(x: 245, y: 692))
    rim.line(to: NSPoint(x: 316, y: 692))
    rim.lineWidth = 12
    rim.lineCapStyle = .round
    NSColor(calibratedRed: 0.47, green: 0.97, blue: 0.88, alpha: 0.80).setStroke()
    rim.stroke()

    let wave = NSBezierPath()
    wave.move(to: NSPoint(x: 265, y: 500))
    wave.line(to: NSPoint(x: 372, y: 500))
    wave.line(to: NSPoint(x: 436, y: 600))
    wave.line(to: NSPoint(x: 501, y: 386))
    wave.line(to: NSPoint(x: 576, y: 628))
    wave.line(to: NSPoint(x: 650, y: 500))
    wave.line(to: NSPoint(x: 761, y: 500))
    wave.lineJoinStyle = .round
    wave.lineCapStyle = .round
    for (width, alpha) in [(CGFloat(66), CGFloat(0.09)), (CGFloat(42), CGFloat(0.18)), (CGFloat(21), CGFloat(1.0))] {
        wave.lineWidth = width
        NSColor(calibratedRed: 0.29, green: 0.98, blue: 0.86, alpha: alpha).setStroke()
        wave.stroke()
    }
    return true
}
let destination = "RepoPulse/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let output = URL(fileURLWithPath: destination)
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Failed to create Repo Pulse AppIcon\n", stderr)
    exit(1)
}
try png.write(to: output)
print("Created \(destination) (\(png.count) bytes)")
