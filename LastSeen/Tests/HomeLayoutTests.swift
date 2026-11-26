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
                        XCTAssertEqual(Set(apps),Set(LabApp.allCases.filter{($0 != .fieldNotes || installed) && $0 != .relaySupport && $0 != .veil && $0 != .motionwell}))
                        XCTAssertEqual(apps.count,Set(apps).count)
                        XCTAssertEqual(Set(LumaHomeLayout.dock),Set(LabApp.allCases.filter(\.inDock)))
                        XCTAssertLessThanOrEqual(layout.iconSize+21,layout.rowHeight)
                    }
                }
            }
        }
    }
    func testCompactAndAccessibleLayoutKeepsControlsReachable() {
        for width in [320.0,390,844] {
            for height in [220.0,300,390,470,740] {
                for accessible in [false,true] {
                    let layout=LumaHomeLayout(width:width,height:height,fiveColumns:true,smallIcons:false,accessibleLayout:accessible)
                    XCTAssertGreaterThanOrEqual(layout.gridHeight,79)
                    XCTAssertGreaterThanOrEqual(layout.rowHeight,79)
                    XCTAssertLessThanOrEqual(layout.iconSize+21,layout.rowHeight)
                    XCTAssertEqual(layout.needsScroll,layout.contentHeight>height+0.5)
                    if height<=300 {XCTAssertTrue(layout.needsScroll)}
                    if accessible {XCTAssertEqual(layout.columns,4);XCTAssertFalse(layout.showWidgets)}
                    let apps=LumaHomeLayout.pages(columns:layout.columns,rows:layout.rows,fieldNotes:true,support:true,veil:true).flatMap{$0}.flatMap{$0.apps}+LumaHomeLayout.dock
                    XCTAssertEqual(Set(apps),Set(LabApp.allCases.filter{$0 != .motionwell}))
                    XCTAssertEqual(apps.count,Set(apps).count)
                }
            }
        }
    }
    func testImageViewportClampsToFittedPixels() {
        let viewport=CGSize(width:300,height:300)
        let image=CGSize(width:600,height:300)
        XCTAssertEqual(LumaImageViewportGeometry.fitted(image,in:viewport),CGSize(width:300,height:150))
        let proposed=CGSize(width:1000,height:-1000)
        XCTAssertEqual(LumaImageViewportGeometry.clamp(proposed,image:image,viewport:viewport,scale:1),.zero)
        XCTAssertEqual(LumaImageViewportGeometry.clamp(proposed,image:image,viewport:viewport,scale:2),CGSize(width:150,height:0))
        XCTAssertEqual(LumaImageViewportGeometry.clamp(proposed,image:image,viewport:viewport,scale:3),CGSize(width:300,height:-75))
    }
    func testExpandedLayoutGeometryMatrix() {
        for width:CGFloat in [320,390,430,844] {
            for height:CGFloat in [220,300,390,470,540,600,740,844] {
                for five in [false,true] {
                    for small in [false,true] {
                        for accessible in [false,true] {
                            let layout=LumaHomeLayout(width:width,height:height,fiveColumns:five,smallIcons:small,accessibleLayout:accessible)
                            XCTAssertTrue((1...3).contains(layout.rows))
                            XCTAssertEqual(layout.columns,accessible ? 4 : (five ? 5:4))
                            XCTAssertGreaterThanOrEqual(layout.rowHeight,(accessible ? 96:79)-0.0001)
                            XCTAssertTrue((22...61).contains(layout.iconSize))
                            XCTAssertEqual(layout.needsScroll,layout.contentHeight>height+0.5)
                            if accessible {XCTAssertFalse(layout.showWidgets)}
                        }
                    }
                }
            }
        }
    }
    func testViewportGeometryMatrix() {
        for image in [CGSize(width:600,height:300),CGSize(width:300,height:600),CGSize(width:300,height:300),CGSize(width:1,height:1000)] {
            for viewport in [CGSize(width:300,height:300),CGSize(width:320,height:180),CGSize(width:180,height:320)] {
                for scale:CGFloat in [1,1.5,2,3] {
                    let fit=LumaImageViewportGeometry.fitted(image,in:viewport)
                    XCTAssertLessThanOrEqual(fit.width,viewport.width+0.0001)
                    XCTAssertLessThanOrEqual(fit.height,viewport.height+0.0001)
                    for offset in [CGSize(width:1000,height:-1000),CGSize(width:-1000,height:1000),.zero] {
                        let result=LumaImageViewportGeometry.clamp(offset,image:image,viewport:viewport,scale:scale)
                        XCTAssertLessThanOrEqual(abs(result.width),max(0,(fit.width*scale-viewport.width)/2)+0.0001)
                        XCTAssertLessThanOrEqual(abs(result.height),max(0,(fit.height*scale-viewport.height)/2)+0.0001)
                        if scale==1 {XCTAssertEqual(result.width,0,accuracy:0.0001);XCTAssertEqual(result.height,0,accuracy:0.0001)}
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
