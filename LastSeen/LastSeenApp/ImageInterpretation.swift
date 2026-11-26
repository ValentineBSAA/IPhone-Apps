import SwiftUI
import UIKit

/// Authored interpretive layers are not recovered pixels or proof of a subject.
enum ImageInterpretation {
    enum Mode:String,CaseIterable,Identifiable {
        case original, monochrome, channels, shadow, echo, scanlines
        var id:String {rawValue}
        var title:String {
            switch self {
            case .original:return "Original"
            case .monochrome:return "Monochrome"
            case .channels:return "Channel emphasis"
            case .shadow:return "Shadow lift"
            case .echo:return "Signal echo"
            case .scanlines:return "Scanline reconstruction"
            }
        }
        var synthetic:Bool {self == .echo || self == .scanlines}
    }
    struct Finding:Identifiable {
        let id:String
        let asset:String
        let mode:Mode
        let region:Int
        let note:String
        var pattern:Pattern = .outline
        var confidence:String {"Uncertain · interpretive"}
    }
    enum Pattern: Equatable {
        case outline, interruptedBars, displacedCorners, rings, shadowFigure, reflectionFragment, brokenFrame
        var description:String {
            switch self {
            case .outline:return "A broken angular outline"
            case .interruptedBars:return "Interrupted parallel bars"
            case .displacedCorners:return "Two displaced corners"
            case .rings:return "Concentric rings"
            case .shadowFigure:return "An indistinct upright shadow"
            case .reflectionFragment:return "A fractured reflective contour"
            case .brokenFrame:return "An incomplete rectangular frame"
            }
        }
    }
    private static let authored:[Finding] = [
        .init(id:"interpretation-01",asset:"Recovered_B27_02",mode:.echo,region:2,note:"The synthetic echo adds an outline absent from the unmodified preview. It is not evidence of a second subject."),
        .init(id:"interpretation-02",asset:"Nora_Archive_08",mode:.scanlines,region:4,note:"The reconstructed layer adds an interrupted geometric mark. It belongs to the interpretation layer, not the original photograph.",pattern:.interruptedBars),
        .init(id:"interpretation-03",asset:"Nora_Archive_09",mode:.echo,region:6,note:"The interpretive layer introduces a displaced border fragment. Compare it to the unchanged original before recording any theory.",pattern:.displacedCorners),
        .init(id:"interpretation-04",asset:"Nora_Archive_10",mode:.scanlines,region:1,note:"The reconstructed bands introduce a repeated circular trace. The trace is authored preview content rather than a feature authenticated in the source.",pattern:.rings),
        .init(id:"interpretation-05",asset:"Recovered_B27_03",mode:.scanlines,region:8,note:"A discontinuity appears in the synthetic bands. It is not a verified physical object in the original reference.",pattern:.interruptedBars),
        .init(id:"interpretation-06",asset:"Recovered_B27_13",mode:.echo,region:3,note:"The echoed preview contains a displaced shape. The underlying original remains unchanged.",pattern:.displacedCorners),
        .init(id:"interpretation-07",asset:"VEIL_Home_02",mode:.echo,region:5,note:"An extra border trace appears only in the synthetic echo. The source image does not establish a recording device.",pattern:.displacedCorners),
        .init(id:"interpretation-08",asset:"VEIL_Home_04",mode:.scanlines,region:1,note:"A repeated ring appears only in the reconstruction. It cannot establish a person or event outside the frame.",pattern:.rings),
        .init(id:"interpretation-09",asset:"VEIL_Home_06",mode:.echo,region:3,note:"The interpretation adds a broken outline. Keep it separate from the visible furnishings and original pixels.",pattern:.outline),
        .init(id:"interpretation-10",asset:"VEIL_Home_01",mode:.echo,region:2,note:"The authored echo introduces a vague upright shadow. The original does not establish an additional person.",pattern:.shadowFigure),
        .init(id:"interpretation-11",asset:"VEIL_Home_03",mode:.scanlines,region:3,note:"A fractured reflective contour is introduced by the reconstruction. It is not an authenticated reflection in the photograph.",pattern:.reflectionFragment),
        .init(id:"interpretation-12",asset:"VEIL_Home_05",mode:.echo,region:1,note:"An incomplete frame-like shape is added by the interpretive layer. It cannot establish a hidden opening or object.",pattern:.brokenFrame)
    ]
    static let regions=["Upper left","Upper middle","Upper right","Middle left","Center","Middle right","Lower left","Lower middle","Lower right"]
    static func modes(_ asset:String,in world:PhoneWorld)->[Mode] {
        guard RecoveredImageAnalysis.record(asset,in:world) != nil else{return []}
        guard RecoveredImageAnalysis.completed(asset,in:world),world.flags.contains("phone-tutorial-finished") else{return [.original]}
        var result:[Mode]=[.original,.monochrome,.channels,.shadow]
        if world.flags.contains("web.visited.archive"),LumaWebCatalog.page("archive")?.available(world.flags)==true {result += [.echo,.scanlines]}
        return result
    }
    static func displayMode(_ requested:Mode,asset:String,in world:PhoneWorld,horrorEnabled:Bool,compareOriginal:Bool)->Mode {
        guard !compareOriginal,modes(asset,in:world).contains(requested),horrorEnabled || !requested.synthetic else{return .original}
        return requested
    }
    static func available(_ asset:String,mode:Mode,in world:PhoneWorld)->Finding? {
        guard modes(asset,in:world).contains(mode),mode.synthetic else{return nil}
        return authored.first{$0.asset==asset && $0.mode==mode}
    }
    static func accepts(_ asset:String,mode:Mode,region:Int,in world:PhoneWorld)->Finding? {
        guard let finding=available(asset,mode:mode,in:world),finding.region==region else{return nil}
        return finding
    }
    static func comparisonAccepts(_ asset:String,mode:Mode,region:Int,
                                  inspectedOriginal:Bool,inspectedLayer:Bool,in world:PhoneWorld)->Bool {
        inspectedOriginal && inspectedLayer && accepts(asset,mode:mode,region:region,in:world) != nil
    }
    static func recorded(_ world:PhoneWorld)->[Finding] {
        authored.filter{f in
            available(f.asset,mode:f.mode,in:world) != nil && world.connectedWorld?.imageInterpretationFindings?.contains(f.id)==true
        }
    }
    static func notes(_ asset:String,in world:PhoneWorld)->[String] {
        recorded(world).filter{$0.asset==asset}.map{"Interpretive observation (uncertain): "+$0.note}
    }
}
struct ImageInterpretationPreview:View {
    let image:UIImage
    let mode:ImageInterpretation.Mode
    let finding:ImageInterpretation.Finding?
    let strength:Double
    var body:some View {
        ZStack {
            Image(uiImage:image).resizable().scaledToFit()
                .saturation(mode == .monochrome ? 0 : 1)
                .colorMultiply(mode == .channels ? Color(red:0.85,green:1,blue:0.87):.white)
                .brightness(mode == .shadow ? 0.15*strength : 0)
            if mode == .echo {
                Image(uiImage:image).resizable().scaledToFit().saturation(0).colorMultiply(.purple)
                    .opacity(0.18*strength).offset(x:6*strength,y:2*strength)
            }
            if mode == .scanlines {
                GeometryReader {g in
                    Path { p in
                        for y in stride(from:0.0,to:Double(g.size.height),by:6.0) {
                            p.move(to:CGPoint(x:0,y:y));p.addLine(to:CGPoint(x:g.size.width,y:y))
                        }
                    }.stroke(Color.purple.opacity(0.35*strength),lineWidth:1)
                }.allowsHitTesting(false).accessibilityHidden(true)
            }
            if let finding, mode.synthetic {
                GeometryReader {g in
                    let x=(CGFloat(finding.region%3)+0.5)*g.size.width/3
                    let y=(CGFloat(finding.region/3)+0.5)*g.size.height/3
                    Path {p in
                        switch finding.pattern {
                        case .outline:
                            p.move(to:CGPoint(x:x-13,y:y+8));p.addLine(to:CGPoint(x:x,y:y-13))
                            p.addLine(to:CGPoint(x:x+13,y:y+8))
                            p.move(to:CGPoint(x:x-7,y:y+8));p.addLine(to:CGPoint(x:x+7,y:y+8))
                        case .interruptedBars:
                            for dy in [CGFloat(-9),CGFloat(0),CGFloat(9)] {
                                p.move(to:CGPoint(x:x-14,y:y+dy));p.addLine(to:CGPoint(x:x-3,y:y+dy))
                                p.move(to:CGPoint(x:x+4,y:y+dy));p.addLine(to:CGPoint(x:x+13,y:y+dy))
                            }
                        case .displacedCorners:
                            p.move(to:CGPoint(x:x-13,y:y+4));p.addLine(to:CGPoint(x:x-13,y:y-12));p.addLine(to:CGPoint(x:x+3,y:y-12))
                            p.move(to:CGPoint(x:x+13,y:y-4));p.addLine(to:CGPoint(x:x+13,y:y+12));p.addLine(to:CGPoint(x:x-3,y:y+12))
                        case .rings:
                            p.addEllipse(in:CGRect(x:x-12,y:y-12,width:24,height:24))
                            p.addEllipse(in:CGRect(x:x-5,y:y-5,width:10,height:10))
                        case .shadowFigure:
                            p.addEllipse(in:CGRect(x:x-6,y:y-27,width:12,height:14))
                            p.move(to:CGPoint(x:x-7,y:y-12))
                            p.addQuadCurve(to:CGPoint(x:x-13,y:y+24),control:CGPoint(x:x-16,y:y))
                            p.addLine(to:CGPoint(x:x+14,y:y+24))
                            p.addQuadCurve(to:CGPoint(x:x+7,y:y-12),control:CGPoint(x:x+17,y:y))
                            p.closeSubpath()
                        case .reflectionFragment:
                            p.move(to:CGPoint(x:x-18,y:y-20));p.addLine(to:CGPoint(x:x+2,y:y-8))
                            p.addLine(to:CGPoint(x:x-6,y:y+1))
                            p.move(to:CGPoint(x:x+7,y:y-4));p.addLine(to:CGPoint(x:x+18,y:y+16))
                            p.addLine(to:CGPoint(x:x-4,y:y+22))
                        case .brokenFrame:
                            p.move(to:CGPoint(x:x-18,y:y+12));p.addLine(to:CGPoint(x:x-18,y:y-23))
                            p.addLine(to:CGPoint(x:x+18,y:y-23));p.addLine(to:CGPoint(x:x+18,y:y-5))
                            p.move(to:CGPoint(x:x+18,y:y+7));p.addLine(to:CGPoint(x:x+18,y:y+23))
                            p.addLine(to:CGPoint(x:x-5,y:y+23))
                        }
                    }.stroke(finding.pattern == .shadowFigure ? Color.black.opacity(0.85*strength) : Color.white.opacity(0.70*strength),
                             style:StrokeStyle(lineWidth:finding.pattern == .shadowFigure ? 5:2,
                                               dash:finding.pattern == .shadowFigure ? []:[5,3]))
                }.allowsHitTesting(false).accessibilityHidden(true)
            }
        }.clipped().accessibilityLabel(mode.synthetic ? "Synthetic interpretive preview, not original pixels":"Adjusted image preview")
    }
}
private struct LumaImageHandoffKey:EnvironmentKey {
    static let defaultValue:((String)->Void)? = nil
}
extension EnvironmentValues {
    var sendImageToLuma:((String)->Void)? {
        get{self[LumaImageHandoffKey.self]}
        set{self[LumaImageHandoffKey.self]=newValue}
    }
}
struct SendImageToLumaButton:View {
    let asset:String
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.sendImageToLuma) private var send
    @Environment(\.scenePhase) private var phase
    var body:some View {
        if let send,phase == .active,RecoveredImageAnalysis.record(asset,in:world.state) != nil {
            Button {
                guard phase == .active,RecoveredImageAnalysis.record(asset,in:world.state) != nil else{return}
                send(asset)
            } label: {Label("Send to Luma for analysis",systemImage:"waveform.circle.fill")}
                .buttonStyle(.borderedProminent)
        }
    }
}


