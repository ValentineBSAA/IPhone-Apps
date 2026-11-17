import AppKit
import Foundation

// Generates a fully original 1024px native App Store icon from vector shapes.
// No external stock artwork, licensed font or external asset dependency.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let folder = root.appendingPathComponent("LastSeenApp/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

let size = 1024
guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                    pixelsWide: size, pixelsHigh: size,
                                    bitsPerSample: 8, samplesPerPixel: 4,
                                    hasAlpha: true, isPlanar: false,
                                    colorSpaceName: .deviceRGB,
                                    bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Cannot initialize icon drawing context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
let all = NSRect(x: 0, y: 0, width: size, height: size)
let backdrop = NSBezierPath(roundedRect: all, xRadius: 185, yRadius: 185)
NSGradient(starting: NSColor(calibratedRed: 0.035, green: 0.045, blue: 0.075, alpha: 1),
           ending: NSColor(calibratedRed: 0.21, green: 0.12, blue: 0.20, alpha: 1))!
    .draw(in: backdrop, angle: 135)

let glow = NSBezierPath(ovalIn: NSRect(x: 165, y: 335, width: 720, height: 720))
NSColor(calibratedRed: 0.60, green: 0.12, blue: 0.19, alpha: 0.20).setFill()
glow.fill()

let phone = NSBezierPath(roundedRect: NSRect(x: 224, y: 86, width: 576, height: 852),
                         xRadius: 87, yRadius: 87)
NSColor(calibratedRed: 0.025, green: 0.035, blue: 0.058, alpha: 1).setFill()
phone.fill()
NSColor(calibratedRed: 0.61, green: 0.33, blue: 0.40, alpha: 0.80).setStroke()
phone.lineWidth = 9
phone.stroke()

let screen = NSBezierPath(roundedRect: NSRect(x: 254, y: 120, width: 516, height: 784),
                          xRadius: 53, yRadius: 53)
NSColor(calibratedRed: 0.080, green: 0.092, blue: 0.13, alpha: 1).setFill()
screen.fill()

let pill = NSBezierPath(roundedRect: NSRect(x: 416, y: 836, width: 192, height: 31),
                        xRadius: 17, yRadius: 17)
NSColor.black.setFill()
pill.fill()

let bubble = NSBezierPath(roundedRect: NSRect(x: 298, y: 563, width: 410, height: 174),
                          xRadius: 49, yRadius: 49)
NSColor(calibratedRed: 0.20, green: 0.25, blue: 0.34, alpha: 1).setFill()
bubble.fill()

for i in 0..<3 {
    let dot = NSBezierPath(ovalIn: NSRect(x: 382 + i * 89, y: 627, width: 49, height: 49))
    NSColor(calibratedRed: 0.72, green: 0.76, blue: 0.84, alpha: i == 1 ? 1 : 0.5).setFill()
    dot.fill()
}

let divider = NSBezierPath(rect: NSRect(x: 336, y: 400, width: 352, height: 2))
NSColor(calibratedRed: 0.40, green: 0.43, blue: 0.51, alpha: 0.38).setFill()
divider.fill()

let shadow = NSShadow()
shadow.shadowBlurRadius = 12
shadow.shadowColor = NSColor.black.withAlphaComponent(0.65)
shadow.shadowOffset = NSSize(width: 0, height: -6)
shadow.set()

let title = NSAttributedString(string: "LAST", attributes: [
    .font: NSFont.systemFont(ofSize: 115, weight: .black),
    .foregroundColor: NSColor.white
])
title.draw(at: NSPoint(x: 324, y: 277))
let second = NSAttributedString(string: "SEEN", attributes: [
    .font: NSFont.systemFont(ofSize: 115, weight: .black),
    .foregroundColor: NSColor(calibratedRed: 0.93, green: 0.37, blue: 0.46, alpha: 1)
])
second.draw(at: NSPoint(x: 323, y: 151))
NSShadow().set()

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Cannot render PNG icon")
}
try png.write(to: folder.appendingPathComponent("AppIcon.png"), options: .atomic)

let contents = """
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
"""
try contents.write(to: folder.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Created original LAST SEEN 1024×1024 app icon")
