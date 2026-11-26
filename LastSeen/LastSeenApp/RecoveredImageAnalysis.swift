import SwiftUI
import UIKit
import CoreGraphics

/// An optional, read-only tool for already inspected, authorized game images.
/// Private albums require a separate authenticated session and are excluded.
enum RecoveredImageAnalysis {
    enum Source:Int,CaseIterable {
        case cameraRoll, browser, veil
        var title:String {
            switch self {
            case .cameraRoll:return "Restored camera roll"
            case .browser:return "Regular browser attachment"
            case .veil:return "Recovered anonymous archive"
            }
        }
    }
    struct Record:Identifiable {
        let id:String
        let source:Source
        var title:String {source.title+" · "+String(id.suffix(2))}
    }
    static let limits=["Preview adjustments change display only; original provenance remains unverified.",
                       "Brightness adjustment verifies who captured the image.",
                       "A copied image proves its original capture date."]
    static func cameraMarker(_ id:String)->String {"analysis.opened.camera."+id}
    static func cameraAvailable(_ id:String,in world:PhoneWorld)->Bool {
        world.everydayArchiveRevision != nil && NoraPhotoCatalog.photos.contains {
            $0.id == id && !$0.privateAlbum && $0.available(flags:NoraPhotoCatalog.discoveryFlags(from:world.flags))
        }
    }
    static func visible(_ world:PhoneWorld)->[Record] {
        guard world.everydayArchiveRevision != nil else{return []}
        var records=NoraPhotoCatalog.photos.filter {
            cameraAvailable($0.id,in:world) && world.flags.contains(cameraMarker($0.id))
        }.map {Record(id:$0.id,source:.cameraRoll)}
        let seenPages=LumaWebCatalog.visible(world.flags).filter{world.flags.contains("web.visited."+$0.id)}
        let images=Set(seenPages.flatMap(\.images)).filter{world.flags.contains("web.inspected."+$0)}
        records += images.sorted().map{Record(id:$0,source:.browser)}
        if VeilArchive.authorized(world) {
            records += VeilArchive.media(world).filter{world.flags.contains("veil.viewed."+$0)}.map{Record(id:$0,source:.veil)}
        }
        return records
    }
    static func record(_ id:String,in world:PhoneWorld)->Record? {visible(world).first{$0.id==id}}
    static func completed(_ id:String,in world:PhoneWorld)->Bool {
        record(id,in:world) != nil && world.connectedWorld?.recoveredImageReviews?.contains(id)==true
    }
    static func accepts(_ id:String,source:Int,limit:Int,in world:PhoneWorld)->Bool {
        guard let record=record(id,in:world) else{return false}
        return source==record.source.rawValue && limit==0
    }
    static func summary(_ id:String,in world:PhoneWorld)->String? {
        guard completed(id,in:world),let record=record(id,in:world) else{return nil}
        return "Image analysis recorded. Source collection: "+record.source.title+". "+limits[0]
    }
    /// Actual image-derived brightness sample, not EXIF or scene recognition.
    /// Fixed small buffer, no image upload, no face or location identification.
    static func brightnessBins(_ image:UIImage)->[Int]? {
        guard let cg=image.cgImage else{return nil}
        let n=32
        var pixels=[UInt8](repeating:0,count:n*n*4)
        let rendered=pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let base=raw.baseAddress,let ctx=CGContext(data:base,width:n,height:n,bitsPerComponent:8,bytesPerRow:n*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else{return false}
            ctx.interpolationQuality = .medium
            ctx.draw(cg,in:CGRect(x:0,y:0,width:n,height:n))
            return true
        }
        guard rendered else{return nil}
        var bins=[0,0,0]
        for i in stride(from:0,to:pixels.count,by:4) {
            let lum=(54*Int(pixels[i])+183*Int(pixels[i+1])+19*Int(pixels[i+2]))/256
            bins[min(2,lum/86)]+=1
        }
        return bins
    }
}
struct RecoveredImageAnalysisView:View {
    let asset:String
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.veil.security") private var security="Standard"
    @State private var reveal=false
    @State private var textOnly=false
    @State private var brightness=0.0
    @State private var contrast=1.0
    @State private var zoom=1.0
    @State private var bins:[Int]?
    @State private var binChoice:Int?
    @State private var binFeedback=""
    @State private var source:Int?
    @State private var limit:Int?
    @State private var feedback=""
    @State private var mode=ImageInterpretation.Mode.original
    @State private var compareOriginal=false
    @State private var strength=0.7
    @State private var region:Int?
    @State private var interpretationFeedback=""
    @AppStorage("lastseen.lab.horrorEffects") private var horrorEffects=true
    private let bandNames=["Dark","Midtones","Light"]
    private func resetPreview(){reveal=false;brightness=0;contrast=1;zoom=1;bins=nil;binChoice=nil;binFeedback="";mode = .original;compareOriginal=false;region=nil;interpretationFeedback=""}
    var body:some View {
        List {
            if let item=RecoveredImageAnalysis.record(asset,in:world.state) {
                Section {
                    LumaHeader(title:"Image analysis",detail:item.title,symbol:"viewfinder")
                    Text("Inspect an already recovered reference. Adjustments affect only the preview, never the original.").font(.subheadline)
                    Toggle("Text-only inspection",isOn:$textOnly)
                    SendImageToLumaButton(asset:asset)
                }
                Section("Source record") {
                    Text(item.source.title)
                    Text("Original capture time and photographer are not independently established by this local copy.").font(.caption).foregroundColor(.secondary)
                }
                if !textOnly && (item.source != .veil || VeilArchive.allowsImages(security)) {
                    Section("Visual inspection") {
                        Button(reveal ? "Hide preview":"Reveal preview") {
                            if reveal {resetPreview()} else if phase == .active {
                                reveal=true
                                if let image=PortraitImages.load(asset){bins=RecoveredImageAnalysis.brightnessBins(image)}
                            }
                        }.disabled(phase != .active)
                        if reveal && phase == .active {
                            if let image=PortraitImages.load(asset) {
                                ScrollView([.horizontal,.vertical]) {
                                    let effective=ImageInterpretation.displayMode(mode,asset:asset,in:world.state,horrorEnabled:horrorEffects,compareOriginal:compareOriginal)
                                    let width=CGFloat(240*zoom)
                                    let aspect=max(0.1,image.size.width/max(1,image.size.height))
                                    ImageInterpretationPreview(image:image,mode:effective,finding:ImageInterpretation.available(asset,mode:effective,in:world.state),strength:strength)
                                        .frame(width:width,height:width/aspect)
                                        .brightness(compareOriginal ? 0:brightness).contrast(compareOriginal ? 1:contrast)
                                }.frame(height:240)
                                Toggle("Compare with untouched original",isOn:$compareOriginal)
                                Text(compareOriginal ? "Original pixels · display adjustments bypassed" : "Adjusted preview · original unchanged").font(.caption).foregroundColor(.secondary)
                                Text("Brightness");Slider(value:$brightness,in:-0.25...0.35,step:0.05).disabled(compareOriginal)
                                Text("Contrast");Slider(value:$contrast,in:0.7...1.4,step:0.05).disabled(compareOriginal)
                                Text("Magnification");Slider(value:$zoom,in:1...2.5,step:0.1)
                                Button("Reset adjustments"){brightness=0;contrast=1;zoom=1}
                            } else {Text("Preview unavailable; use text-only inspection.")}
                            if let bins {
                                Text("Original brightness sample").font(.headline)
                                ForEach(bins.indices,id:\.self){i in
                                    VStack(alignment:.leading) {
                                        Text(bandNames[i]+" · "+String(bins[i])+" of 1024")
                                        ProgressView(value:Double(bins[i]),total:1024).tint(.purple)
                                    }
                                }
                                Text("Which range has the most sampled pixels?").font(.subheadline)
                                ForEach(bins.indices,id:\.self){i in
                                    Button(bandNames[i]){
                                        binChoice=i
                                        binFeedback=bins[i]==bins.max() ? "Sample interpreted correctly. This does not authenticate the source.":"Compare the three counts and try again."
                                    }.buttonStyle(.bordered).tint(binChoice==i ? .purple:.secondary)
                                }
                                if !binFeedback.isEmpty{Text(binFeedback).font(.caption)}
                            }
                        }
                    }
                } else {
                    Section("Text inspection"){Text("The same source review is available without displaying any image.")}
                }
                let modes=ImageInterpretation.modes(asset,in:world.state)
                if modes.count > 1 {
                    Section("Analysis layers") {
                        Picker("Layer",selection:$mode) {
                            ForEach(modes){m in Text(m.title).tag(m)}
                        }
                        if mode.synthetic {
                            Text("Interpretive reconstruction. This layer may introduce shapes not present in the original.").font(.caption).foregroundColor(.secondary)
                            if !horrorEffects || textOnly || (item.source == .veil && !VeilArchive.allowsImages(security)) {
                                Text("Visual effects hidden. Text-based inspection remains available.").font(.caption)
                            } else {
                                Text("Layer strength");Slider(value:$strength,in:0.3...1,step:0.05)
                            }
                        }
                        if let finding=ImageInterpretation.available(asset,mode:mode,in:world.state) {
                            if textOnly || !horrorEffects || (item.source == .veil && !VeilArchive.allowsImages(security)) {
                                Text("The synthetic layer has a marker at "+ImageInterpretation.regions[finding.region]+". Select that region to record the observation.").font(.subheadline)
                            } else {
                                Text("Compare the synthetic layer with Original. Locate the interrupted marker in the preview.").font(.subheadline)
                            }
                            LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:3)) {
                                ForEach(0..<9,id:\.self){i in
                                    Button {region=i;interpretationFeedback=""} label:{
                                        Text(ImageInterpretation.regions[i]).font(.caption).frame(maxWidth:.infinity,minHeight:44)
                                    }.buttonStyle(.bordered).tint(region==i ? .purple:.secondary)
                                }
                            }
                            Button("Record interpretation") {
                                guard let region,phase == .active else{return}
                                interpretationFeedback=world.recordImageInterpretation(asset,mode:mode,region:region) ? "Interpretive observation saved.":"Compare the layer and try again."
                            }.buttonStyle(.borderedProminent).disabled(region==nil || phase != .active || ((!reveal || compareOriginal) && !textOnly && horrorEffects && (item.source != .veil || VeilArchive.allowsImages(security))))
                            if !interpretationFeedback.isEmpty{Text(interpretationFeedback).font(.caption)}
                        }
                        ForEach(ImageInterpretation.notes(asset,in:world.state),id:\.self){note in Text(note).font(.subheadline)}
                        Button("Return to original"){mode = .original;compareOriginal=false;brightness=0;contrast=1;zoom=1;region=nil}
                    }
                }
                if let summary=RecoveredImageAnalysis.summary(asset,in:world.state) {
                    Section("Recorded observation"){Label(summary,systemImage:"checkmark.seal").foregroundColor(.teal)}
                } else {
                    Section("1. Which collection contains this reference?") {
                        ForEach(RecoveredImageAnalysis.Source.allCases,id:\.rawValue){option in
                            Button{source=option.rawValue;feedback=""}label:{
                                Label(option.title,systemImage:source==option.rawValue ? "largecircle.fill.circle":"circle")
                            }.buttonStyle(.plain).accessibilityAddTraits(source==option.rawValue ? .isSelected:[])
                        }
                    }
                    Section("2. What can the preview establish?") {
                        ForEach(RecoveredImageAnalysis.limits.indices,id:\.self){i in
                            Button{limit=i;feedback=""}label:{
                                Label(RecoveredImageAnalysis.limits[i],systemImage:limit==i ? "largecircle.fill.circle":"circle")
                            }.buttonStyle(.plain).accessibilityAddTraits(limit==i ? .isSelected:[])
                        }
                        Button("Record analysis"){
                            guard let source,let limit else{return}
                            feedback=world.completeRecoveredImageAnalysis(asset,source:source,limit:limit) ? "Observation saved.":"Review the collection and source limitations, then try again."
                        }.buttonStyle(.borderedProminent).disabled(source==nil || limit==nil)
                        if !feedback.isEmpty{Text(feedback).font(.caption)}
                    }
                }
            } else {Label("This image has not been recovered or inspected.",systemImage:"lock")}
        }.navigationTitle("Image analysis").navigationBarTitleDisplayMode(.inline)
            .onChange(of:phase){if $0 != .active{resetPreview()}}
            .onChange(of:security){_ in resetPreview()}
            .onChange(of:textOnly){_ in resetPreview()}
            .onChange(of:horrorEffects){_ in resetPreview()}
            .onChange(of:mode){_ in compareOriginal=false;region=nil;interpretationFeedback=""}
            .onDisappear{resetPreview()}
    }
}
