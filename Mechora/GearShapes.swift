import SwiftUI

// MARK: - Core gear/cog Shape

struct GearCogShape: Shape {
    var teeth: Int = 10
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) / 2
        let rInner = rOuter * 0.74
        let rHub = rOuter * 0.34
        let count = max(6, teeth)
        let total = count * 2
        for i in 0..<total {
            let frac = Double(i) / Double(total)
            let angle = frac * 2 * Double.pi
            let r = (i % 2 == 0) ? rOuter : rInner
            let p = CGPoint(x: c.x + CGFloat(cos(angle)) * r, y: c.y + CGFloat(sin(angle)) * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        // hub hole
        path.addEllipse(in: CGRect(x: c.x - rHub, y: c.y - rHub, width: rHub * 2, height: rHub * 2))
        return path
    }
}

// MARK: - Tab glyphs

struct WorkbenchGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width
            ZStack {
                GearCogShape(teeth: 9)
                    .stroke(color, lineWidth: w * 0.08)
                    .frame(width: w * 0.78, height: w * 0.78)
                Circle().fill(color).frame(width: w * 0.18, height: w * 0.18)
            }
            .frame(width: w, height: p.size.height)
        }
    }
}

struct ManualGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.08)
                    .stroke(color, lineWidth: w * 0.075)
                    .frame(width: w * 0.74, height: h * 0.82)
                Rectangle().fill(color).frame(width: w * 0.06, height: h * 0.82)
                VStack(spacing: h * 0.1) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(color).frame(width: w * 0.4, height: h * 0.05)
                            .offset(x: w * 0.08)
                    }
                }
            }
            .frame(width: w, height: h)
        }
    }
}

struct AwardsGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                Circle().stroke(color, lineWidth: w * 0.08).frame(width: w * 0.5, height: w * 0.5)
                    .offset(y: -h * 0.08)
                StarShape(points: 5)
                    .fill(color)
                    .frame(width: w * 0.26, height: w * 0.26)
                    .offset(y: -h * 0.08)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.4, y: h * 0.55))
                    path.addLine(to: CGPoint(x: w * 0.32, y: h * 0.92))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.78))
                    path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.92))
                    path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.55))
                }.fill(color)
            }
            .frame(width: w, height: h)
        }
    }
}

struct MoreGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            VStack(spacing: h * 0.16) {
                ForEach(0..<3, id: \.self) { i in
                    ZStack(alignment: i == 1 ? .trailing : .leading) {
                        Capsule().fill(color.opacity(0.4)).frame(height: h * 0.1)
                        Circle().fill(color).frame(width: h * 0.2, height: h * 0.2)
                    }
                }
            }
            .frame(width: w * 0.74, height: h * 0.66)
            .frame(width: w, height: h)
        }
    }
}

// MARK: - Star

struct StarShape: Shape {
    var points: Int = 5
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) / 2
        let rInner = rOuter * 0.45
        let total = points * 2
        for i in 0..<total {
            let angle = -Double.pi / 2 + Double(i) / Double(total) * 2 * Double.pi
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * r, y: c.y + CGFloat(sin(angle)) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

struct StarRow: View {
    let filled: Int
    let total: Int
    var size: CGFloat = 16
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { i in
                StarShape(points: 5)
                    .fill(i < filled ? GearPalette.gold : GearPalette.haze.opacity(0.3))
                    .frame(width: size, height: size)
            }
        }
    }
}

// MARK: - Run controls

struct PlayGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            Path { path in
                path.move(to: CGPoint(x: w * 0.28, y: h * 0.2))
                path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.5))
                path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.8))
                path.closeSubpath()
            }.fill(color)
        }
    }
}

struct PauseGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            HStack(spacing: w * 0.14) {
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: w * 0.2)
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: w * 0.2)
            }
            .frame(width: w * 0.54, height: h * 0.6)
            .frame(width: w, height: h)
        }
    }
}

struct StepGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            HStack(spacing: w * 0.06) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.22))
                    path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.5))
                    path.addLine(to: CGPoint(x: 0, y: h * 0.78))
                    path.closeSubpath()
                }.fill(color).frame(width: w * 0.42)
                RoundedRectangle(cornerRadius: 1).fill(color).frame(width: w * 0.12, height: h * 0.56)
            }
            .frame(width: w * 0.62, height: h)
            .frame(width: w, height: h)
        }
    }
}

struct ResetGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                Path { path in
                    path.addArc(center: CGPoint(x: w * 0.5, y: h * 0.5),
                                radius: w * 0.3, startAngle: .degrees(70), endAngle: .degrees(360), clockwise: false)
                }.stroke(color, style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round))
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: h * 0.1))
                    path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.28))
                    path.addLine(to: CGPoint(x: w * 0.46, y: h * 0.36))
                    path.closeSubpath()
                }.fill(color)
            }
        }
    }
}

// MARK: - Tool glyphs (palette)

