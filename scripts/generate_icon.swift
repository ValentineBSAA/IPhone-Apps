import AppKit
import Foundation

// The original Repo Pulse 0.8.3 Deck icon, reduced to a 128px JPEG source
// to keep the repository's source history lean. Produces a full opaque iOS PNG.
let path = "scripts/repopulse-deck-icon.jpg.b64"
let encoded = try String(contentsOfFile:path, encoding:.utf8)
guard let data = Data(base64Encoded:encoded.trimmingCharacters(in:.whitespacesAndNewlines)),
      let deckIcon = NSImage(data:data) else {
    fatalError("Deck icon JPEG source is missing or corrupt")
}
let canvas = NSImage(size:NSSize(width:1024,height:1024),flipped:false) { rect in
    NSColor.black.setFill()
    rect.fill()
    deckIcon.draw(in:rect,from:.zero,operation:.copy,fraction:1.0)
    return true
}
guard let tiff=canvas.tiffRepresentation,
      let bitmap=NSBitmapImageRep(data:tiff),
      let png=bitmap.representation(using:.png,properties:[:]) else {
    fatalError("Unable to draw Deck icon")
}
let destinations=[
    "RepoPulse/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
    "RepoPulse/Assets.xcassets/DeckCube.imageset/DeckCube.png"
]
for dest in destinations {
    let url=URL(fileURLWithPath:dest)
    try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),
                                            withIntermediateDirectories:true)
    try png.write(to:url)
    print("Wrote \(dest)")
}
