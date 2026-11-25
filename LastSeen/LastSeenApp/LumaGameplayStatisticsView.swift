import SwiftUI

struct LumaGameplayStatisticsView: View {
    @ObservedObject var store: LumaSaveStore
    @EnvironmentObject private var world: PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.saves.interval") private var interval = 5
    @AppStorage("lastseen.relay.installed") private var installed = ""
    private var earned: Int {
        LumaUtility.allCases.filter { world.state.flags.contains($0.flag) }.count + (RecoveryCircuit.unlocked(world.state.flags) ? 1 : 0)
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                LumaHeader(title:"Gameplay Statistics",detail:"Your time in LumaOS",symbol:"chart.bar.xaxis")
                VStack(alignment:.leading,spacing:8) {
                    Text("TOTAL ACTIVE PLAYTIME").font(.caption.weight(.semibold)).foregroundColor(.secondary)
                    Text(LumaSaveStore.duration(store.lifetimeSeconds)).font(.system(.largeTitle,design:.monospaced).weight(.bold)).foregroundColor(LumaDesign.accent)
                    Text("Lifetime playtime is kept when a checkpoint is loaded.").font(.caption).foregroundColor(.secondary)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(18).lumaSurface()
                HStack(alignment:.top,spacing:10) {
                    metric("Current session",LumaSaveStore.duration(store.sessionSeconds),symbol:"clock")
                    metric("Next autosave",nextLabel,symbol:"clock.arrow.circlepath")
                }
                VStack(alignment:.leading,spacing:12) {
                    Text("Checkpoints").font(.headline)
                    LabeledContent("Interval",value:interval == 0 ? "Off" : "\(interval) min")
                    if let date = store.lastSuccessfulAutomatic {
                        LabeledContent("Last successful save") { Text(date,style:.relative) }
                    } else { LabeledContent("Last successful save",value:"Not yet saved") }
                    LabeledContent("Automatic slots",value:"\(LumaSaveStore.automatic.filter { store.slots[$0] != nil }.count) / 3")
                    if store.automaticFailed { Label("Autosave failed; retry pending",systemImage:"exclamationmark.triangle").foregroundColor(.orange).font(.caption) }
                }.padding(16).lumaSurface()
                VStack(alignment:.leading,spacing:12) {
                    Text("Investigation").font(.headline)
                    LabeledContent("Completed milestones",value:InvestigationProgress.summary(world.state.flags))
                    LabeledContent("Earned utility certifications",value:String(earned))
                    LabeledContent("Installed optional packages",value:String(RelayCatalog.ids(installed).filter { RelayCatalog.package($0)?.essential == false }.count))
                }.padding(16).lumaSurface()
                Text("Statistics are stored on this phone. No external analytics.").font(.caption).foregroundColor(.secondary)
            }.padding(18)
        }.navigationTitle("Statistics").navigationBarTitleDisplayMode(.inline)
    }
    private var nextLabel: String {
        guard let seconds = store.nextAutomaticSeconds(interval:interval) else { return "Off" }
        if phase != .active { return "Paused" }
        if store.automaticFailed { return "Retry pending" }
        return seconds == 0 ? "Due" : LumaSaveStore.duration(seconds)
    }
    private func metric(_ title:String,_ value:String,symbol:String)->some View {
        VStack(alignment:.leading,spacing:7) {
            Image(systemName:symbol).foregroundColor(LumaDesign.accent)
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline.monospacedDigit()).fixedSize(horizontal:false,vertical:true)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(13).lumaSurface(radius:16)
    }
}
