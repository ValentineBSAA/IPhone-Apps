import SwiftUI

/// Authored home arrangement, not a new evidence catalog. Folder membership
/// never grants access to protected content or unearned utilities.
enum LumaHomeFolder:String,CaseIterable,Identifiable {
    case social="Friends & feeds", studio="Blue Hour", everyday="Little things"
    var id:String {
        switch self {case .social:return "social";case .studio:return "studio";case .everyday:return "everyday"}
    }
    var apps:[LabApp] {
        switch self {case .social:return [.afterframe,.commonGround];case .studio:return [.files,.connective];case .everyday:return [.clock,.calculator,.havenWatch]}
    }
    var subtitle:String {
        switch self {case .social:return "Personal life";case .studio:return "Work and studio";case .everyday:return "Everyday essentials"}
    }
    var tint:Color {
        switch self {case .social:return Color(red:0.73,green:0.52,blue:0.74);case .studio:return .indigo;case .everyday:return Color(red:0.79,green:0.59,blue:0.39)}
    }
}
enum LumaHomeEntry:Equatable {
    case app(LabApp),folder(LumaHomeFolder)
    var apps:[LabApp] {
        switch self {case .app(let app):return [app];case .folder(let folder):return folder.apps}
    }
}
struct LumaHomeLayout {
    static let dock:[LabApp]=[.phone,.messages,.browser,.settings]
    let columns:Int
    let rows:Int
    let showWidgets:Bool
    let spacing:CGFloat
    let dockHeight:CGFloat
    let gridHeight:CGFloat
    let rowHeight:CGFloat
    let iconSize:CGFloat
    let dockIconSize:CGFloat
    init(width:CGFloat,height:CGFloat,fiveColumns:Bool,smallIcons:Bool) {
        let columns=fiveColumns ? 5 : 4
        self.columns=columns
        showWidgets=height>=540
        spacing=height>=600 ? 8 : 4
        dockHeight=height>=540 ? 86 : 72
        let gapCount:CGFloat=showWidgets ? 6 : 5
        // Header, search, optional widgets, dots, shortcuts, dock, and padding.
        let reserved:CGFloat=44+42+(showWidgets ? 74:0)+32+44+dockHeight+16+gapCount*spacing
        gridHeight=max(48,height-reserved)
        let rowCount=max(1,min(3,Int(gridHeight/79)))
        rows=rowCount
        rowHeight=gridHeight/CGFloat(rowCount)
        let cellWidth=max(28,(width-28-CGFloat(columns-1)*4)/CGFloat(columns))
        iconSize=max(22,min(smallIcons ? 43:61,min(cellWidth-5,rowHeight-21)))
        dockIconSize=max(24,min(smallIcons ? 43:61,min((width-28-18-18)/4-4,dockHeight-30)))
    }
    static func pages(columns:Int,rows:Int,fieldNotes:Bool)->[[LumaHomeEntry]] {
        let capacity=max(1,columns*rows)
        let personal:[LumaHomeEntry]=[
            .app(.contacts),.app(.photos),.app(.notes),.app(.calendar),
            .app(.mail),.folder(.social),.folder(.studio),.folder(.everyday)
        ]
        var repair:[LumaHomeEntry]=[.app(.relay),.app(.patchline),.app(.workstation),.app(.saves)]
        if fieldNotes { repair.append(.app(.fieldNotes)) }
        func chunks(_ entries:[LumaHomeEntry])->[[LumaHomeEntry]] {
            stride(from:0,to:entries.count,by:capacity).map { start in
                Array(entries[start..<min(start+capacity,entries.count)])
            }
        }
        return chunks(personal)+chunks(repair)
    }
}
