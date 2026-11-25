import SwiftUI

enum Night {
    static let background = LumaDesign.background
    static let surface = LumaDesign.surface
    static let raised = LumaDesign.raised
    static let incoming = Color(red: 0.176, green: 0.190, blue: 0.224)
    static let accent = LumaDesign.accent
    static let outgoing = Color(red: 0.23, green: 0.40, blue: 0.68)
    static let danger = Color(red: 0.82, green: 0.25, blue: 0.34)
    static let muted = Color(red: 0.58, green: 0.61, blue: 0.69)
    static let gold = Color(red: 0.90, green: 0.72, blue: 0.45)
}

/// Resolve artwork from the app bundle explicitly. This matches the asset
/// lookup used by simulator regression tests and avoids test-host ambiguity.
enum PortraitImages {
    static func load(_ name: String) -> UIImage? {
        UIImage(named: name, in: Bundle(for: GameStore.self), compatibleWith: nil)
    }
}

struct ContactAvatar: View {
    let contact: Contact
    var size: CGFloat = 52
    var option: Int? = nil

    // Store portrait selections separately from chapter progress, so replay
    // never discards the player's preferred contact photographs.
    @AppStorage("lastseen.portrait.nora") private var noraPortrait = 1
    @AppStorage("lastseen.portrait.eli") private var eliPortrait = 1
    @AppStorage("lastseen.portrait.unit7") private var unit7Portrait = 1

    private var assetName: String {
        let chosen: Int
        let prefix: String
        switch contact {
        case .nora:
            prefix = "Contact_Nora"
            chosen = min(max(option ?? noraPortrait, 1), 4)
        case .eli:
            prefix = "Contact_Eli"
            chosen = min(max(option ?? eliPortrait, 1), 3)
        case .unit7:
            prefix = "Contact_Unit7"
            chosen = min(max(option ?? unit7Portrait, 1), 3)
        }
        return String(format: "%@_%02d", prefix, chosen)
    }

    private var fallbackColor: Color {
        switch contact {
        case .nora: return Color(red: 0.42, green: 0.44, blue: 0.66)
        case .eli: return Color(red: 0.32, green: 0.51, blue: 0.55)
        case .unit7: return Night.danger
        }
    }

    var body: some View {
        ZStack {
            if let photo = PortraitImages.load(assetName) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                Circle()
                    .fill(RadialGradient(
                        colors: [fallbackColor.opacity(0.9), fallbackColor.opacity(0.23), .black],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    ))
                Text(contact.initials)
                    .font(.system(
                        size: size * (contact == .unit7 ? 0.51 : 0.29),
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(.white.opacity(0.92))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(contact.name) contact photo")
    }
}

struct BubbleShape: Shape {
    let outgoing: Bool

    func path(in rect: CGRect) -> Path {
        let corners: UIRectCorner = outgoing
            ? [.topLeft, .topRight, .bottomLeft]
            : [.topLeft, .topRight, .bottomRight]
        return Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: 19, height: 19)
        ).cgPath)
    }
}

struct TypingDots: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.22)) { context in
            let active = Int(context.date.timeIntervalSinceReferenceDate * 4.5) % 3
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == active ? Color.white.opacity(0.90) : Color.white.opacity(0.33))
                        .frame(width: 7, height: 7)
                        .offset(y: index == active ? -2 : 1)
                }
            }
        }
        .padding(.horizontal, 15)
        .frame(height: 34)
        .background(Night.incoming, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Typing")
    }
}

struct EvidencePhoto: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            ZStack {
                LinearGradient(colors: [
                    Color(red: 0.12, green: 0.15, blue: 0.20),
                    Color(red: 0.03, green: 0.05, blue: 0.08),
                    Color(red: 0.10, green: 0.13, blue: 0.16)
                ], startPoint: .top, endPoint: .bottom)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.28))
                    path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.72))
                    path.addLine(to: CGPoint(x: 0, y: h))
                }
                .fill(Color(red: 0.11, green: 0.14, blue: 0.17))

                Path { path in
                    path.move(to: CGPoint(x: w, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.63, y: h * 0.28))
                    path.addLine(to: CGPoint(x: w * 0.63, y: h * 0.72))
                    path.addLine(to: CGPoint(x: w, y: h))
                }
                .fill(Color(red: 0.09, green: 0.12, blue: 0.15))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.72))
                    path.addLine(to: CGPoint(x: w * 0.63, y: h * 0.72))
                    path.addLine(to: CGPoint(x: w, y: h))
                }
                .fill(Color(red: 0.12, green: 0.15, blue: 0.17))

                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [.black, Color(red: 0.22, green: 0.26, blue: 0.30)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: w * 0.22, height: h * 0.44)
                    .overlay {
                        RoundedRectangle(cornerRadius: 1)
                            .stroke(Night.muted.opacity(0.33), lineWidth: 2)
                    }
                    .position(x: w * 0.50, y: h * 0.52)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: w * 0.13, height: h * 0.32)
                    .position(x: w * 0.76, y: h * 0.47)

                VStack(spacing: 3) {
                    Text("07").font(.system(size: max(14, w * 0.062), weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.87, green: 0.29, blue: 0.30))
                    Text("01:43").font(.system(size: max(8, w * 0.03), weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.65))
                }
                .position(x: w * 0.76, y: h * 0.39)

                VStack {
                    HStack {
                        Text("CAM 04").font(.system(size: 11, weight: .semibold, design: .monospaced))
                        Spacer()
                        Image(systemName: "record.circle").foregroundColor(Night.danger)
                    }
                    Spacer()
                    HStack {
                        Text("01:43 AM").font(.system(size: 10, design: .monospaced))
                        Spacer()
                        Text("NO SIGNAL").font(.system(size: 10, design: .monospaced))
                    }
                }
                .foregroundColor(.white.opacity(0.72))
                .padding(11)

                LinearGradient(colors: [.clear, .white.opacity(0.035), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .blendMode(.screen)
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .aspectRatio(1.40, contentMode: .fit)
        .accessibilityLabel("Dark apartment hallway photograph. A reflection shows 07 and 01:43.")
    }
}

struct SectionEyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(2.1)
            .foregroundColor(Night.muted)
    }
}
