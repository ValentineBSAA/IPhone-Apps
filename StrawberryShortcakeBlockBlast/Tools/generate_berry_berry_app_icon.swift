import AppKit
import Foundation

// Offline Codemagic artwork assembly. Original, transparent Berry Berry Blast
// mascot is composited onto an opaque strawberry-pink App Store icon.
let assets = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("BerryBlockBlast/Assets.xcassets")
let portraitURL = assets.appendingPathComponent(
    "BerryCharacterPortrait.imageset/BerryCharacterPortrait.png")
let outputURL = assets.appendingPathComponent("AppIcon.appiconset/AppIcon.png")
guard let portrait = NSImage(contentsOf: portraitURL) else {
    fatalError("Missing approved transparent Berry Berry Blast portrait")
}

let size = NSSize(width: 1024, height: 1024)
let icon = NSImage(size: size)
icon.lockFocus()
NSColor(calibratedRed: 1.0, green: 0.91, blue: 0.92, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()

let frame = NSBezierPath(ovalIn: NSRect(x: 65, y: 65, width: 894, height: 894))
NSColor(calibratedRed: 0.94, green: 0.36, blue: 0.49, alpha: 1).setStroke()
frame.lineWidth = 19
frame.stroke()

let inside = NSBezierPath(ovalIn: NSRect(x: 95, y: 95, width: 834, height: 834))
NSColor(calibratedRed: 1, green: 0.97, blue: 0.93, alpha: 1).setFill()
inside.fill()

portrait.draw(in: NSRect(x: 105, y: 123, width: 810, height: 810),
              from: .zero, operation: .sourceOver, fraction: 1)
icon.unlockFocus()

guard let tiff = icon.tiffRepresentation,
      let representation = NSBitmapImageRep(data: tiff),
      let png = representation.representation(using: .png, properties: [:]) else {
    fatalError("Could not create opaque Berry Berry Blast app icon PNG")
}
try png.write(to: outputURL, options: .atomic)
print("PASS: Berry Berry Blast native app icon generated from new mascot")
