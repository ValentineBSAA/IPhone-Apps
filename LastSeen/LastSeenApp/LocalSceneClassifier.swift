import Foundation
import Vision

/// Broad local image categories only. Never use face recognition, OCR,
/// metadata, location inference, or a network image service.
enum LocalSceneClassifier {
    private static let mapping: [String: String] = [
        "plant":"plant", "flower":"flower", "tree":"tree", "vegetation":"vegetation",
        "dog":"dog", "cat":"cat", "animal":"animal", "bird":"bird",
        "food":"food", "fruit":"fruit", "vegetable":"vegetable",
        "building":"building", "architecture":"architecture", "room":"interior",
        "interior":"interior", "furniture":"furniture", "vehicle":"vehicle", "car":"vehicle",
        "sky":"sky", "water":"water", "landscape":"landscape", "nature":"nature",
        "book":"book", "computer":"computer", "screen":"screen"
    ]
    static func valid(_ labels: [String]) -> Bool {
        labels.count <= 3 && Set(labels).count == labels.count &&
        Set(labels).isSubset(of: Set(mapping.values))
    }
    static func categories(_ observations: [(String, Float)]) -> [String] {
        var labels: [String] = []
        for (identifier, confidence) in observations.sorted(by: { $0.1 > $1.1 }) {
            let key = identifier.lowercased().replacingOccurrences(of: "_", with: " ")
            guard confidence >= 0.65, let label = mapping[key], !labels.contains(label) else { continue }
            labels.append(label)
            if labels.count == 3 { break }
        }
        return labels
    }
    static func classify(_ data: Data) async -> [String]? {
        await Task.detached(priority: .userInitiated) {
            let request = VNClassifyImageRequest()
            do {
                try VNImageRequestHandler(data: data, options: [:]).perform([request])
                let observations = request.results ?? []
                return categories(observations.map { ($0.identifier, $0.confidence) })
            } catch { return nil }
        }.value
    }
}
