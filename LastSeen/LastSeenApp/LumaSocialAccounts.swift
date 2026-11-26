import SwiftUI

struct LumaSocialPreferences: Codable, Equatable {
    var mutedAuthors: Set<String> = []
    var notificationsEnabled = true
    var showPreviews = true
    var followedPostAlerts: Bool? = nil
}

enum LumaSocialCommunity {
    struct Person {
        let name: String
        let handle: String
        let bio: String
        let channel: LumaSocialChannel
        let first: String
        let second: String
    }
    static let people: [Person] = [
        .init(name: "Iris Vale", handle: "iris.vale", bio: "Illustrator • weekend ceramics", channel: .afterframe, first: "Finally glazed the little blue bowl. It only took three attempts and a very patient teacher.", second: "The handle on my latest mug is slightly crooked. It has character, apparently."),
        .init(name: "Miles Chen", handle: "miles.frames", bio: "Hobby photographer • walks and architecture", channel: .afterframe, first: "The light on the brickwork this morning was worth getting up early for.", second: "Left the camera at home today. Sometimes a walk can just be a walk."),
        .init(name: "Sofia Hart", handle: "sofia.hart", bio: "Home cooking and gardening", channel: .afterframe, first: "The basil has survived another week. The kitchen smells wonderful.", second: "Tried making bread again. Much better when I actually read the recipe."),
        .init(name: "Evan Park", handle: "evan.codes", bio: "Independent accessibility consultant", channel: .connective, first: "A usability session is more useful when people can describe what confused them in their own words.", second: "Spent the afternoon reviewing contrast and keyboard navigation. Small details add up."),
        .init(name: "Amara Finch", handle: "amara.finch", bio: "Freelance editor • small business owner", channel: .connective, first: "A project brief should explain who the work is for before listing everything it needs to contain.", second: "My favorite project milestone is a clear, kind handoff."),
        .init(name: "Rowan Bell", handle: "rowan.audio", bio: "Independent sound designer", channel: .connective, first: "Testing sound at a comfortable volume matters. A cue should communicate without overwhelming the listener.", second: "Finished a small collection of original interface sounds this week. Taking tomorrow off."),
        .init(name: "June Ellis", handle: "june.reads", bio: "Reader • community events", channel: .commonGround, first: "Anyone interested in a casual book swap next month? No need to bring anything fancy.", second: "Finished the short story collection from the reading group. Would happily lend it out."),
        .init(name: "Leo Mercer", handle: "leo.mercer", bio: "Cycling • neighborhood gardening", channel: .commonGround, first: "The community planter could use a little attention this weekend. I'll bring spare gloves.", second: "Found a nice quiet route for my evening ride. Glad the weather held."),
        .init(name: "Sam Rivera", handle: "sam.rivera", bio: "Board games • cooking • local events", channel: .commonGround, first: "Thinking of organizing a relaxed board game evening. Beginners absolutely welcome.", second: "Does anyone have a reliable recipe for cinnamon rolls? Mine are more like cinnamon bricks."),
        .init(name: "Devon Price", handle: "devon.trails", bio: "Trail maps, weather and walking", channel: .afterframe, first: "Saving this mountain view for the next rainy afternoon. Anyone else collect pictures of places they'd like to walk?", second: "A short walk counts. Not every weekend needs an expedition."),
        .init(name: "Ellis Morgan", handle: "ellis.mugs", bio: "Coffee enthusiast • amateur cook", channel: .afterframe, first: "An espresso appreciation post. The tiny cup is somehow the best part.", second: "Bought a kitchen scale and immediately discovered how inconsistent my coffee measurements were."),
        .init(name: "Mina Foster", handle: "mina.paws", bio: "Cat person • home projects", channel: .afterframe, first: "This tabby photo is an instant mood improvement. Look at that little expression.", second: "My weekend project is organizing a cupboard that has been fighting back for months."),
        .init(name: "Noah Grant", handle: "noah.access", bio: "Freelance interface designer", channel: .connective, first: "When a prototype fails a usability check, write down the failure before redesigning. Otherwise you can solve the wrong problem.", second: "I keep a reusable checklist for focus order, readable labels and large text."),
        .init(name: "Clara West", handle: "clara.prints", bio: "Independent printmaker • small shop", channel: .connective, first: "The most useful shop update this month was a clearer description of delivery windows. Nothing glamorous, but fewer confused messages.", second: "Finally set aside an afternoon to organize my invoices. Future me deserves the favor."),
        .init(name: "Jasper Lane", handle: "jasper.tools", bio: "Indie software developer", channel: .connective, first: "A tiny tool with one reliable job is often more valuable than a large dashboard nobody understands.", second: "Today's reminder: test an upgrade with an existing save, not just a fresh install."),
        .init(name: "Nina Wells", handle: "nina.wild", bio: "Wildlife photos • quiet walks", channel: .commonGround, first: "Sharing a fox photograph for the wildlife thread. Please give wild animals plenty of distance.", second: "Any recommendations for a beginner-friendly field guide? I keep mixing up the local birds."),
        .init(name: "Owen Reed", handle: "owen.noodles", bio: "Home cooking • recipe swaps", channel: .commonGround, first: "A bowl of udon is a pretty convincing argument for a noodle night. Sharing this as dinner inspiration.", second: "I finally learned to prepare ingredients before turning the stove on. It only took several very chaotic dinners."),
        .init(name: "Avery Quinn", handle: "avery.green", bio: "Plants • books • outdoor photography", channel: .commonGround, first: "Saving this woodland photograph as inspiration for a tiny fern corner at home.", second: "If anyone has tips for keeping a houseplant alive through winter, I'm listening.")
,
        .init(name: "Morgan Hale", handle: "morgan.stitches", bio: "Sewing • repairs • slow weekends", channel: .afterframe, first: "Mended the pocket on my favorite jacket instead of replacing it. Very satisfying.", second: "The fabric shop had an entire shelf of odd buttons. I resisted almost all of them."),
        .init(name: "Riley Shaw", handle: "riley.runs", bio: "Early walks • running journals", channel: .afterframe, first: "Took the shorter route this morning and still felt better for getting outside.", second: "The rain sounded lovely once I was home with dry socks."),
        .init(name: "Taylor Brooks", handle: "taylor.clay", bio: "Pottery • sketchbooks", channel: .afterframe, first: "My clay bowl finally holds water. A tiny but very welcome milestone.", second: "Trying a pale green glaze next. The test tiles are drying on the windowsill."),
        .init(name: "Casey Flynn", handle: "casey.kitchen", bio: "Weekend baker • meal planning", channel: .afterframe, first: "Made enough soup for the next few lunches. Future me is going to be delighted.", second: "I think the secret to my bread is leaving it alone for longer than I want to."),
        .init(name: "Drew Carter", handle: "drew.paper", bio: "Stationery • handwritten letters", channel: .afterframe, first: "Found a notebook with paper that doesn't bleed through. Small victory.", second: "Writing a few thank-you cards tonight before I forget again."),
        .init(name: "Jamie Patel", handle: "jamie.maps", bio: "Transit and urban design", channel: .connective, first: "A useful map answers where to go next before it tries to show everything.", second: "Spent the morning simplifying a set of direction signs. Fewer words helped."),
        .init(name: "Reese Kim", handle: "reese.types", bio: "Editorial design • typography", channel: .connective, first: "A readable type hierarchy is worth more than another decorative element.", second: "Checking the smallest labels in a design before approving the large screens."),
        .init(name: "Cameron Ellis", handle: "cam.records", bio: "Independent records coordinator", channel: .connective, first: "A filing convention only works if the entire team understands it.", second: "Archived the completed folders today. The desk finally feels less crowded."),
        .init(name: "Alexis Stone", handle: "alexis.studio", bio: "Craft teacher • workshop planning", channel: .connective, first: "Leaving a few extra minutes at the end of a class makes cleanup much less stressful.", second: "Rewriting the materials list so beginners don't have to guess what to bring."),
        .init(name: "Blair Sutton", handle: "blair.repair", bio: "Electronics repair • tinkering", channel: .connective, first: "Labeling tiny screws before taking something apart is a very worthwhile habit.", second: "Repaired an old lamp this afternoon. Glad I kept the spare parts."),
        .init(name: "Robin Fletcher", handle: "robin.seedlings", bio: "Retired librarian • community garden", channel: .commonGround, first: "The seedlings are ready to move into larger pots. I've got a few spares if anyone wants one.", second: "Finished sorting a box of donated books. Some lovely forgotten titles in there."),
        .init(name: "Harper Monroe", handle: "harper.knits", bio: "Knitting • family recipes", channel: .commonGround, first: "Finally finished the scarf I started before the weather changed.", second: "Does anyone have a favorite pattern for using up small amounts of leftover yarn?"),
        .init(name: "Parker Doyle", handle: "parker.records", bio: "Record collecting • neighborhood walks", channel: .commonGround, first: "Played an old jazz record while making breakfast. A rather nice start to the day.", second: "Sorting the record sleeves this weekend. Somehow the alphabet always gets away from me."),
        .init(name: "Leslie Ford", handle: "leslie.mends", bio: "Woodworking • community workshops", channel: .commonGround, first: "Sanded down a little wooden shelf that has been waiting in the garage for months.", second: "The workshop has spare sandpaper if anyone is finishing a small project."),
        .init(name: "The Cat Window", handle: "cat.window", bio: "Illustrated cat appreciation account", channel: .afterframe, first: "A reminder to give the cat the sunny chair. Apparently it was never ours.", second: "Today's tiny joy: a cat discovering a perfectly ordinary cardboard box."),
        .init(name: "Good Dog Notes", handle: "gooddog.notes", bio: "Dog walks • pet care reminders", channel: .commonGround, first: "A slow sniff-filled walk is still a good walk.", second: "Remember the water bowl when heading out on a longer afternoon walk."),
        .init(name: "Quiet Summit", handle: "quiet.summit", bio: "Illustrated outdoor inspiration", channel: .afterframe, first: "Collecting mountain pictures for the days when a walk isn't on the cards.", second: "The best outdoor plan is the one you can enjoy safely at your own pace."),
        .init(name: "Little Sprout Club", handle: "little.sprout", bio: "Houseplants • gardening ideas", channel: .commonGround, first: "A small plant swap sounds lovely. Cuttings welcome, fancy pots optional.", second: "Checking the soil before watering has saved more plants than any fancy gadget.")
,
        .init(name: "Copper Kettle Kitchen", handle: "copperkettle.kitchen", bio: "Recipe notes · small-batch baking", channel: .afterframe, first: "Testing an orange loaf today. The whole kitchen smells of citrus.", second: "Tomorrow's bake is a batch of oat biscuits. Keeping the recipe simple this time."),
        .init(name: "Paper Fern Press", handle: "paperfern.press", bio: "Illustrated stationery · printmaking", channel: .afterframe, first: "The fern-pattern cards are finally dry enough to pack.", second: "A few misprinted cards have become bookmarks for the studio."),
        .init(name: "Windowlight Journal", handle: "windowlight.journal", bio: "Everyday photography · quiet interiors", channel: .afterframe, first: "The afternoon light landed on the bookshelf at exactly the right moment.", second: "Looking at shadows rather than colors for today's little composition exercise."),
        .init(name: "Soft Kiln Studio", handle: "softkiln.studio", bio: "Handmade ceramics · studio notes", channel: .afterframe, first: "The first small bowls came out of the kiln this morning.", second: "A second glaze test is cooling. Trying to get a soft, matte finish."),
        .init(name: "Thread & Thimble", handle: "thread.thimble", bio: "Visible mending · sewing ideas", channel: .afterframe, first: "A patched elbow can look intentional with a little contrast stitching.", second: "Sorted the leftover cotton by color. It is much easier to find a small patch now."),
        .init(name: "Pavement Sketches", handle: "pavement.sketches", bio: "Urban sketchbook collective", channel: .afterframe, first: "Today's prompt is a doorway. No need to draw the whole building.", second: "A five-minute sketch is enough when the weather is chilly."),
        .init(name: "Rainroom Records", handle: "rainroom.records", bio: "Record sleeves · music collecting", channel: .afterframe, first: "Reorganized the shelf by mood instead of genre for a change.", second: "Cleaning a few old sleeves this afternoon. Paper takes a little patience."),
        .init(name: "Clover Table", handle: "clover.table", bio: "Seasonal meals · table settings", channel: .afterframe, first: "A simple soup and some crusty bread are plenty for a good lunch.", second: "Tried folding the napkins differently for a quiet dinner at home."),
        .init(name: "Lattice Interface", handle: "lattice.interface", bio: "Independent interface design studio", channel: .connective, first: "Today's review was mostly about spacing and focus order. The mockup looks calmer now.", second: "Leaving written notes beside the prototype helps the next person understand the decisions."),
        .init(name: "Fieldnote Editing", handle: "fieldnote.editing", bio: "Editorial services · documentation", channel: .connective, first: "Removed three redundant sections from a guide. The instructions are easier to follow now.", second: "A glossary is most useful when it explains unfamiliar words without adding more of them."),
        .init(name: "Northpin Audio", handle: "northpin.audio", bio: "Independent audio production", channel: .connective, first: "Finished a small mix review using both headphones and a little speaker.", second: "Saved the original recordings before starting another edit. Always worth doing."),
        .init(name: "Margin Works", handle: "margin.works", bio: "Small print and layout studio", channel: .connective, first: "The latest print proof needed a slightly wider inner margin.", second: "Keeping a sample book of paper weights makes choosing materials much quicker."),
        .init(name: "Juniper Systems", handle: "juniper.systems", bio: "Small software tools · maintenance", channel: .connective, first: "A maintenance update is easier to understand with a short list of what changed.", second: "Wrote a repeatable setup checklist before handing a tiny project over."),
        .init(name: "Clearpath Learning", handle: "clearpath.learning", bio: "Workshop materials · adult learning", channel: .connective, first: "Added a practice example before the first exercise. Beginners should have somewhere to start.", second: "The next worksheet will have more room for handwritten notes."),
        .init(name: "Foldline Fabrication", handle: "foldline.fabrication", bio: "Model making · prototyping", channel: .connective, first: "The cardboard model helped us spot a clearance issue before making the final piece.", second: "Keeping the first rough prototypes is useful for explaining how a design evolved."),
        .init(name: "Quiet Ledger", handle: "quiet.ledger", bio: "Independent bookkeeping and organization", channel: .connective, first: "Reconciled the small expense list before it turned into a large one.", second: "A consistent file name is a surprisingly good time-saving tool."),
        .init(name: "Cedar Swap Circle", handle: "cedar.swap", bio: "Neighborhood plant and seed exchange", channel: .commonGround, first: "A few spare basil seedlings are ready for the next exchange.", second: "Bring a small container if you are taking home a cutting."),
        .init(name: "Sunday Puzzle Table", handle: "sunday.puzzles", bio: "Casual jigsaws · board games", channel: .commonGround, first: "We found all the edge pieces before lunch. Not bad for a slow Sunday.", second: "The next meetup will have a smaller puzzle for anyone who prefers a shorter session."),
        .init(name: "Lantern Reading Room", handle: "lantern.reading", bio: "Community reading group", channel: .commonGround, first: "This month's reading choice is a collection of essays. Read whichever pieces interest you.", second: "No pressure to finish the whole book before the next discussion."),
        .init(name: "Bluebird Repair Circle", handle: "bluebird.repairs", bio: "Mending meetups · sharing skills", channel: .commonGround, first: "A reminder to bring the broken item and any loose pieces to the next session.", second: "We have spare thread and a few basic hand tools for small repairs."),
        .init(name: "Moss & Map Walks", handle: "moss.map", bio: "Gentle walking club · outdoor appreciation", channel: .commonGround, first: "Choosing a shorter route for the next group walk so everyone can take their time.", second: "A warm layer and a water bottle are good things to bring along."),
        .init(name: "Corner Pantry Exchange", handle: "corner.pantry", bio: "Recipe exchange · reducing food waste", channel: .commonGround, first: "A leftover vegetable soup is the recipe suggestion for this week.", second: "We're collecting ideas for using the last few ingredients in a cupboard."),
        .init(name: "Spare Page Society", handle: "spare.page", bio: "Notebook swaps · letter writing", channel: .commonGround, first: "A few unused notebooks are available at the next stationery swap.", second: "Bring an envelope if you want to try the little letter-writing exercise."),
        .init(name: "Little Bench Collective", handle: "littlebench.collective", bio: "Community crafts · beginner projects", channel: .commonGround, first: "The next craft session is a simple wooden coaster. Beginners welcome.", second: "We'll have some spare sanding blocks and offcuts for practice.")
,
        .init(name: "Ada Wren", handle: "ada.wren", bio: "Watercolor sketches", channel: .afterframe, first: "The colors in my sketch looked completely different after the paper dried.", second: "I am leaving tomorrow's page blank until something catches my eye."),
        .init(name: "Ben Okafor", handle: "ben.bakes", bio: "Home baking", channel: .afterframe, first: "The lemon cake actually came out of the tin in one piece.", second: "Next time I will grate the zest before squeezing the lemon."),
        .init(name: "Celia Frost", handle: "celia.frost", bio: "Indoor plants", channel: .afterframe, first: "Moved my little fern away from the radiator and it looks happier.", second: "Found a pot that fits without taking up the entire shelf."),
        .init(name: "Dorian Vale", handle: "dorian.watches", bio: "Watch collecting and repair", channel: .afterframe, first: "Changed the strap on an old watch. It feels like a completely different piece.", second: "The little seconds hand is my favorite part of this dial."),
        .init(name: "Emery Nash", handle: "emery.nash", bio: "Knitting and tea", channel: .afterframe, first: "Unraveled a few rows to fix a mistake and somehow enjoyed the quiet.", second: "The new yarn is much softer than I expected."),
        .init(name: "Freya Quinn", handle: "freya.pages", bio: "Reading and journaling", channel: .afterframe, first: "Finished a chapter before breakfast for once.", second: "My notebook is full of half-remembered lines from books."),
        .init(name: "Gabe Turner", handle: "gabe.frames", bio: "Film photography", channel: .afterframe, first: "Used the last frame on an interesting shadow.", second: "I like waiting until the whole roll is finished before looking at the pictures."),
        .init(name: "Hana Ito", handle: "hana.clay", bio: "Pottery and handmade gifts", channel: .afterframe, first: "Making a small dish for my keys instead of losing them around the apartment.", second: "The glaze test has a tiny speckled edge that I want to keep."),
        .init(name: "Isaac Kim", handle: "isaac.keys", bio: "Mechanical keyboards", channel: .afterframe, first: "Cleaned my keyboard and found enough crumbs to explain a few sticky keys.", second: "Trying quieter switches this week."),
        .init(name: "Jules Avery", handle: "jules.letters", bio: "Letter writing and ink", channel: .afterframe, first: "Picked a dark green ink for a birthday card.", second: "A handwritten address takes me longer than the entire message sometimes."),
        .init(name: "Kira Young", handle: "kira.stargazing", bio: "Night sky and astronomy books", channel: .afterframe, first: "The clouds won this evening, so I read about constellations indoors.", second: "Putting a small red flashlight in my observing bag."),
        .init(name: "Luca Diaz", handle: "luca.lunch", bio: "Simple lunches and walks", channel: .afterframe, first: "Packed rice and vegetables in a little lunch box today.", second: "Took the long way home to enjoy the cooler air."),
        .init(name: "Mara Keene", handle: "mara.keene", bio: "Embroidery and textiles", channel: .afterframe, first: "The tiny stitches are starting to look like leaves.", second: "I have officially lost the needle I was holding five minutes ago."),
        .init(name: "Nico Alvarez", handle: "nico.docs", bio: "Technical documentation", channel: .connective, first: "Added a working example to the shortest guide in the project.", second: "A warning belongs near the step where someone might need it."),
        .init(name: "Opal Dean", handle: "opal.layouts", bio: "Layout and editorial design", channel: .connective, first: "Adjusted the line spacing on the proof after reading it at actual size.", second: "The smallest caption was doing far too much work."),
        .init(name: "Priya Shah", handle: "priya.qa", bio: "Software QA and accessibility", channel: .connective, first: "Reproduced a bug with a restored save that never appeared on a new installation.", second: "Keeping the test notes short enough that someone can repeat them tomorrow."),
        .init(name: "Quinn Ellis", handle: "quinn.audio", bio: "Audio editing and production", channel: .connective, first: "Recorded a short room tone sample before packing the microphone.", second: "A quiet pause can make the next line much easier to hear."),
        .init(name: "Rosa Vega", handle: "rosa.catalogs", bio: "Library collections", channel: .connective, first: "Reviewed the labels on the returns shelf and found two confusing categories.", second: "The catalog is much more useful when common search terms actually work."),
        .init(name: "Theo Nance", handle: "theo.prototypes", bio: "Prototyping and model making", channel: .connective, first: "Made a paper model to see where the tabs should fold.", second: "The first draft was more useful than I expected."),
        .init(name: "Uma Cole", handle: "uma.workshops", bio: "Creative workshop facilitation", channel: .connective, first: "Moved the practice exercise before the explanation in my lesson plan.", second: "Everyone deserves enough time to ask a question."),
        .init(name: "Victor Imani", handle: "victor.files", bio: "Information organization", channel: .connective, first: "Found three versions of a file with almost identical names.", second: "Wrote down the naming convention beside the shared folder."),
        .init(name: "Willa Grey", handle: "willa.motion", bio: "Motion graphics", channel: .connective, first: "A slightly slower transition made the title easier to read.", second: "Testing the animation at a smaller screen size before exporting."),
        .init(name: "Xander Hill", handle: "xander.parts", bio: "Electronics technician", channel: .connective, first: "Sorted the small connectors into labeled drawers.", second: "A good light and a clean work surface make a repair much less frustrating."),
        .init(name: "Yara Moss", handle: "yara.research", bio: "Independent user researcher", channel: .connective, first: "Today I listened to someone describe a task without interrupting.", second: "A useful interview question leaves room for an unexpected answer."),
        .init(name: "Zane Perry", handle: "zane.notes", bio: "Project coordination", channel: .connective, first: "Closed the week by writing down what still needs an owner.", second: "A five-minute handoff is better than leaving everyone to guess."),
        .init(name: "Anika Bell", handle: "anika.prints", bio: "Print production", channel: .connective, first: "Compared the proof under two different lights.", second: "Keeping the final sample with the job notes for the next run."),
        .init(name: "Basil Reed", handle: "basil.chess", bio: "Casual chess and puzzles", channel: .commonGround, first: "Anyone up for a friendly game this weekend? No clocks needed.", second: "Found an old puzzle book with some lovely little positions."),
        .init(name: "Cora Finch", handle: "cora.herbs", bio: "Herbs and seed swaps", channel: .commonGround, first: "I have extra mint cuttings if anyone wants one.", second: "Putting plant labels in the pots before I forget what I planted."),
        .init(name: "Dexter Lin", handle: "dexter.desk", bio: "Desk organization and small crafts", channel: .commonGround, first: "Made a small tray from leftover cardboard.", second: "Does anyone else keep a box of useful scraps?"),
        .init(name: "Esme Holt", handle: "esme.cooks", bio: "Recipe swaps", channel: .commonGround, first: "Trying a simple lentil soup tonight.", second: "If you have leftover carrots, they work nicely in a soup."),
        .init(name: "Felix Upton", handle: "felix.walks", bio: "Walking and birdwatching", channel: .commonGround, first: "Heard a bird I couldn't identify during my walk.", second: "Bringing a small field guide next time."),
        .init(name: "Greta Low", handle: "greta.games", bio: "Board game evenings", channel: .commonGround, first: "Found a cooperative game that's easy to explain to new players.", second: "We could start with a short round before the longer games."),
        .init(name: "Hugo Mendez", handle: "hugo.tools", bio: "Home projects and tool swaps", channel: .commonGround, first: "Finally fixed the squeaky drawer.", second: "I have a spare measuring tape for the next repair meetup."),
        .init(name: "Inez Patel", handle: "inez.paper", bio: "Book swaps and stationery", channel: .commonGround, first: "Two books are ready for the swap pile.", second: "Anyone interested in a little notebook exchange?"),
        .init(name: "Jonah Fox", handle: "jonah.music", bio: "Music collecting", channel: .commonGround, first: "Rediscovered an album I haven't played for years.", second: "Making a playlist for a quiet afternoon of sorting records."),
        .init(name: "Keiko Mills", handle: "keiko.garden", bio: "Gardening and compost", channel: .commonGround, first: "The little planter is finally ready for some seedlings.", second: "I am trying smaller amounts of compost this season."),
        .init(name: "Leah Novak", handle: "leah.crafts", bio: "Community craft sessions", channel: .commonGround, first: "Cut enough paper for the next craft meetup.", second: "Beginners are welcome to bring any materials they already have."),
        .init(name: "Milo Santos", handle: "milo.paws", bio: "Pet care and everyday routines", channel: .commonGround, first: "The dog has decided that the hallway is the best place for a nap.", second: "Washed the water bowl and put a spare one by the door."),
        .init(name: "Nell Rhodes", handle: "nell.reads", bio: "Short stories and community reading", channel: .commonGround, first: "Read a lovely short story over a cup of tea.", second: "Does anyone have a favorite collection to recommend?"),
        .init(name: "Orin Beck", handle: "orin.bench", bio: "Small woodworking projects", channel: .commonGround, first: "A little shelf is ready for the final coat.", second: "Keeping the offcuts for a few practice joints.")
    ]
    static let portraits: [String: String] = [
        "iris.vale": "CommunityPortrait_11",
        "miles.frames": "CommunityPortrait_17",
        "sofia.hart": "CommunityPortrait_13",
        "evan.codes": "CommunityPortrait_02",
        "amara.finch": "CommunityPortrait_09",
        "rowan.audio": "CommunityPortrait_08",
        "june.reads": "CommunityPortrait_04",
        "leo.mercer": "CommunityPortrait_07",
        "sam.rivera": "CommunityPortrait_15",
        "devon.trails": "CommunityPortrait_01",
        "ellis.mugs": "CommunityPortrait_03",
        "mina.paws": "CommunityPortrait_10",
        "noah.access": "CommunityPortrait_06",
        "clara.prints": "CommunityPortrait_12",
        "jasper.tools": "CommunityPortrait_05",
        "nina.wild": "CommunityPortrait_16",
        "owen.noodles": "CommunityPortrait_14",
        "avery.green": "CommunityPortrait_18",
        "morgan.stitches": "CommunityReserve_01",
        "riley.runs": "CommunityReserve_02",
        "taylor.clay": "CommunityReserve_03",
        "casey.kitchen": "CommunityReserve_04",
        "drew.paper": "CommunityReserve_05",
        "jamie.maps": "CommunityReserve_06",
        "reese.types": "CommunityReserve_07",
        "cam.records": "CommunityReserve_08",
        "alexis.studio": "CommunityReserve_09",
        "blair.repair": "CommunityReserve_10",
        "robin.seedlings": "CommunityOlder_1",
        "harper.knits": "CommunityOlder_2",
        "parker.records": "CommunityOlder_3",
        "leslie.mends": "CommunityOlder_4",
        "cat.window": "CommunityAvatar_Cat",
        "gooddog.notes": "CommunityAvatar_Dog",
        "quiet.summit": "CommunityAvatar_Mountain",
        "little.sprout": "CommunityAvatar_Gardening"
    ]
    // Original in-game marks for fictional groups, shops and studios.
    // No external brand marks or unreviewed image files are used.
    struct IdentityMark {
        let initials: String
        let symbol: String
        let palette: MarkPalette
    }
    enum MarkPalette {
        case terracotta, forest, gold, clay, plum, slate, indigo, olive, blue
        var colors: [Color] {
            switch self {
            case .terracotta: return [Color(red: 0.64, green: 0.27, blue: 0.19), Color(red: 0.29, green: 0.12, blue: 0.10)]
            case .forest: return [Color(red: 0.20, green: 0.42, blue: 0.31), Color(red: 0.08, green: 0.23, blue: 0.18)]
            case .gold: return [Color(red: 0.57, green: 0.40, blue: 0.15), Color(red: 0.28, green: 0.19, blue: 0.08)]
            case .clay: return [Color(red: 0.61, green: 0.40, blue: 0.32), Color(red: 0.31, green: 0.17, blue: 0.16)]
            case .plum: return [Color(red: 0.49, green: 0.29, blue: 0.48), Color(red: 0.22, green: 0.12, blue: 0.25)]
            case .slate: return [Color(red: 0.34, green: 0.43, blue: 0.50), Color(red: 0.15, green: 0.20, blue: 0.26)]
            case .indigo: return [Color(red: 0.35, green: 0.34, blue: 0.63), Color(red: 0.17, green: 0.14, blue: 0.35)]
            case .olive: return [Color(red: 0.38, green: 0.45, blue: 0.20), Color(red: 0.17, green: 0.24, blue: 0.12)]
            case .blue: return [Color(red: 0.20, green: 0.40, blue: 0.60), Color(red: 0.10, green: 0.19, blue: 0.33)]
            }
        }
    }
    static let identityMarks: [String: IdentityMark] = [
        "copperkettle.kitchen": .init(initials: "CK", symbol: "cup.and.saucer.fill", palette: .terracotta),
        "paperfern.press": .init(initials: "PF", symbol: "leaf.fill", palette: .forest),
        "windowlight.journal": .init(initials: "WJ", symbol: "sun.max.fill", palette: .gold),
        "softkiln.studio": .init(initials: "SK", symbol: "circle.hexagongrid.fill", palette: .clay),
        "thread.thimble": .init(initials: "TT", symbol: "scissors", palette: .plum),
        "pavement.sketches": .init(initials: "PS", symbol: "pencil.tip", palette: .slate),
        "rainroom.records": .init(initials: "RR", symbol: "record.circle", palette: .indigo),
        "clover.table": .init(initials: "CT", symbol: "fork.knife", palette: .olive),
        "lattice.interface": .init(initials: "LI", symbol: "square.grid.2x2", palette: .indigo),
        "fieldnote.editing": .init(initials: "FE", symbol: "doc.text", palette: .forest),
        "northpin.audio": .init(initials: "NA", symbol: "waveform", palette: .slate),
        "margin.works": .init(initials: "MW", symbol: "text.alignleft", palette: .clay),
        "juniper.systems": .init(initials: "JS", symbol: "terminal", palette: .forest),
        "clearpath.learning": .init(initials: "CL", symbol: "book.closed", palette: .blue),
        "foldline.fabrication": .init(initials: "FF", symbol: "cube", palette: .gold),
        "quiet.ledger": .init(initials: "QL", symbol: "list.bullet.rectangle", palette: .plum),
        "cedar.swap": .init(initials: "CS", symbol: "leaf", palette: .olive),
        "sunday.puzzles": .init(initials: "SP", symbol: "puzzlepiece.extension", palette: .blue),
        "lantern.reading": .init(initials: "LR", symbol: "book.fill", palette: .gold),
        "bluebird.repairs": .init(initials: "BR", symbol: "wrench.and.screwdriver", palette: .blue),
        "moss.map": .init(initials: "MM", symbol: "map.fill", palette: .forest),
        "corner.pantry": .init(initials: "CP", symbol: "basket.fill", palette: .terracotta),
        "spare.page": .init(initials: "SS", symbol: "envelope.fill", palette: .plum),
        "littlebench.collective": .init(initials: "LB", symbol: "hammer.fill", palette: .slate)
,
        "ada.wren": .init(initials: "AW", symbol: "paintbrush", palette: .forest),
        "ben.bakes": .init(initials: "BO", symbol: "birthday.cake", palette: .gold),
        "celia.frost": .init(initials: "CF", symbol: "leaf", palette: .olive),
        "dorian.watches": .init(initials: "DV", symbol: "clock", palette: .slate),
        "emery.nash": .init(initials: "EN", symbol: "cup.and.saucer", palette: .plum),
        "freya.pages": .init(initials: "FQ", symbol: "book", palette: .blue),
        "gabe.frames": .init(initials: "GT", symbol: "camera", palette: .indigo),
        "hana.clay": .init(initials: "HI", symbol: "circle.hexagongrid", palette: .clay),
        "isaac.keys": .init(initials: "IK", symbol: "keyboard", palette: .slate),
        "jules.letters": .init(initials: "JA", symbol: "envelope", palette: .terracotta),
        "kira.stargazing": .init(initials: "KY", symbol: "moon.stars", palette: .indigo),
        "luca.lunch": .init(initials: "LD", symbol: "fork.knife", palette: .gold),
        "mara.keene": .init(initials: "MK", symbol: "scissors", palette: .plum),
        "nico.docs": .init(initials: "NZ", symbol: "doc.text", palette: .blue),
        "opal.layouts": .init(initials: "OD", symbol: "text.alignleft", palette: .clay),
        "priya.qa": .init(initials: "PZ", symbol: "checkmark.seal", palette: .forest),
        "quinn.audio": .init(initials: "QE", symbol: "waveform", palette: .indigo),
        "rosa.catalogs": .init(initials: "RV", symbol: "books.vertical", palette: .gold),
        "theo.prototypes": .init(initials: "TN", symbol: "cube", palette: .slate),
        "uma.workshops": .init(initials: "UC", symbol: "person.2", palette: .olive),
        "victor.files": .init(initials: "VI", symbol: "folder", palette: .blue),
        "willa.motion": .init(initials: "WG", symbol: "film", palette: .plum),
        "xander.parts": .init(initials: "XH", symbol: "wrench", palette: .slate),
        "yara.research": .init(initials: "YM", symbol: "magnifyingglass", palette: .forest),
        "zane.notes": .init(initials: "ZP", symbol: "calendar", palette: .gold),
        "anika.prints": .init(initials: "AB", symbol: "printer", palette: .terracotta),
        "basil.chess": .init(initials: "BZ", symbol: "square.grid.3x3", palette: .indigo),
        "cora.herbs": .init(initials: "CZ", symbol: "leaf", palette: .olive),
        "dexter.desk": .init(initials: "DL", symbol: "tray", palette: .slate),
        "esme.cooks": .init(initials: "EH", symbol: "fork.knife", palette: .terracotta),
        "felix.walks": .init(initials: "FU", symbol: "binoculars", palette: .forest),
        "greta.games": .init(initials: "GL", symbol: "dice", palette: .plum),
        "hugo.tools": .init(initials: "HM", symbol: "hammer", palette: .gold),
        "inez.paper": .init(initials: "IP", symbol: "book", palette: .blue),
        "jonah.music": .init(initials: "JF", symbol: "music.note", palette: .indigo),
        "keiko.garden": .init(initials: "KM", symbol: "sun.max", palette: .olive),
        "leah.crafts": .init(initials: "LN", symbol: "pencil.tip", palette: .clay),
        "milo.paws": .init(initials: "MS", symbol: "pawprint", palette: .blue),
        "nell.reads": .init(initials: "NR", symbol: "book.closed", palette: .plum),
        "orin.bench": .init(initials: "OB", symbol: "hammer.fill", palette: .slate)
    ]
    static func identityMark(for post: LumaSocialPost) -> IdentityMark? {
        guard people.contains(where: { $0.name == post.author && $0.handle == post.handle && $0.channel == post.channel }) else { return nil }
        return identityMarks[post.handle]
    }
    // Exact authored record-to-media map. Never resolve arbitrary photo names
    // through the community catalog, or treat these as Nora's photographs.
    static let photoAssignments: [String: String] = [
        "b32-community-devon.trails-0": "CommunityMedia_Mountains",
        "b32-community-ellis.mugs-0": "CommunityMedia_Coffee",
        "b32-community-mina.paws-0": "CommunityMedia_Tabby",
        "b32-community-nina.wild-0": "CommunityMedia_Fox",
        "b32-community-owen.noodles-0": "CommunityMedia_Udon",
        "b32-community-avery.green-0": "CommunityMedia_Forest"
    ]
    static func posts(anchor: Date) -> [LumaSocialPost] {
        people.enumerated().flatMap { index, person in
            [person.first, person.second].enumerated().map { number, body in
                let id = "b32-community-" + person.handle + "-" + String(number)
                return LumaSocialPost(id: id, channel: person.channel, author: person.name, handle: person.handle, body: body, date: anchor.addingTimeInterval(-Double(3 + index + number * 11) * 86400 - 7200), portrait: portraits[person.handle], photo: photoAssignments[id], gate: nil)
            }
        }
    }
    static func publicPhoto(_ post: LumaSocialPost) -> String? {
        guard let asset = photoAssignments[post.id], asset == post.photo,
              people.contains(where: { $0.name == post.author && $0.handle == post.handle && $0.channel == post.channel }) else { return nil }
        return asset
    }
    static func bio(author: String, channel: LumaSocialChannel) -> String? {
        if let person = people.first(where: { $0.name == author && $0.channel == channel }) { return person.bio }
        switch author {
        case "Nora Bennett":
            switch channel {
            case .afterframe: return "Little moments, late nights, music and coffee."
            case .connective: return "Founder and lead developer · Blue Hour Interactive"
            case .commonGround: return "Local reader, game developer and coffee enthusiast."
            }
        case "Blue Hour Interactive": return "Independent mobile games and apps · Studio updates"
        case "Maya Brooks": return "Books, coffee and time with friends."
        case "Lily Bennett": return "Art, playlists and small everyday adventures."
        case "Adrian Cole": return "Technical lead · Blue Hour Interactive"
        case "Tessa Reed": return "Artist and producer · Blue Hour Interactive"
        default: return nil
        }
    }
}

