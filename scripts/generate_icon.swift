import AppKit
import Foundation

// No JPEG, Base64, or external image dependencies. The original Repo Pulse
// blue-violet cube and heartbeat are reproduced using native vector geometry.
func rgb(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ alpha:CGFloat=1)->NSColor {
    NSColor(calibratedRed:r,green:g,blue:b,alpha:alpha)
}
func path(_ points:[(CGFloat,CGFloat)])->NSBezierPath {
    let p=NSBezierPath()
    for (index,q) in points.enumerated() {
        if index==0 { p.move(to:NSPoint(x:q.0,y:q.1)) }
        else { p.line(to:NSPoint(x:q.0,y:q.1)) }
    }
    p.close()
    return p
}
func gradient(_ p:NSBezierPath,_ a:NSColor,_ b:NSColor,_ angle:CGFloat=100) {
    NSGradient(starting:a,ending:b)!.draw(in:p,angle:angle)
}
func outline(_ p:NSBezierPath,_ c:NSColor,_ size:CGFloat) {
    p.lineWidth=size
    p.lineJoinStyle = .round
    p.lineCapStyle = .round
    c.setStroke()
    p.stroke()
}

let image=NSImage(size:NSSize(width:1024,height:1024),flipped:false) { rect in
    gradient(NSBezierPath(rect:rect),rgb(0.012,0.047,0.11),rgb(0.038,0.015,0.12),140)
    // Soft backlighting.
    for n in (0..<18).reversed() {
        let radius=CGFloat(200+n*15)
        let glow=NSBezierPath(ovalIn:NSRect(x:512-radius,y:502-radius,
                                           width:radius*2,height:radius*2))
        rgb(0.10,0.31,0.98,CGFloat(18-n)/1450).setFill()
        glow.fill()
    }
    let top=path([(254,640),(506,779),(770,634),(513,488)])
    let left=path([(254,640),(513,488),(513,265),(254,404)])
    let right=path([(513,488),(770,634),(770,400),(513,265)])
    gradient(left,rgb(0.025,0.49,0.98),rgb(0.018,0.08,0.24),45)
    gradient(right,rgb(0.24,0.13,0.63),rgb(0.025,0.043,0.17),45)
    gradient(top,rgb(0.01,0.70,1),rgb(0.33,0.23,0.75),115)
    let roof=path([(280,644),(502,761),(736,638),(514,511)])
    gradient(roof,rgb(0.075,0.27,0.62),rgb(0.036,0.07,0.23),120)
    let blueBand=path([(433,722),(507,763),(768,635),(694,592)])
    gradient(blueBand,rgb(0.016,0.85,1),rgb(0.42,0.45,1),125)
    let bandEdge=path([(694,592),(768,635),(768,562),(694,521)])
    gradient(bandEdge,rgb(0.38,0.42,0.99),rgb(0.20,0.11,0.48),90)
    outline(top,rgb(0.40,0.78,1,0.58),9)
    outline(left,rgb(0.10,0.51,1,0.67),9)
    outline(right,rgb(0.56,0.39,1,0.77),9)
    let line=NSBezierPath()
    line.move(to:NSPoint(x:283,y:446))
    line.line(to:NSPoint(x:394,y:420))
    line.line(to:NSPoint(x:438,y:470))
    line.line(to:NSPoint(x:496,y:586))
    line.line(to:NSPoint(x:559,y:342))
    line.line(to:NSPoint(x:615,y:474))
    line.line(to:NSPoint(x:661,y:433))
    line.line(to:NSPoint(x:742,y:449))
    outline(line,rgb(0.04,0.65,1,0.10),64)
    outline(line,rgb(0.09,0.82,1,0.27),39)
    outline(line,rgb(0.18,0.94,1,0.93),17)
    outline(line,rgb(0.76,1,1,0.92),7)
    return true
}
func export(_ picture:NSImage,_ size:Int,_ destination:String) throws {
    let rendered=NSImage(size:NSSize(width:size,height:size),flipped:false) { bounds in
        picture.draw(in:bounds,from:NSRect(x:0,y:0,width:1024,height:1024),
                     operation:.copy,fraction:1)
        return true
    }
    guard let tiff=rendered.tiffRepresentation,
          let bitmap=NSBitmapImageRep(data:tiff),
          let png=bitmap.representation(using:.png,properties:[:]),
          png.count>12000,
          let verify=NSBitmapImageRep(data:png),
          verify.pixelsWide==size,verify.pixelsHigh==size else {
        fatalError("Icon failed content/dimension verification")
    }
    let a=verify.colorAt(x:size/2,y:size/2)
    let b=verify.colorAt(x:size/3,y:size/3)
    guard a != nil,b != nil,
          abs(a!.redComponent-b!.redComponent)>0.03 ||
          abs(a!.blueComponent-b!.blueComponent)>0.03 else {
        fatalError("Icon has unexpectedly flat or corrupt pixels")
    }
    let url=URL(fileURLWithPath:destination)
    try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),
                                            withIntermediateDirectories:true)
    try png.write(to:url)
    print("Verified \(destination): \(size)x\(size), \(png.count) bytes")
}
try export(image,1024,"RepoPulse/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try export(image,256,"RepoPulse/Assets.xcassets/RepoPulseMark.imageset/RepoPulseMark.png")
