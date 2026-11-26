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
    struct Record:Identifiable,Equatable {
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
        let images=Set(LumaWebCatalog.visitedAttachments(in:world.flags)).filter{world.flags.contains("web.inspected."+$0)}
        records += images.sorted().map{Record(id:$0,source:.browser)}
        if VeilArchive.authorized(world) {
            records += VeilArchive.media(world).filter{world.flags.contains("veil.viewed."+$0)}.map{Record(id:$0,source:.veil)}
        }
        return records
    }
    static func record(_ id:String,in world:PhoneWorld)->Record? {visible(world).first{$0.id==id}}
    static func inspectionCurrent(_ asset:String,source:Source?,epoch:UUID?,currentEpoch:UUID,active:Bool,in world:PhoneWorld)->Bool {
        guard active,epoch == currentEpoch,let source else{return false}
        return record(asset,in:world)?.source == source
    }
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
    /// Nine measured regions of a downsampled original, never a synthetic layer.
    static func regionalLight(_ image:UIImage)->[Int]? {
        guard let cg=image.cgImage else{return nil}
        let n=36
        var pixels=[UInt8](repeating:0,count:n*n*4)
        let rendered=pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let base=raw.baseAddress,let ctx=CGContext(data:base,width:n,height:n,
                bitsPerComponent:8,bytesPerRow:n*4,space:CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else{return false}
            ctx.interpolationQuality = .medium
            ctx.draw(cg,in:CGRect(x:0,y:0,width:n,height:n))
            return true
        }
        guard rendered else{return nil}
        var sums=[Int](repeating:0,count:9)
        for y in 0..<n {
            for x in 0..<n {
                let i=(y*n+x)*4
                let light=(54*Int(pixels[i])+183*Int(pixels[i+1])+19*Int(pixels[i+2]))/256
                sums[(y/12)*3+x/12]+=light
            }
        }
        return sums.map{$0/144}
    }
    static func validLightPair(_ values:[Int],dark:Int,bright:Int)->Bool {
        guard values.count == 9,values.allSatisfy({(0...255).contains($0)}),
              values.indices.contains(dark),values.indices.contains(bright),dark != bright,
              let low=values.min(),let high=values.max(),high>low else{return false}
        return values[dark]==low && values[bright]==high
    }
    /// Recompute from current access; never persist a second copy of findings.
    static func reviewOverview(_ world:PhoneWorld)->(opened:Int,reviewed:Int,light:Int,matched:Int,interpretive:Int) {
        let records=visible(world)
        let ids=Set(records.map(\.id))
        let reviewed=ids.intersection(world.connectedWorld?.recoveredImageReviews ?? [])
        let light=reviewed.intersection(world.connectedWorld?.regionalLightReviews ?? [])
        let matched=PhotoFeatureMatch.available(world).filter{PhotoFeatureMatch.completed($0,in:world)}.count
        return (ids.count,reviewed.count,light.count,matched,ImageInterpretation.recorded(world).count)
    }
    static func lightNote(_ asset:String,in world:PhoneWorld)->String? {
        guard completed(asset,in:world),
              world.connectedWorld?.regionalLightReviews?.contains(asset)==true else{return nil}
        return "Original-image regional light scan completed. The strongest measured contrast was located in the sampled grid. Brightness is not evidence of capture time, identity or an unseen object."
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
    @State private var inspectionEpoch:UUID?
    @State private var inspectionSource:RecoveredImageAnalysis.Source?
    @AppStorage("lastseen.lab.horrorEffects") private var horrorEffects=true
    private let bandNames=["Dark","Midtones","Light"]
    private var item:RecoveredImageAnalysis.Record? {RecoveredImageAnalysis.record(asset,in:world.state)}
    private var currentInspection:Bool {RecoveredImageAnalysis.inspectionCurrent(asset,source:inspectionSource,epoch:inspectionEpoch,currentEpoch:world.checkpointEpoch,active:phase == .active,in:world.state)}
    private func resetPreview(){reveal=false;brightness=0;contrast=1;zoom=1;bins=nil;binChoice=nil;binFeedback="";mode = .original;compareOriginal=false;strength=0.7;region=nil;interpretationFeedback=""}
    private func resetInspection(){resetPreview();source=nil;limit=nil;feedback="";inspectionEpoch=nil;inspectionSource=nil}
    private func refreshInspection(){resetInspection();if phase == .active,let item {inspectionEpoch=world.checkpointEpoch;inspectionSource=item.source}}
    var body:some View {
        List {
            if let item,currentInspection {
                Section {
                    LumaHeader(title:"Image analysis",detail:item.title,symbol:"viewfinder")
                    Text("Inspect an already recovered reference. Adjustments affect only the preview, never the original.").font(.subheadline)
                    Toggle("Text-only inspection",isOn:$textOnly)
                    SendImageToLumaButton(asset:asset)
                    NavigationLink { ImageReviewOverviewView() } label:{
                        Label("My image investigation",systemImage:"checklist")
                    }
                }
                Section("Source record") {
                    Text(item.source.title)
                    if item.source == .veil,let description=VeilArchive.mediaDescription(asset) {
                        Text(description).font(.subheadline)
                    } else if item.source == .browser,let description=LumaWebCatalog.referenceDescriptions[asset] {
                        Text(description).font(.subheadline)
                    } else if item.source == .cameraRoll,let description=NoraPhotoCatalog.everydayDescriptions[asset] {
                        Text(description).font(.subheadline)
                    }
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
                if RecoveredImageAnalysis.completed(asset,in:world.state),phase == .active {
                    Section("Regional light scan") {
                        RegionalLightScanView(asset:asset)
                    }
                }
                let detailChallenges=PhotoFeatureMatch.available(world.state).filter{$0.assets.contains(asset)}
                if !detailChallenges.isEmpty,phase == .active {
                    Section("Compare recurring details") {
                        ForEach(detailChallenges) { challenge in
                            NavigationLink { PhotoFeatureMatchView(challengeID:challenge.id) } label:{
                                Label(challenge.title,systemImage:PhotoFeatureMatch.completed(challenge,in:world.state) ? "checkmark.circle":"viewfinder")
                            }
                        }
                    }
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
                            NavigationLink { ReconstructionComparisonView(asset:asset,mode:finding.mode) } label:{
                                Label("Compare original and reconstruction",systemImage:"rectangle.split.2x1")
                            }
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
                            guard let source,let limit,currentInspection else{return}
                            feedback=world.completeRecoveredImageAnalysis(asset,source:source,limit:limit) ? "Observation saved.":"Review the collection and source limitations, then try again."
                        }.buttonStyle(.borderedProminent).disabled(source==nil || limit==nil)
                        if !feedback.isEmpty{Text(feedback).font(.caption)}
                    }
                }
            } else {Label("Image inspection unavailable in this session.",systemImage:"lock")}
        }.navigationTitle("Image analysis").navigationBarTitleDisplayMode(.inline)
            .onAppear{refreshInspection()}
            .onChange(of:world.checkpointEpoch){_ in refreshInspection()}
            .onChange(of:item){_ in refreshInspection()}
            .onChange(of:ImageInterpretation.modes(asset,in:world.state)){modes in if !modes.contains(mode){resetPreview()}}
            .onChange(of:phase){if $0 != .active{resetInspection()}else{refreshInspection()}}
            .onChange(of:security){_ in resetPreview()}
            .onChange(of:textOnly){_ in resetPreview()}
            .onChange(of:horrorEffects){_ in resetPreview()}
            .onChange(of:mode){_ in compareOriginal=false;region=nil;interpretationFeedback=""}
            .onDisappear{resetInspection()}
    }
}


