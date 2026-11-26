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
    static func canTrigger(_ world:PhoneWorld)->Bool {
        InvestigationResolution.eligible(world) &&
        world.flags.contains("web.visited."+InvestigationResolution.indexID) &&
        !world.flags.contains(InvestigationResolution.completed) &&
        !world.flags.contains(installed) && !world.flags.contains(removed)
    }
    static func cleared(_ flags:Set<String>)->Bool {
        flags.contains(removed) || flags.contains(InvestigationResolution.completed)
    }
    static let repairChoices=["Verify","Restore","Isolate","Reload"]
    static let repairOrder=["Isolate","Verify","Restore"]
    static func validRepair(_ sequence:[String])->Bool {sequence==repairOrder}
    static func asksForHelp(_ text:String)->Bool {
        let words=Set(text.lowercased().split{!$0.isLetter && !$0.isNumber}.map(String.init))
        let specific:Set<String>=["virus","malware","infection","infected","echo","containment","quarantine","foreign","glitch","hacked","hook","hooks","tweak","tweaks"]
        let general:Set<String>=["help","stuck","hint","next","fix","repair","wrong","weird","happening","remove","deactivate","safe","more"]
        return !words.isDisjoint(with:specific) || !words.isDisjoint(with:general)
    }
    static func assistance(technical:Bool)->String {
        technical ? "Patchline can inspect the foreign extension even in Safe Mode. Match each trace to the affected service, then use the dependency hints to construct a recovery sequence. Do not remove legitimate packages." :
        "Something has changed in the phone's shell. I can't verify who caused it. Your records are still available. Open Patchline and compare the symptoms with its diagnostic traces; you can ask Alex for technical help."
    }
    static func overridesTweak(_ id:String,flags:Set<String>,safeMode:Bool)->Bool {
        !safeMode && active(flags) && overrides.contains(id)
    }
    static func valid(_ answers:[String])->Bool { answers == solution }
}

struct EntityEchoRemovalView:View {
    @EnvironmentObject private var world:PhoneWorldStore
    @Environment(\.scenePhase) private var phase
    @AppStorage("lastseen.relay.safeMode") private var safeMode=false
    @State private var answers:[String]=[]
    @State private var repair:[String]=[]
    @State private var feedback=""
    @State private var epoch:UUID?
    private func reset(){answers=[];repair=[];feedback="";epoch=world.checkpointEpoch}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                Label("Echo containment",systemImage:"waveform.path.ecg").font(.title2.bold())
                if EntityEcho.active(world.state.flags) {
                    Text(safeMode ? "Safe Mode has paused the foreign hooks. The extension is still present." : "Three foreign presentation hooks are active. Identify and quarantine them.")
                    ProgressView(value:Double(answers.count+repair.count),total:Double(EntityEcho.solution.count+EntityEcho.repairOrder.count))
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
                                    }.buttonStyle(.bordered).frame(minHeight:44).accessibilityIdentifier("echo.trace."+choice)
                                }
                            }
                        }.padding(12).lumaSurface()
                    }
                    if EntityEcho.valid(answers) {
                        VStack(alignment:.leading,spacing:8){
                            Text("Restore the service chain").font(.headline)
                            Text("Separate foreign hooks before verifying the remaining services. Restore only after verification. A reload alone does not repair the chain.")
                            Text(repair.isEmpty ? "Select three steps" : repair.joined(separator:" → ")).font(.caption.monospaced())
                            ForEach(EntityEcho.repairChoices,id:\.self){step in
                                Button(step){
                                    guard phase == .active,epoch==world.checkpointEpoch,EntityEcho.active(world.state.flags),repair.count<3,!repair.contains(step) else{return}
                                    repair.append(step);feedback=""
                                }.buttonStyle(.bordered).disabled(repair.contains(step)||repair.count==3).frame(minHeight:44).accessibilityIdentifier("echo.repair."+step)
                            }
                            Button("Clear sequence"){repair=[];feedback=""}.buttonStyle(.bordered)
                        }.padding(12).lumaSurface()
                    }
                    Button("Quarantine extension"){
                        guard phase == .active,let epoch else{return}
                        if !EntityEcho.validRepair(repair){feedback="Service order is not verified. Recheck the dependency hints.";repair=[];return}
                        if world.removeEntityEcho(answers:answers,repair:repair,epoch:epoch){feedback="Foreign hooks isolated. Your original package configuration is intact."}
                        else {feedback="Quarantine could not be committed. Try again."}
                    }.buttonStyle(.borderedProminent).disabled(!EntityEcho.valid(answers) || repair.count != 3).accessibilityIdentifier("echo.commit")
                    Button("Reset trace"){reset()}.buttonStyle(.bordered)
                } else {
                    Label(world.state.flags.contains(EntityEcho.removed) ? "Extension quarantined" : "No foreign extension detected",systemImage:"checkmark.shield").font(.headline)
                    Text("Legitimate packages, records and investigation progress are unchanged.").accessibilityIdentifier("echo.containment.result")
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
