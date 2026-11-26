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
        var confidence:String {"Uncertain · interpretive"}
    }
    private static let authored:[Finding] = [
        .init(id:"interpretation-01",asset:"Recovered_B27_02",mode:.echo,region:2,note:"The synthetic echo adds an outline absent from the unmodified preview. It is not evidence of a second subject."),
        .init(id:"interpretation-02",asset:"Nora_Archive_08",mode:.scanlines,region:4,note:"The reconstructed layer adds an interrupted geometric mark. It belongs to the interpretation layer, not the original photograph.")
    ]
    static let regions=["Upper left","Upper middle","Upper right","Middle left","Center","Middle right","Lower left","Lower middle","Lower right"]
    static func modes(_ asset:String,in world:PhoneWorld)->[Mode] {
        guard RecoveredImageAnalysis.record(asset,in:world) != nil else{return []}
        guard RecoveredImageAnalysis.completed(asset,in:world),world.flags.contains("phone-tutorial-finished") else{return [.original]}
        var result:[Mode]=[.original,.monochrome,.channels,.shadow]
        if world.flags.contains("web.visited.archive"),LumaWebCatalog.page("archive")?.available(world.flags)==true {result += [.echo,.scanlines]}
        return result
    }
    static func available(_ asset:String,mode:Mode,in world:PhoneWorld)->Finding? {
        guard modes(asset,in:world).contains(mode),mode.synthetic else{return nil}
        return authored.first{$0.asset==asset && $0.mode==mode}
    }
    static func accepts(_ asset:String,mode:Mode,region:Int,in world:PhoneWorld)->Finding? {
        guard let finding=available(asset,mode:mode,in:world),finding.region==region else{return nil}
        return finding
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
                        p.move(to:CGPoint(x:x-13,y:y+8));p.addLine(to:CGPoint(x:x,y:y-13))
                        p.addLine(to:CGPoint(x:x+13,y:y+8))
                        p.move(to:CGPoint(x:x-7,y:y+8));p.addLine(to:CGPoint(x:x+7,y:y+8))
                    }.stroke(Color.white.opacity(0.70*strength),style:StrokeStyle(lineWidth:2,dash:[5,3]))
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
    var body:some View {
        if let send,RecoveredImageAnalysis.record(asset,in:world.state) != nil {
            Button {
                guard RecoveredImageAnalysis.record(asset,in:world.state) != nil else{return}
                send(asset)
            } label: {Label("Send to Luma for analysis",systemImage:"waveform.circle.fill")}
                .buttonStyle(.borderedProminent)
        }
    }
}