struct LumaSocialAccountView: View {
    let channel: LumaSocialChannel
    @EnvironmentObject private var world: PhoneWorldStore
    private var prefs: LumaSocialPreferences { world.socialPreferences(channel) }
    var body: some View {
        List {
            Section("Restored account") {
                NavigationLink { LumaSocialProfile(channel: channel, author: "Nora Bennett") } label: {
                    HStack {
                        Image("Nora_Profile").resizable().scaledToFill().frame(width: 48, height: 48).clipShape(Circle())
                        VStack(alignment: .leading) { Text("Nora Bennett").font(.headline); Text("@nora.b").font(.caption).foregroundColor(.secondary) }
                    }
                }
                if channel == .connective {
                    NavigationLink("Blue Hour Interactive · Company page") { LumaSocialProfile(channel: channel, author: "Blue Hour Interactive") }
                }
                LabeledContent("Account", value: "Signed in")
                Text("New posts and comments use this restored account. Original posts remain unchanged.").font(.caption).foregroundColor(.secondary)
            }
            Section("Local viewing preferences") {
                Toggle("App notifications", isOn: Binding(get: { prefs.notificationsEnabled }, set: { value in var next = prefs; next.notificationsEnabled = value; world.setSocialPreferences(next, channel: channel) }))
                Toggle("Notification previews", isOn: Binding(get: { prefs.showPreviews }, set: { value in var next = prefs; next.showPreviews = value; world.setSocialPreferences(next, channel: channel) }))
                Toggle("New posts from followed profiles", isOn: Binding(get: { prefs.followedPostAlerts ?? true }, set: { value in var next = prefs; next.followedPostAlerts = value; world.setSocialPreferences(next, channel: channel) }))
                Text("These preferences apply to new local community replies and authored posts. Restored posts remain available.").font(.caption).foregroundColor(.secondary)
            }
            Section("Muted profiles") {
                if prefs.mutedAuthors.isEmpty { Text("No muted profiles").foregroundColor(.secondary) }
                ForEach(prefs.mutedAuthors.sorted(), id: \.self) { author in
                    Button("Unmute " + author) { world.toggleSocialMute(author, channel: channel) }
                }
            }
            Section("Discover people") {
                NavigationLink("Browse all profiles") { LumaSocialDirectory(channel: channel) }
                NavigationLink("Following") { LumaSocialDirectory(channel: channel, followingOnly: true) }
            }
            Section("Your local activity") {
                LabeledContent("Saved posts", value: String(LumaSocialCatalog.visible(channel, world: world.state).filter { world.connected.savedPosts.contains($0.id) }.count))
                LabeledContent("Following", value: String(world.connected.follows.filter { $0.hasPrefix(channel.rawValue + "|") }.count))
            }
        }.navigationTitle("Account & settings")
    }
}

