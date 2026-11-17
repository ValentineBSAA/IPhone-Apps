import Foundation

/// Short, original, silent Story-mode dialogue that never interrupts play.
/// Characters and themes belong to Berry Block Blast, not another franchise.
enum BerryStoryNarrative {
    private static let chapters: [(title: String, opening: String, encouragement: String, victory: String)] = [
        ("Gather the Lost Seeds",
         "The village needs new seedlings! Fill the garden with your first sweet harvest.",
         "Those seeds are sprouting! Keep going, garden friend.",
         "We found the seeds! The village can begin to bloom."),
        ("Restore the Flower Beds",
         "Our flowers need room to grow. Clear three whole rows or columns!",
         "The garden looks brighter already. Just a little more!",
         "The flower beds are back! Thank you for helping."),
        ("Open the Garden Path",
         "Our garden path is blocked. Earn enough points to help me clear the way!",
         "We can almost reach the cottage. You're doing wonderfully!",
         "The path is clear! Let's explore together."),
        ("Repair the Berry Gate",
         "The little village gate needs fixing. Clear the required lines for us!",
         "We're nearly finished with the gate. Keep it up!",
         "The gate looks lovely again!"),
        ("Reopen the Berry Market",
         "The baskets are empty. Earn points so we can reopen the market!",
         "The market shelves are filling with berries!",
         "The Berry Boutique is ready for visitors!"),
        ("Prepare the Harvest Festival",
         "Our festival needs a beautiful garden. Let's complete the next challenge!",
         "Everyone in the village is cheering you on!",
         "The festival is here! Our strawberry village shines!")
    ]

    private static func entry(for chapter: Int) -> (title: String, opening: String, encouragement: String, victory: String) {
        chapters[(max(1, chapter) - 1) % chapters.count]
    }
    static func title(for chapter: Int) -> String { entry(for: chapter).title }
    static func opening(for chapter: Int) -> String { entry(for: chapter).opening }
    static func encouragement(for chapter: Int) -> String { entry(for: chapter).encouragement }
    static func victory(for chapter: Int) -> String { entry(for: chapter).victory }
}
