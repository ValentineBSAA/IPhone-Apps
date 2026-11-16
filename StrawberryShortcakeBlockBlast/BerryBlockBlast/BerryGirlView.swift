import SwiftUI

/// Uses the supplied BerryMascot image when installed; retains the geometric mascot as a safe fallback.
struct BerryGirlView: View {
    var body: some View {
        Group {
            if UIImage(named: "BerryMascot") != nil {
                Image("BerryMascot")
                    .resizable()
                    .scaledToFit()
            } else {
                GeometryReader { geo in
            let s = min(geo.size.width / 180, geo.size.height / 220)
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.66))
                    .frame(width: 162, height: 162)
                    .offset(y: 10)
                Circle().fill(Color(red: 0.99, green: 0.78, blue: 0.83))
                    .frame(width: 132, height: 132).offset(y: 14)
                // Puffed hair behind the face.
                Ellipse().fill(Color(red: 0.69, green: 0.27, blue: 0.19))
                    .frame(width: 110, height: 109).offset(y: 18)
                ForEach(0..<7, id: \.self) { n in
                    Circle().fill(Color(red: 0.77, green: 0.30, blue: 0.19))
                        .frame(width: 29, height: 29)
                        .offset(x: -46 + CGFloat(n) * 15, y: 45 + (n % 2 == 0 ? 0 : 7))
                }
                // Scalloped collar and strawberry-red dress.
                Ellipse().fill(Color.white).frame(width: 100, height: 60).offset(y: 90)
                RoundedRectangle(cornerRadius: 19)
                    .fill(Color(red: 0.92, green: 0.30, blue: 0.46))
                    .frame(width: 90, height: 58).offset(y: 99)
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(Color.white.opacity(0.60)).frame(width: 56, height: 4)
                    }
                }.offset(y: 95)
                // Face.
                Ellipse().fill(Color(red: 1, green: 0.84, blue: 0.66))
                    .frame(width: 96, height: 92).offset(y: 18)
                Ellipse().fill(Color(red: 0.99, green: 0.61, blue: 0.57)).opacity(0.74)
                    .frame(width: 23, height: 15).offset(x: -32, y: 29)
                Ellipse().fill(Color(red: 0.99, green: 0.61, blue: 0.57)).opacity(0.74)
                    .frame(width: 23, height: 15).offset(x: 32, y: 29)
                HStack(spacing: 23) {
                    ForEach(0..<2, id: \.self) { _ in
                        Ellipse().fill(Color(red: 0.31, green: 0.19, blue: 0.18))
                            .frame(width: 10, height: 15)
                            .overlay(alignment: .topLeading) {
                                Circle().fill(.white).frame(width: 4, height: 4).offset(x: 2, y: 2)
                            }
                    }
                }.offset(y: 14)
                ForEach([-1,1], id: \.self) { direction in
                    ForEach(0..<3, id: \.self) { dot in
                        Circle().fill(Color(red: 0.61, green: 0.35, blue: 0.27))
                            .frame(width: 2.5, height: 2.5)
                            .offset(x: CGFloat(direction) * (24 + CGFloat(dot)*5), y: 27 + CGFloat(dot%2)*3)
                    }
                }
                // The smile is positioned relative to the centered face, not
                // the parent view's top-left origin.
                Path { p in
                    p.move(to: CGPoint(x: 75, y: 135))
                    p.addQuadCurve(to: CGPoint(x: 105, y: 135), control: CGPoint(x: 90, y: 153))
                }
                .stroke(Color(red: 0.58, green: 0.23, blue: 0.27),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .frame(width: 180, height: 220)
                // Iconic berry-garden hat shape, original geometric rendering.
                Ellipse().fill(Color(red: 1, green: 0.74, blue: 0.82))
                    .frame(width: 162, height: 47).offset(y: -28)
                    .overlay {
                        Ellipse().stroke(Color(red: 0.91, green: 0.40, blue: 0.53), lineWidth: 3)
                            .frame(width: 160, height: 46).offset(y: -28)
                    }
                Ellipse().fill(Color(red: 1, green: 0.80, blue: 0.86))
                    .frame(width: 108, height: 62).offset(y: -56)
                Capsule().fill(Color(red: 0.91, green: 0.30, blue: 0.46))
                    .frame(width: 120, height: 9).offset(y: -37)
                ForEach([-31, 0, 32], id: \.self) { x in
                    TinyBerry().frame(width: 14, height: 16).offset(x: CGFloat(x), y: -62)
                }
                // Leafy striped bow and berry centerpiece.
                Ellipse().fill(Color.white).frame(width: 41, height: 23)
                    .rotationEffect(.degrees(26)).offset(x: 13, y: -65)
                Ellipse().fill(Color(red: 0.57, green: 0.78, blue: 0.45))
                    .frame(width: 31, height: 17).rotationEffect(.degrees(26)).offset(x: 12, y: -65)
                Ellipse().fill(Color.white).frame(width: 41, height: 23)
                    .rotationEffect(.degrees(-26)).offset(x: 48, y: -65)
                Ellipse().fill(Color(red: 0.57, green: 0.78, blue: 0.45))
                    .frame(width: 31, height: 17).rotationEffect(.degrees(-26)).offset(x: 46, y: -65)
                TinyBerry().frame(width: 21, height: 25).offset(x: 30, y: -65)
            }
            .frame(width: 180, height: 220)
            .scaleEffect(s)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
            }
        }
        .accessibilityLabel("Smiling berry-garden girl wearing a pink strawberry hat")
    }
}

private struct TinyBerry: View {
    var body: some View {
        GeometryReader { g in
            ZStack {
                Ellipse().fill(Color(red: 0.94, green: 0.22, blue: 0.35))
                    .frame(width: g.size.width * 0.88, height: g.size.height * 0.82)
                    .offset(y: g.size.height * 0.08)
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(Color(red: 1.0, green: 0.87, blue: 0.63))
                        .frame(width: 2, height: 2)
                        .offset(x: CGFloat(i - 1) * g.size.width * 0.19, y: g.size.height * 0.12)
                }
                Image(systemName: "leaf.fill")
                    .font(.system(size: g.size.width * 0.52))
                    .foregroundStyle(Color(red: 0.24, green: 0.60, blue: 0.32))
                    .offset(y: -g.size.height * 0.27)
            }.frame(width: g.size.width, height: g.size.height)
        }
    }
}