/// Explicit A/B inspection, with a fixed aligned preview. No flashes,
/// automatic changes or modified original image data.
struct ReconstructionComparisonView:View {
    let asset:String
    let mode:ImageInterpretation.Mode
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.veil.security") private var security="Standard"
    @AppStorage("lastseen.lab.horrorEffects") private var horrorEffects=true
    @State private var textOnly=false
    @State private var reveal=false
    @State private var layer=false
    @State private var inspectionEpoch:UUID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var seenOriginal=false
    @State private var seenLayer=false
    @State private var strength=0.8
    @State private var region:Int?
    @State private var notice=""
    private var visualAllowed:Bool {
        guard let record=RecoveredImageAnalysis.record(asset,in:world.state) else{return false}
        return horrorEffects && !textOnly && (record.source != .veil || VeilArchive.allowsImages(security))
    }
    private func reset() {
        reveal=false;layer=false;seenOriginal=false;seenLayer=false;strength=0.8;region=nil;notice="";inspectionEpoch=nil
    }
    var body:some View {
        List {
            if let finding=ImageInterpretation.available(asset,mode:mode,in:world.state),phase == .active {
                Section {
                    Text("Compare original and reconstruction").font(.headline)
                    Text("The reconstructed view is a fictional analysis layer. It can introduce shapes that never existed in the original.").font(.caption).foregroundColor(.secondary)
                    Toggle("Text-only comparison",isOn:$textOnly)
                    if visualAllowed {
                        Toggle("Reveal comparison",isOn:$reveal)
                    }
                }
                if reveal || !visualAllowed {
                    Section("Inspection") {
                        Picker("View",selection:$layer) {
                            Text("Original").tag(false)
                            Text("Reconstruction").tag(true)
                        }.pickerStyle(.segmented)
                        if visualAllowed,let image=PortraitImages.load(asset) {
                            let aspect=max(0.1,image.size.width/max(1,image.size.height))
                            ImageInterpretationPreview(image:image,mode:layer ? mode:.original,
                                finding:layer ? finding:nil,strength:strength)
                                .aspectRatio(aspect,contentMode:.fit)
                            if layer {
                                Text("Reconstruction strength")
                                Slider(value:$strength,in:0.3...1,step:0.05)
                            }
                        } else {
                            Text(layer ? finding.pattern.description+" appears in the "+ImageInterpretation.regions[finding.region].lowercased()+" region of the synthetic layer.":"Unmodified original: the authored marker is not part of this view.")
                                .font(.subheadline)
                        }
                        Button(layer ? "Mark reconstruction inspected":"Mark original inspected") {
                            guard phase == .active,ImageInterpretation.available(asset,mode:mode,in:world.state) != nil else{return}
                            if inspectionEpoch != world.checkpointEpoch {seenOriginal=false;seenLayer=false;region=nil;inspectionEpoch=world.checkpointEpoch}
                            if layer {seenLayer=true} else {seenOriginal=true}
                        }.buttonStyle(.bordered)
                        Label(seenOriginal ? "Original inspected":"Original not yet inspected",systemImage:seenOriginal ? "checkmark.circle":"circle")
                        Label(seenLayer ? "Reconstruction inspected":"Reconstruction not yet inspected",systemImage:seenLayer ? "checkmark.circle":"circle")
                    }
                    Section("Locate the introduced detail") {
                        LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:dynamicTypeSize.isAccessibilitySize ? 1:3),spacing:6) {
                            ForEach(0..<9,id:\.self) { i in
                                Button {
                                    guard phase == .active,inspectionEpoch==world.checkpointEpoch,seenOriginal,seenLayer else{return}
                                    region=i;notice=""
                                } label:{
                                    Text(ImageInterpretation.regions[i]).font(.caption)
                                        .frame(maxWidth:.infinity,minHeight:44)
                                }.buttonStyle(.bordered).tint(region==i ? .purple:.secondary)
                                    .accessibilityAddTraits(region==i ? .isSelected:[])
                                    .disabled(!seenOriginal || !seenLayer || inspectionEpoch != world.checkpointEpoch)
                            }
                        }
                        Button("Record comparison") {
                            guard phase == .active,inspectionEpoch == world.checkpointEpoch,let region else{return}
                            guard ImageInterpretation.comparisonAccepts(asset,mode:mode,region:region,
                                inspectedOriginal:seenOriginal,inspectedLayer:seenLayer,in:world.state) else {
                                notice="Revisit both views and locate the introduced detail.";return
                            }
                            notice=world.recordImageInterpretation(asset,mode:mode,region:region) ?
                                "Interpretive observation saved.":"Comparison unavailable."
                        }.buttonStyle(.borderedProminent).disabled(!seenOriginal || !seenLayer || region==nil)
                        if !notice.isEmpty {Text(notice).font(.caption)}
                    }
                }
                if ImageInterpretation.recorded(world.state).contains(where:{$0.id==finding.id}) {
                    Section("Recorded interpretation") {Text(finding.note)}
                }
            } else { Text("Comparison unavailable.") }
        }.navigationTitle("Reconstruction comparison")
        .onChange(of:world.checkpointEpoch){_ in reset()}
        .onChange(of:ImageInterpretation.available(asset,mode:mode,in:world.state)?.id){_ in reset()}
        .onChange(of:phase){if $0 != .active {reset()}}
        .onChange(of:security){_ in reset()}
        .onChange(of:horrorEffects){_ in reset()}
        .onChange(of:textOnly){_ in reset()}
        .onChange(of:reveal){if !$0 {seenOriginal=false;seenLayer=false;region=nil;notice="";inspectionEpoch=nil}}
        .onDisappear{reset()}
    }
}