/// Optional tactile inspection. No photograph needs to be displayed;
/// numeric readings provide the same task under text-only preferences.
struct RegionalLightScanView:View {
    let asset:String
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.veil.security") private var security="Standard"
    @State private var values:[Int]?
    @State private var scanned:Set<Int>=[]
    @State private var dark:Int?
    @State private var bright:Int?
    @State private var scanEpoch:UUID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var pickingDark=true
    @State private var notice=""
    private func clear(){
        values=nil;scanned=[];dark=nil;bright=nil;pickingDark=true;notice="";scanEpoch=nil
    }
    private func sampleLabel(_ index:Int,values:[Int])->String {
        var parts=[ImageInterpretation.regions[index]]
        parts.append(scanned.contains(index) ? "light reading "+String(values[index]) : "not sampled")
        if dark==index {parts.append("marked darkest")}
        if bright==index {parts.append("marked brightest")}
        return parts.joined(separator:", ")
    }
    private func selectSample(_ index:Int) {
        guard phase == .active,scanEpoch==world.checkpointEpoch,
              RecoveredImageAnalysis.completed(asset,in:world.state) else{return}
        if !scanned.insert(index).inserted {
            if pickingDark {dark=index} else {bright=index}
        }
        notice=""
    }
    private func sampleCell(_ index:Int,values:[Int])->some View {
        let markedDark=dark==index
        let markedBright=bright==index
        let tint:Color=(markedDark || markedBright) ? .purple : .secondary
        return Button {selectSample(index)} label:{
            VStack(spacing:4) {
                Text(ImageInterpretation.regions[index]).font(.caption2)
                Text(scanned.contains(index) ? String(values[index]) : "Probe").font(.headline.monospacedDigit())
                if markedDark || markedBright {
                    Text(markedDark && markedBright ? "Both" : markedDark ? "Darkest" : "Brightest").font(.caption2)
                }
            }.frame(maxWidth:.infinity,minHeight:64)
        }.buttonStyle(.bordered).tint(tint)
            .accessibilityLabel(sampleLabel(index,values:values))
    }
    private func sampleGrid(_ values:[Int])->some View {
        let columns=Array(repeating:GridItem(.flexible()),count:dynamicTypeSize.isAccessibilitySize ? 1:3)
        return LazyVGrid(columns:columns,spacing:8) {
            ForEach(0..<9,id:\.self){index in sampleCell(index,values:values)}
        }
    }
    var body:some View {
        if RecoveredImageAnalysis.completed(asset,in:world.state),phase == .active {
            VStack(alignment:.leading,spacing:12) {
                Text("Probe the nine original-image regions, then select the darkest and brightest measured cells. No reconstruction layers are sampled.").font(.subheadline)
                if let note=RecoveredImageAnalysis.lightNote(asset,in:world.state) {
                    Label(note,systemImage:"checkmark.seal").font(.caption).foregroundColor(.teal)
                }
                if let values,values.count == 9,scanEpoch == world.checkpointEpoch {
                    if values.min()==values.max() {
                        Text("This sample is uniform; no contrast pair is available.").font(.caption)
                    } else {
                        Text("Regions sampled: "+String(scanned.count)+" / 9").font(.caption)
                        Picker("Mark",selection:$pickingDark) {
                            Text("Darkest").tag(true)
                            Text("Brightest").tag(false)
                        }.pickerStyle(.segmented)
                        sampleGrid(values)
                        Text("First tap samples a cell. Tap it again to mark it using the selected mode. Readings range from 0 to 255.").font(.caption).foregroundColor(.secondary)
                        Button("Record contrast pair") {
                            guard phase == .active,scanEpoch == world.checkpointEpoch,scanned.count==9,let dark,let bright else{return}
                            notice=world.recordRegionalLightReview(asset,dark:dark,bright:bright) ?
                                "Original contrast observation saved.":"Compare the measured readings and try again."
                        }.buttonStyle(.borderedProminent).disabled(scanEpoch != world.checkpointEpoch || scanned.count != 9 || dark==nil || bright==nil || dark==bright)
                    }
                    Button("Reset scan"){clear()}.font(.caption)
                } else {
                    Button("Start light scan") {
                        guard phase == .active,RecoveredImageAnalysis.completed(asset,in:world.state) else{return}
                        clear()
                        scanEpoch=world.checkpointEpoch
                        values=PortraitImages.load(asset).flatMap{RecoveredImageAnalysis.regionalLight($0)}
                        if values==nil {notice="Original sample unavailable. Other inspection tools remain accessible."}
                    }.buttonStyle(.bordered)
                }
                if !notice.isEmpty {Text(notice).font(.caption)}
            }
            .onChange(of:world.checkpointEpoch){_ in clear()}
            .onChange(of:RecoveredImageAnalysis.completed(asset,in:world.state)){if !$0 {clear()}}
            .onChange(of:security){_ in clear()}
            .onChange(of:phase){if $0 != .active {clear()}}
            .onDisappear{clear()}
        }
    }
}


