import SwiftUI

/// Fictional local state only. No downloaded code, external routes, or OS modification.
enum EntityEcho {
    static let installed = "entity.echo.installed.v1"
    static let removed = "entity.echo.quarantined.v1"
    static let overrides: Set<String> = ["seconds","compact","quietbadges"]
    static let clues = [
        "The foreign clock hook repeats the smallest unit of time.",
        "The foreign layout hook squeezes the launcher icons.",
        "The foreign alert hook hides unread counts, not the messages."
    ]
    static let choices = ["Clock echo","Grid echo","Badge echo","Wallpaper","Archive reader"]
    static let solution = ["Clock echo","Grid echo","Badge echo"]
    static func active(_ flags:Set<String>)->Bool {
        flags.contains(installed) && !flags.contains(removed)
    }
    static func canInstall(_ world:PhoneWorld)->Bool {
        VeilArchive.authorized(world) && !world.flags.contains(installed) && !world.flags.contains(removed)
    }
    static func overridesTweak(_ id:String,flags:Set<String>,safeMode:Bool)->Bool {
        !safeMode && active(flags) && overrides.contains(id)
    }
    static func valid(_ answers:[String])->Bool { answers == solution }
}

struct EntityEchoOffer: View {
    let packages:String
    let safeMode:Bool
    let sessionAvailable:Bool
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @State private var approvalEpoch:UUID?
    @State private var feedback=""
    var body:some View {
        VStack(alignment:.leading,spacing:10) {
            Label("ECHO / unverified extension",systemImage:"shippingbox").font(.headline)
            Text("An anonymous archive offers an unsigned shell extension. Its advertised behavior is not verified.").font(.subheadline)
            if EntityEcho.active(world.state.flags) {
                Label("Foreign extension installed",systemImage:"exclamationmark.shield").foregroundColor(.orange)
                Text("Patchline can inspect and isolate the affected hooks.").font(.caption)
            } else if world.state.flags.contains(EntityEcho.removed) {
                Label("Extension quarantined",systemImage:"checkmark.shield")
            } else if EntityEcho.canInstall(world.state) && sessionAvailable {
                if approvalEpoch == world.checkpointEpoch {
                    Text("This optional fictional event can temporarily alter launcher presentation. You can recover it in Patchline without losing records.").font(.caption)
                    Button("Install unverified extension",role:.destructive) {
                        guard phase == .active,sessionAvailable,approvalEpoch==world.checkpointEpoch else{return}
                        let ok=world.installEntityEcho(packages:packages,safeMode:safeMode,epoch:world.checkpointEpoch)
                        approvalEpoch=nil
                        feedback=ok ? "Unexpected loader hooks detected. Open Patchline." : "Installation unavailable. No changes committed."
                    }.buttonStyle(.borderedProminent)
                    Button("Cancel"){approvalEpoch=nil}.buttonStyle(.bordered)
                } else {
                    Button("Inspect extension"){approvalEpoch=world.checkpointEpoch;feedback=""}.buttonStyle(.bordered)
                }
            }
            if !feedback.isEmpty {Text(feedback).font(.caption)}
        }.padding(12).lumaSurface()
            .onChange(of:world.checkpointEpoch){_ in approvalEpoch=nil;feedback=""}
            .onChange(of:phase){if $0 != .active {approvalEpoch=nil;feedback=""}}
            .onChange(of:sessionAvailable){if !$0 {approvalEpoch=nil}}
    }
}

struct EntityEchoRemovalView:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    @State private var answers:[String]=[]
    @State private var feedback=""
    @State private var epoch:UUID?
    private func reset(){answers=[];feedback="";epoch=world.checkpointEpoch}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                Label("Echo containment",systemImage:"waveform.path.ecg").font(.title2.bold())
                if EntityEcho.active(world.state.flags) {
                    Text(safeMode ? "Safe Mode has paused the foreign hooks. The extension is still present." : "Three foreign presentation hooks are active. Identify and quarantine them.")
                    ProgressView(value:Double(answers.count),total:Double(EntityEcho.solution.count))
                    ForEach(EntityEcho.clues.indices,id:\.self){index in
                        VStack(alignment:.leading,spacing:8){
                            Text("Trace "+String(index+1)).font(.caption.bold())
                            Text(EntityEcho.clues[index])
                            if index < answers.count {Label(answers[index],systemImage:"checkmark.circle")}
                            else if index == answers.count {
                                ForEach(EntityEcho.choices.filter{!answers.contains($0)},id:\.self){choice in
                                    Button(choice){
                                        guard phase == .active,epoch==world.checkpointEpoch,EntityEcho.active(world.state.flags),answers.count==index else{return}
                                        guard choice==EntityEcho.solution[index] else {feedback="That hook is legitimate. Review the trace and try another.";return}
                                        answers.append(choice);feedback=""
                                    }.buttonStyle(.bordered).frame(minHeight:44)
                                }
                            }
                        }.padding(12).lumaSurface()
                    }
                    Button("Quarantine extension"){
                        guard phase == .active,let epoch else{return}
                        if world.removeEntityEcho(answers:answers,epoch:epoch){feedback="Foreign hooks isolated. Your original package configuration is intact."}
                        else {feedback="Quarantine could not be committed. Try again."}
                    }.buttonStyle(.borderedProminent).disabled(!EntityEcho.valid(answers))
                    Button("Reset trace"){reset()}.buttonStyle(.bordered)
                } else {
                    Label(world.state.flags.contains(EntityEcho.removed) ? "Extension quarantined" : "No foreign extension detected",systemImage:"checkmark.shield").font(.headline)
                    Text("Legitimate packages, records and investigation progress are unchanged.")
                }
                if !feedback.isEmpty {Text(feedback).font(.subheadline).accessibilityAddTraits(.updatesFrequently)}
                Text("Local fictional repair puzzle. No real files or device settings are accessed.").font(.caption).foregroundColor(.secondary)
            }.padding(18)
        }.navigationTitle("Echo containment").navigationBarTitleDisplayMode(.inline)
            .onAppear{reset()}
            .onChange(of:world.checkpointEpoch){_ in reset()}
            .onChange(of:phase){if $0 != .active {reset()}}
    }
}