/// Browsable account directory derived from the actually accessible feed.
struct LumaSocialDirectory: View {
    let channel: LumaSocialChannel
    var followingOnly = false
    @EnvironmentObject private var world: PhoneWorldStore
    @State private var query = ""
    private var accounts: [LumaSocialPost] {
        let posts = LumaSocialCatalog.visible(channel, world: world.state)
        var seen = Set<String>()
        return posts.filter { post in
            guard seen.insert(post.author).inserted else { return false }
            let following = world.connected.follows.contains(channel.rawValue + "|" + post.author)
            return (!followingOnly || following) && (query.isEmpty || [post.author, post.handle, LumaSocialCommunity.bio(author: post.author, channel: channel) ?? ""].contains { $0.localizedCaseInsensitiveContains(query) })
        }.sorted { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
    }
    var body: some View {
        List {
            if accounts.isEmpty { Text(followingOnly ? "No followed accounts found." : "No matching profiles.").foregroundColor(.secondary) }
            ForEach(accounts) { post in
                NavigationLink { LumaSocialProfile(channel: channel, author: post.author) } label: {
                    HStack(spacing: 12) {
                        LumaSocialAvatar(post: post, size: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(post.author).font(.headline)
                            Text("@" + post.handle).font(.caption).foregroundColor(.secondary)
                            if let bio = LumaSocialCommunity.bio(author: post.author, channel: channel) {
                                Text(bio).font(.caption2).foregroundColor(.secondary).lineLimit(2)
                            }
                        }
                    }.padding(.vertical, 4)
                }
            }
        }.navigationTitle(followingOnly ? "Following" : "Discover people")
            .searchable(text: $query, prompt: "Names, interests or usernames")
    }
}

/// Original typographic fallback for fictional business/organization accounts.
/// Not an imported real corporate logo.
struct LumaSocialAvatar: View {
    let post: LumaSocialPost
    let size: CGFloat
    private var mark: String? {
        switch post.handle {
        case "bluehour": return "BH"
        case "maplebooks": return "MB"
        case "maplecafe": return "MC"
        case "ashstreet": return "AS"
        default: return nil
        }
    }
    var body: some View {
        Group {
            if let portrait = post.portrait {
                Image(portrait).resizable().scaledToFill()
            } else if let identity = LumaSocialCommunity.identityMark(for: post) {
                ZStack {
                    LinearGradient(colors: identity.palette.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Circle().strokeBorder(.white.opacity(0.25), lineWidth: max(1, size * 0.025)).padding(size * 0.08)
                    VStack(spacing: size * 0.035) {
                        Image(systemName: identity.symbol).font(.system(size: size * 0.29, weight: .semibold))
                        Text(identity.initials).font(.system(size: size * 0.21, weight: .bold, design: .rounded))
                    }.foregroundColor(.white)
                }
            } else if let mark {
                ZStack {
                    LinearGradient(colors: [post.channel.accent.opacity(0.85), .black.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(mark).font(.system(size: size * 0.32, weight: .bold, design: .rounded)).foregroundColor(.white)
                }
            } else {
                ZStack {
                    Circle().fill(post.channel.accent.opacity(0.18))
                    Image(systemName: "person.crop.circle.fill").font(.system(size: size * 0.84)).foregroundColor(post.channel.accent)
                }
            }
        }.frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}
