import Foundation
import UIKit

/// Ephemeral local analysis of a bundled original, never a reconstructed layer.
/// Only aggregate brightness and supported scene/object categories are returned.
struct LumaImageAnalysisReport: Equatable {
    let asset:String
    let bins:[Int]
    let labels:[String]?
    var valid:Bool {
        bins.count == 3 && bins.allSatisfy { (0...1024).contains($0) } &&
        bins.reduce(0,+) == 1024 &&
        (labels.map(LocalSceneClassifier.valid) ?? true)
    }
    var description:String {
        guard valid else { return "No reliable local image analysis is available." }
        let names=["dark","midtone","light"]
        let maxCount=bins.max() ?? 0
        let dominant=bins.indices.filter{bins[$0]==maxCount}.map{names[$0]}.joined(separator:" and ")
        let categories:String
        if let labels {
            categories=labels.isEmpty ? "No sufficiently confident supported scene or object category was recognized." :
                "Possible broad categories: "+labels.joined(separator:", ")+". These are estimates."
        } else { categories="The local scene classifier was unavailable." }
        let percentages = zip(names,bins).map { name, count in
            let percent = Int((Double(count) / 1024 * 100).rounded())
            return "\(name) \(percent)%"
        }.joined(separator:", ")
        return "Original preview sample (1,024 pixels): \(percentages). Dominant range: \(dominant). \(categories) No identity, capture date, location or event is established by this scan."
    }
}
enum LumaImageAnalysis {
    static func permitted(_ asset:String,world:PhoneWorld,security:String)->Bool {
        guard let record=RecoveredImageAnalysis.record(asset,in:world) else{return false}
        return record.source != .veil || VeilArchive.allowsImages(security)
    }
    static func verified(_ report:LumaImageAnalysisReport?,recordID:String,world:PhoneWorld,security:String)->LumaImageAnalysisReport? {
        guard let report,report.valid,recordID=="image:"+report.asset,
              permitted(report.asset,world:world,security:security) else{return nil}
        return report
    }
    @MainActor static func scan(_ asset:String,world:PhoneWorld,security:String) async -> LumaImageAnalysisReport? {
        guard permitted(asset,world:world,security:security),
              let original=PortraitImages.load(asset),original.size.width>0,original.size.height>0 else{return nil}
        // Bound decoded analysis input to 512 pixels on its longest side.
        // Use a fresh render of the original, not the interactive preview.
        let ratio=min(1,512/max(original.size.width,original.size.height))
        let size=CGSize(width:max(1,original.size.width*ratio),height:max(1,original.size.height*ratio))
        let format=UIGraphicsImageRendererFormat();format.scale=1;format.opaque=true
        let sample=UIGraphicsImageRenderer(size:size,format:format).image { ctx in
            UIColor.black.setFill();ctx.cgContext.fill(CGRect(origin:.zero,size:size))
            original.draw(in:CGRect(origin:.zero,size:size))
        }
        guard let bins=RecoveredImageAnalysis.brightnessBins(sample),!Task.isCancelled else{return nil}
        var labels:[String]?=nil
        if let data=sample.jpegData(compressionQuality:0.8) {
            labels=await LocalSceneClassifier.classify(data)
        }
        guard !Task.isCancelled else{return nil}
        let result=LumaImageAnalysisReport(asset:asset,bins:bins,labels:labels)
        return result.valid ? result:nil
    }
}
