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
         "The berry village gate looks lovely again!"),
        ("Reopen the Berry Market",
         "The baskets are empty. Earn points so we can reopen the market!",
         "The market shelves are filling with berries!",
         "The Berry Boutique is ready for visitors!"),
        ("Prepare the Harvest Festival",
         "The festival banners are ready, but the lantern orchard is still dark. Help us prepare the first celebration!",
         "Every cleared line brings a little more color back to the square.",
         "The first festival has begun! But the orchard lanterns are still waiting to shine."),
        ("Light the Lantern Orchard",
         "The festival ended too early when the orchard lights went out. Follow the glowing fireflies and gather enough light to relight them.",
         "I can see sparks between the branches. Our orchard is waking up!",
         "The lanterns glow again! A hidden trail now leads toward the creek."),
        ("The Whispering Creek",
         "The creek has fallen quiet. Fallen branches are holding back the water that feeds our fields. Clear a path for the stream.",
         "Listen! That's the sound of water finding its way home.",
         "The creek is flowing! The village gardens have fresh water again."),
        ("The Missing Jam Baskets",
         "The jam maker's delivery never reached the market. The creek carried the baskets into the reeds. Let's gather them before sunset.",
         "One basket, two baskets... almost all of them are back!",
         "The jam baskets are safe, and the bakery can reopen its morning ovens."),
        ("The Sudden Garden Storm",
         "A windstorm has scattered leaves and seeds across the cottage paths. We can rebuild without losing what we've grown.",
         "Keep planting. Each clear makes the village a little safer.",
         "The storm has passed! Our neighbors can walk the paths again."),
        ("The Starlight Greenhouse",
         "Beyond the restored path stands an old glasshouse. Its rare night-blooming flowers need careful tending before dawn.",
         "There's a little glow beneath the glass. Our final seedlings are growing.",
         "The glasshouse blooms under the stars. We have everything for a new festival."),
        ("The Village in Full Bloom",
         "The market, creek, orchard, and greenhouse are ready. Bring everyone's harvest together for a true village celebration.",
         "The whole village is helping now. Look how far our garden has come!",
         "We did it! Our village is alive with berries, lanterns, and laughter. A new gardening season awaits!")
    ]

    private static func entry(for chapter: Int) -> (title: String, opening: String, encouragement: String, victory: String) {
        chapters[(max(1, chapter) - 1) % chapters.count]
    }
    static func title(for chapter: Int) -> String { entry(for: chapter).title }
    static func opening(for chapter: Int) -> String { entry(for: chapter).opening }
    static func encouragement(for chapter: Int) -> String { entry(for: chapter).encouragement }
    static func victory(for chapter: Int) -> String { entry(for: chapter).victory }
}