struct ArmToolGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                Circle().fill(color).frame(width: w * 0.22, height: w * 0.22)
                    .position(x: w * 0.28, y: h * 0.72)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.28, y: h * 0.72))
                    path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.28))
                }.stroke(color, style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round))
                Path { path in
                    path.move(to: CGPoint(x: w * 0.6, y: h * 0.2))
                    path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.22))
                    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.44))
                }.stroke(color, style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

struct BonderToolGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                Circle().stroke(color, lineWidth: w * 0.08).frame(width: w * 0.28, height: w * 0.28)
                    .position(x: w * 0.3, y: h * 0.5)
                Circle().stroke(color, lineWidth: w * 0.08).frame(width: w * 0.28, height: w * 0.28)
                    .position(x: w * 0.7, y: h * 0.5)
                Rectangle().fill(color).frame(width: w * 0.2, height: h * 0.08)
                    .position(x: w * 0.5, y: h * 0.5)
            }
        }
    }
}

struct EraseToolGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.08)
                    .stroke(color, lineWidth: w * 0.08)
                    .frame(width: w * 0.5, height: h * 0.34)
                    .rotationEffect(.degrees(-40))
                Path { path in
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.82))
                    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.82))
                }.stroke(color, style: StrokeStyle(lineWidth: w * 0.08, lineCap: .round))
            }
        }
    }
}

struct SelectToolGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            Path { path in
                path.move(to: CGPoint(x: w * 0.28, y: h * 0.18))
                path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.82))
                path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.62))
                path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.88))
                path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.82))
                path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.56))
                path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.5))
                path.closeSubpath()
            }.fill(color)
        }
    }
}

// MARK: - Instruction token glyph

struct InstructionGlyph: View {
    let instruction: Instruction
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                switch instruction {
                case .grab:
                    // gripper closing
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.3, y: h * 0.2))
                        path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.5))
                        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.5))
                        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.2))
                    }.stroke(color, style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round, lineJoin: .round))
                    Circle().fill(color).frame(width: w * 0.22, height: w * 0.22).position(x: w * 0.5, y: h * 0.7)
                case .drop:
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.5, y: h * 0.2))
                        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.62))
                    }.stroke(color, style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round))
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.34, y: h * 0.48))
                        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.66))
                        path.addLine(to: CGPoint(x: w * 0.66, y: h * 0.48))
                    }.stroke(color, style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round, lineJoin: .round))
                    Circle().fill(color).frame(width: w * 0.2, height: w * 0.2).position(x: w * 0.5, y: h * 0.82)
                case .rotateCW:
                    rotationArc(w: w, h: h, clockwise: true)
                case .rotateCCW:
                    rotationArc(w: w, h: h, clockwise: false)
                case .extend:
                    arrow(w: w, h: h, outward: true)
                case .retract:
                    arrow(w: w, h: h, outward: false)
                case .trackForward:
                    Text("»").font(.system(size: w * 0.6, weight: .black)).foregroundColor(color)
                case .trackBackward:
                    Text("«").font(.system(size: w * 0.6, weight: .black)).foregroundColor(color)
                case .wait:
                    Circle().stroke(color, lineWidth: w * 0.08).frame(width: w * 0.5, height: w * 0.5)
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.5, y: h * 0.5))
                        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.32))
                        path.move(to: CGPoint(x: w * 0.5, y: h * 0.5))
                        path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.56))
                    }.stroke(color, style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round))
                }
            }
        }
    }

    private func rotationArc(w: CGFloat, h: CGFloat, clockwise: Bool) -> some View {
        ZStack {
            Path { path in
                path.addArc(center: CGPoint(x: w * 0.5, y: h * 0.5), radius: w * 0.28,
                            startAngle: .degrees(clockwise ? 200 : -20),
                            endAngle: .degrees(clockwise ? 70 : 110),
                            clockwise: !clockwise)
            }.stroke(color, style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round))
            let tip = clockwise ? CGPoint(x: w * 0.78, y: h * 0.42) : CGPoint(x: w * 0.22, y: h * 0.42)
            Path { path in
                path.move(to: CGPoint(x: tip.x - w * 0.02, y: tip.y - h * 0.16))
                path.addLine(to: tip)
                path.addLine(to: CGPoint(x: tip.x + (clockwise ? -w * 0.16 : w * 0.16), y: tip.y - h * 0.02))
            }.stroke(color, style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round, lineJoin: .round))
        }
    }

    private func arrow(w: CGFloat, h: CGFloat, outward: Bool) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.2))
                path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.8))
            }.stroke(color, style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round))
            let tipY: CGFloat = outward ? h * 0.2 : h * 0.8
            let dir: CGFloat = outward ? 1 : -1
            Path { path in
                path.move(to: CGPoint(x: w * 0.34, y: tipY + dir * h * 0.18))
                path.addLine(to: CGPoint(x: w * 0.5, y: tipY))
                path.addLine(to: CGPoint(x: w * 0.66, y: tipY + dir * h * 0.18))
            }.stroke(color, style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - Atom node + bond (for manual / decor)

struct AtomNodeView: View {
    let element: Element
    var size: CGFloat = 30
    var body: some View {
        ZStack {
            Circle()
                .fill(GearPalette.element(element))
                .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 1.5))
            Text(element.symbol)
                .font(.system(size: size * 0.5, weight: .black, design: .rounded))
                .foregroundColor(element == .delta || element == .gamma ? GearPalette.navyDeep : GearPalette.navyDeep)
        }
        .frame(width: size, height: size)
    }
}
