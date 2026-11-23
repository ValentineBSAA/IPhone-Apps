import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var kitchen: KitchenStore
    @State private var chosen: FryerPreset = .airFry
    @State private var temperature = 360
    @State private var minutes = 10
    @State private var saved = false

    private var live: Bool { !kitchen.previewMode && kitchen.status?.connected == true }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PageHeading(eyebrow: "CRISP COMPANION", title: "Good evening, chef.", subtitle: "Your kitchen, beautifully organized.")
                statusBanner
                heroCard
                controlsCard
                presetsCard
                notesCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 30)
        }
        .background(CrispPalette.background)
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            if !kitchen.previewMode { await kitchen.refresh() }
        }
    }

    private var statusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: live ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundColor(live ? CrispPalette.green : CrispPalette.gold)
            VStack(alignment: .leading, spacing: 3) {
                Text(kitchen.previewMode ? "PREVIEW MODE" : (live ? "LIVE DEVICE DATA" : "NOT CONNECTED"))
                    .font(.caption.weight(.bold)).tracking(1.1)
                Text(kitchen.previewMode ? "Planning only. Nothing here controls your fryer." : (kitchen.lastError ?? "Connected through your private bridge."))
                    .font(.caption)
                    .foregroundColor(CrispPalette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CrispPalette.panelRaised.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var heroCard: some View {
        VStack(spacing: 15) {
            HStack {
                Label("COSORI Dual Blaze", systemImage: "flame.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Text(live ? "ONLINE" : "OFFLINE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background((live ? CrispPalette.green : CrispPalette.muted).opacity(0.18), in: Capsule())
            }
            .foregroundColor(CrispPalette.cream)

            ZStack {
                Circle()
                    .stroke(CrispPalette.panelRaised, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: live && kitchen.status?.cooking == true ? 0.67 : 0.18)
                    .stroke(
                        AngularGradient(colors: [CrispPalette.gold, CrispPalette.peach], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 31))
                        .foregroundStyle(CrispPalette.gold)
                    Text(live ? (kitchen.status?.temperatureF.map { "\($0)°F" } ?? "—") : "—")
                        .font(.system(size: 45, weight: .bold, design: .rounded))
                        .foregroundColor(CrispPalette.cream)
                    Text(live ? (kitchen.status?.cooking == true ? "COOKING" : "NOT COOKING") : "NO LIVE READING")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.4)
                        .foregroundColor(CrispPalette.muted)
                }
            }
            .frame(width: 226, height: 226)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

            HStack(spacing: 10) {
                metric(title: "Time left", value: live ? kitchen.status?.minutesRemaining.map { "\($0) min" } ?? "—" : "—")
                metric(title: "Current mode", value: live ? (kitchen.status?.preset ?? "—") : "—")
            }
            if !kitchen.previewMode {
                Button {
                    Task { await kitchen.refresh() }
                } label: {
                    Label(kitchen.isRefreshing ? "Checking…" : "Refresh actual status", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(kitchen.isRefreshing)
            }
        }
        .padding(22)
        .background(
            LinearGradient(colors: [Color(red: 0.28, green: 0.21, blue: 0.20), CrispPalette.panel], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 30)
        )
        .overlay(RoundedRectangle(cornerRadius: 30).strokeBorder(CrispPalette.gold.opacity(0.16)))
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).foregroundColor(CrispPalette.muted)
            Text(value).font(.system(size: 17, weight: .bold, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.7).foregroundColor(CrispPalette.cream)
        }
        .frame(maxWidth: .infinity).padding(13)
        .background(Color.black.opacity(0.17), in: RoundedRectangle(cornerRadius: 18))
    }

    private var controlsCard: some View {
        CrispCard {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Recipe planner").font(.title3.bold()).foregroundColor(CrispPalette.cream)
                    Text("Choose a temperature and duration").font(.caption).foregroundColor(CrispPalette.muted)
                }
                Spacer()
                Image(systemName: "slider.horizontal.3").foregroundColor(CrispPalette.gold)
            }
            settingRow(title: "Temperature", value: "\(temperature)°F",
                       decrease: { temperature = max(175, temperature - 5) },
                       increase: { temperature = min(400, temperature + 5) })
            settingRow(title: "Duration", value: "\(minutes) min",
                       decrease: { minutes = max(1, minutes - 1) },
                       increase: { minutes = min(60, minutes + 1) })
            Button {
                kitchen.addRecipe(SavedRecipe(title: chosen.name + " Favorite", temperatureF: temperature, minutes: minutes))
                saved = true
            } label: {
                Label("Save to my recipes", systemImage: "bookmark.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .tint(CrispPalette.gold)
            .foregroundColor(CrispPalette.background)
            Text("These settings are local notes only. They are never sent to the heater.")
                .font(.caption2).foregroundColor(CrispPalette.muted)
            if saved { Label("Recipe saved on this iPhone", systemImage: "checkmark.circle.fill").font(.caption).foregroundColor(CrispPalette.green) }
        }
    }

    private func settingRow(title: String, value: String, decrease: @escaping () -> Void, increase: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundColor(CrispPalette.muted)
                Text(value).font(.title2.bold()).monospacedDigit().foregroundColor(CrispPalette.cream)
            }
            Spacer()
            Button(action: decrease) { Image(systemName: "minus").frame(width: 38, height: 38) }
                .buttonStyle(.bordered).accessibilityLabel("Decrease " + title)
            Button(action: increase) { Image(systemName: "plus").frame(width: 38, height: 38) }
                .buttonStyle(.bordered).accessibilityLabel("Increase " + title)
        }
    }

    private var presetsCard: some View {
        CrispCard {
            Text("Factory preset planner").font(.title3.bold()).foregroundColor(CrispPalette.cream)
            Text("12 documented COSORI defaults. Planning only, not live fryer settings.")
                .font(.caption).foregroundColor(CrispPalette.muted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(FryerPreset.allCases) { preset in
                    Button {
                        chosen = preset
                        temperature = preset.suggestedFahrenheit
                        minutes = preset.suggestedMinutes
                        saved = false
                    } label: {
                        VStack(spacing: 9) {
                            Image(systemName: preset.symbol).font(.title2)
                            Text(preset.name).font(.system(size: 12, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 75)
                        .foregroundColor(chosen == preset ? CrispPalette.background : CrispPalette.cream)
                        .background(chosen == preset ? CrispPalette.gold : CrispPalette.panelRaised,
                                    in: RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var notesCard: some View {
        CrispCard {
            Label("Safety first", systemImage: "hand.raised.fill")
                .font(.subheadline.bold()).foregroundColor(CrispPalette.gold)
            Text("Never leave a heated appliance unattended. Cooking starts using the physical controls on the fryer, not this app. Always follow your COSORI manual.")
                .font(.footnote).foregroundColor(CrispPalette.muted)
        }
    }
}
