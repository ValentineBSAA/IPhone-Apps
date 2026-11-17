import SwiftUI

/// The original hybrid-realism art direction:
/// 01–06 are full-size individual photographs. 07–10 are reference crops
/// and should be replaced by full-resolution renders before public release.
enum StoryPhotoCatalog {
    static let assets = [
        "Story_01_Nora_Hallway",
        "Story_02_Elevator_Reflection",
        "Story_03_Nora_Front_Door",
        "Story_04_Impossible_Hallway",
        "Story_05_Eli_Maintenance",
        "Story_06_Inside_Elevator",
        "Story_07_Building_Records",
        "Story_08_Unknown_Your_Door",
        "Story_09_Stairwell",
        "Story_10_Final_Reveal"
    ]

    static let labels: [String: String] = [
        "Story_01_Nora_Hallway": "Ordinary apartment hallway",
        "Story_02_Elevator_Reflection": "Elevator doors with a shadow in the reflection",
        "Story_03_Nora_Front_Door": "Nora's apartment door",
        "Story_04_Impossible_Hallway": "A hallway that seems longer than before",
        "Story_05_Eli_Maintenance": "Eli's maintenance office",
        "Story_06_Inside_Elevator": "A suspicious elevator control panel",
        "Story_07_Building_Records": "Old construction records",
        "Story_08_Unknown_Your_Door": "An unknown sender's photograph of a door",
        "Story_09_Stairwell": "Shadow on the stairwell",
        "Story_10_Final_Reveal": "The final photograph"
    ]
}

/// Regular UI shows a contact's *actual attachment*, not procedural placeholder art.
/// When the optional art pack has not been bundled, fallback keeps gameplay usable.
struct StoryPhotograph: View {
    let assetName: String?
    var fit: Bool = false

    var body: some View {
        Group {
            if let assetName, let photo = UIImage(named: assetName) {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: fit ? .fit : .fill)
                    .accessibilityLabel(StoryPhotoCatalog.labels[assetName] ?? "Story photograph")
            } else {
                EvidencePhoto()
                    .accessibilityLabel("Photograph placeholder. This build does not include the new art pack.")
            }
        }
        .accessibilityAddTraits(.isImage)
    }
}
