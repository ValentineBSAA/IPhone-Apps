import XCTest
@testable import LastSeen

final class HomeLayoutTests:XCTestCase {
    func testAllAppsExactlyOnceIncludingInstalledFieldNotes() {
        for width in [320.0,375,390,430] {
            for height in [470.0,560,640,740,820] {
                for five in [false,true] {
                    for installed in [false,true] {
                        let layout=LumaHomeLayout(width:width,height:height,fiveColumns:five,smallIcons:five)
                        let pages=LumaHomeLayout.pages(columns:layout.columns,rows:layout.rows,fieldNotes:installed)
                        XCTAssertGreaterThanOrEqual(pages.count,2)
                        XCTAssertTrue(pages.allSatisfy{!$0.isEmpty && $0.count<=layout.columns*layout.rows})
                        let apps=pages.flatMap{$0}.flatMap{$0.apps}+LumaHomeLayout.dock
                        XCTAssertEqual(Set(apps),Set(LabApp.allCases.filter{($0 != .fieldNotes || installed) && $0 != .relaySupport && $0 != .veil}))
                        XCTAssertEqual(apps.count,Set(apps).count)
                        XCTAssertEqual(Set(LumaHomeLayout.dock),Set(LabApp.allCases.filter(\.inDock)))
                        XCTAssertLessThanOrEqual(layout.iconSize+21,layout.rowHeight)
                    }
                }
            }
        }
    }
    func testPersonalFoldersAndToolPage() {
        let pages=LumaHomeLayout.pages(columns:4,rows:2,fieldNotes:true)
        XCTAssertEqual(pages.count,2)
        XCTAssertTrue(pages[0].contains(.folder(.studio)))
        XCTAssertTrue(pages[0].contains(.folder(.social)))
        XCTAssertTrue(pages[0].contains(.folder(.everyday)))
        XCTAssertFalse(pages[0].flatMap{$0.apps}.contains(.fieldNotes))
        XCTAssertTrue(pages[1].contains(.app(.fieldNotes)))
        XCTAssertTrue(pages[1].contains(.app(.relay)))
    }
}