struct ImageReviewOverviewView:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    var body:some View {
        List {
            if phase == .active {
                let overview=RecoveredImageAnalysis.reviewOverview(world.state)
                Section("Your recorded work") {
                    LabeledContent("Opened images",value:String(overview.opened))
                    LabeledContent("Source reviews",value:String(overview.reviewed))
                    LabeledContent("Regional light scans",value:String(overview.light))
                    LabeledContent("Recurring-detail matches",value:String(overview.matched))
                    LabeledContent("Interpretive observations",value:String(overview.interpretive))
                    Text("Only currently accessible records are counted. Synthetic findings are listed separately from original-image observations.").font(.caption).foregroundColor(.secondary)
                }
                Section("Opened images") {
                    ForEach(RecoveredImageAnalysis.visible(world.state)) { item in
                        NavigationLink { RecoveredImageAnalysisView(asset:item.id) } label:{
                            VStack(alignment:.leading,spacing:5) {
                                Text(item.source == .veil ? (VeilArchive.mediaTitle(item.id,in:world.state) ?? item.title):item.title)
                                Text(RecoveredImageAnalysis.completed(item.id,in:world.state) ? "Source reviewed":"Source review available").font(.caption)
                                if RecoveredImageAnalysis.lightNote(item.id,in:world.state) != nil {
                                    Label("Light scan recorded",systemImage:"checkmark.circle").font(.caption)
                                }
                                if !ImageInterpretation.notes(item.id,in:world.state).isEmpty {
                                    Label("Interpretation recorded",systemImage:"checkmark.circle").font(.caption)
                                }
                                if !PhotoFeatureMatch.notes(item.id,in:world.state).isEmpty {
                                    Label("Detail match recorded",systemImage:"checkmark.circle").font(.caption)
                                }
                            }
                        }
                    }
                }
            } else { Text("Investigation unavailable.") }
        }.navigationTitle("Image investigation")
    }
}
