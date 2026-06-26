import SwiftUI

struct OnboardingStep {
    let title: String
    let body: String
    let glyph: AnyView
}

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var step = 0

    private var steps: [OnboardingStep] {
        [
            OnboardingStep(
                title: "Welcome to the Drafting Room",
                body: "Gearworks Assembly is a puzzle of programmable machines. You build a machine on the grid and it runs in perfectly predictable cycles to turn input atoms into the product the sink wants.",
                glyph: AnyView(ZStack {
                    GearCogShape(teeth: 11).fill(GearPalette.copper).frame(width: 80, height: 80)
                    GearCogShape(teeth: 8).fill(GearPalette.verdigris).frame(width: 48, height: 48).offset(x: 50, y: 36)
                })),
            OnboardingStep(
                title: "Place an Arm",
                body: "Pick the Arm tool and tap the grid. An arm has a pivot, a reach of 1–3, and a starting facing. Tap an arm to select it and adjust its reach and heading.",
                glyph: AnyView(ArmToolGlyph(color: GearPalette.copperBright).frame(width: 80, height: 80))),
            OnboardingStep(
                title: "Write the Program",
                body: "Each arm runs a looping tape of instructions — Grab, Turn, Extend, Drop — one step per cycle. Add tokens from the palette and reorder them. A short loop can deliver many products.",
                glyph: AnyView(HStack(spacing: 8) {
                    ForEach([Instruction.grab, .rotateCW, .drop], id: \.rawValue) { ins in
                        InstructionGlyph(instruction: ins, color: GearPalette.copperBright)
                            .frame(width: 30, height: 30).padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(GearPalette.navyDeep))
                    }
                })),
            OnboardingStep(
                title: "Bond and Build",
                body: "Place bonders on adjacent cells to fuse atoms into molecules. The arm grabs a whole bonded group at once, so you can carry assembled products to the sink.",
                glyph: AnyView(HStack(spacing: 4) {
                    AtomNodeView(element: .alpha, size: 34)
                    Rectangle().fill(GearPalette.copperBright).frame(width: 16, height: 5)
                    AtomNodeView(element: .beta, size: 34)
                })),
            OnboardingStep(
                title: "Run, Step, Refine",
                body: "Press Run to simulate, or Step to advance one cycle and study it. Beat the cycle and cost budgets to earn up to three stars, and stars unlock new chapters. Let's build!",
                glyph: AnyView(HStack(spacing: 14) {
                    PlayGlyph(color: GearPalette.verdigris).frame(width: 34, height: 34)
                    StarRow(filled: 3, total: 3, size: 24)
                }))
        ]
    }

    var body: some View {
        ZStack {
            GearPalette.navy.ignoresSafeArea()
            GearBackdrop().ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { onFinish() } label: {
                        Text("Skip").font(.system(size: 14, weight: .bold)).foregroundColor(GearPalette.haze)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 16)

                Spacer()
                let s = steps[step]
                VStack(spacing: 24) {
                    s.glyph.frame(height: 110)
                    Text(s.title)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(GearPalette.ivory)
                        .multilineTextAlignment(.center)
                    Text(s.body)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(GearPalette.haze)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)
                }
                .frame(maxWidth: 560)
                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? GearPalette.copper : GearPalette.haze.opacity(0.3))
                            .frame(width: i == step ? 22 : 8, height: 8)
                    }
                }
                .padding(.bottom, 18)

                HStack(spacing: 12) {
                    if step > 0 {
                        Button { withAnimation { step -= 1 } } label: { Text("Back") }
                            .buttonStyle(GearButtonStyle(fill: GearPalette.panel, textColor: GearPalette.ivory))
                    }
                    Button {
                        if step < steps.count - 1 { withAnimation { step += 1 } } else { onFinish() }
                    } label: {
                        Text(step < steps.count - 1 ? "Next" : "Start Building")
                    }
                    .buttonStyle(GearButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .gearReadable()
        }
        .preferredColorScheme(.dark)
    }
}
