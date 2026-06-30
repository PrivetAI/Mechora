import SwiftUI

enum GearPalette {
    static let navy = Color(red: 0.047, green: 0.102, blue: 0.169)      // #0C1A2B
    static let navyDeep = Color(red: 0.027, green: 0.063, blue: 0.110)
    static let panel = Color(red: 0.078, green: 0.149, blue: 0.227)
    static let panelLift = Color(red: 0.106, green: 0.196, blue: 0.290)
    static let blueprint = Color(red: 0.247, green: 0.655, blue: 0.769)  // #3FA7C4 cyan
    static let copper = Color(red: 0.784, green: 0.467, blue: 0.180)     // #C8772E
    static let copperBright = Color(red: 0.910, green: 0.560, blue: 0.250)
    static let ivory = Color(red: 0.937, green: 0.902, blue: 0.824)      // #EFE6D2
    static let verdigris = Color(red: 0.235, green: 0.549, blue: 0.431)  // #3C8C6E
    static let gold = Color(red: 0.95, green: 0.80, blue: 0.30)
    static let alert = Color(red: 0.86, green: 0.32, blue: 0.27)
    static let haze = Color(red: 0.56, green: 0.66, blue: 0.74)
    static let line = Color(red: 0.247, green: 0.655, blue: 0.769).opacity(0.30)

    static func element(_ e: Element) -> Color {
        switch e {
        case .alpha: return copper
        case .beta: return verdigris
        case .gamma: return gold
        case .delta: return ivory
        case .epsilon: return blueprint
        }
    }
}

/// Blueprint grid backdrop used behind most screens.
struct GearBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                LinearGradient(colors: [GearPalette.navyDeep, GearPalette.navy],
                               startPoint: .top, endPoint: .bottom)
                Canvas { ctx, size in
                    let step: CGFloat = 34
                    var x: CGFloat = 0
                    while x < size.width {
                        var line = Path()
                        line.move(to: CGPoint(x: x, y: 0))
                        line.addLine(to: CGPoint(x: x, y: size.height))
                        ctx.stroke(line, with: .color(GearPalette.blueprint.opacity(0.07)), lineWidth: 1)
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < size.height {
                        var line = Path()
                        line.move(to: CGPoint(x: 0, y: y))
                        line.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(line, with: .color(GearPalette.blueprint.opacity(0.07)), lineWidth: 1)
                        y += step
                    }
                }
                Circle()
                    .fill(GearPalette.copper.opacity(0.10))
                    .frame(width: w * 0.7, height: w * 0.7)
                    .blur(radius: 60)
                    .offset(x: w * 0.3, y: -h * 0.25)
                Circle()
                    .fill(GearPalette.verdigris.opacity(0.10))
                    .frame(width: w * 0.6, height: w * 0.6)
                    .blur(radius: 60)
                    .offset(x: -w * 0.3, y: h * 0.3)
            }
        }
    }
}

/// A standard titled card panel used across screens.
struct GearCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(GearPalette.panel)
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(GearPalette.line, lineWidth: 1))
            )
    }
}

struct GearSectionHeader: View {
    let title: String
    var accent: Color = GearPalette.copper
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent)
                .frame(width: 5, height: 20)
            Text(title)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(GearPalette.ivory)
            Spacer()
        }
    }
}

/// Primary action button.
struct GearButtonStyle: ButtonStyle {
    var fill: Color = GearPalette.copper
    var textColor: Color = GearPalette.navyDeep
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// Adaptive horizontal content width so iPad doesn't stretch text lines.
struct GearReadableWidth: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            Spacer(minLength: 0)
            content.frame(maxWidth: 680)
            Spacer(minLength: 0)
        }
    }
}

extension View {
    func gearReadable() -> some View { modifier(GearReadableWidth()) }
}
