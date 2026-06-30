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
                title: "The Goal: Input → Output",
                body: "Each puzzle has copper INPUT cells (dashed copper squares) that supply atoms, and one green OUTPUT cell (the sink) that wants a specific molecule. Your job: build a machine that carries atoms from the copper inputs to the green output to make that molecule.",
                glyph: AnyView(HStack(spacing: 14) {
                    AtomNodeView(element: .alpha, size: 34)
                    InstructionGlyph(instruction: .extend, color: GearPalette.haze).frame(width: 24, height: 24)
                    RoundedRectangle(cornerRadius: 5).stroke(GearPalette.verdigris, lineWidth: 2)
                        .frame(width: 34, height: 34)
                })),
            OnboardingStep(
                title: "Place an Arm",
                body: "Pick the Arm tool and tap a grid cell next to a copper input. An arm has a pivot, a reach of 1–3, and a starting facing. Tap an arm to select it and adjust its reach and heading. No arm = nothing to run.",
                glyph: AnyView(ArmToolGlyph(color: GearPalette.copperBright).frame(width: 80, height: 80))),
            OnboardingStep(
                title: "Program the Looping Tape",
                body: "Each arm runs a tape of instructions — Grab, Turn, Extend, Drop. It performs ONE instruction per cycle, then LOOPS back to the start and repeats forever. A good short loop grabs an atom at the input and drops it at the output, over and over.",
                glyph: AnyView(HStack(spacing: 8) {
                    ForEach([Instruction.grab, .rotateCW, .drop], id: \.rawValue) { ins in
                        InstructionGlyph(instruction: ins, color: GearPalette.copperBright)
                            .frame(width: 30, height: 30).padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(GearPalette.navyDeep))
                    }
                })),
            OnboardingStep(
                title: "Bond and Build",
                body: "Place bonders on adjacent cells to fuse atoms into molecules. The arm grabs a whole bonded group at once, so you can carry assembled products to the green output.",
                glyph: AnyView(HStack(spacing: 4) {
                    AtomNodeView(element: .alpha, size: 34)
                    Rectangle().fill(GearPalette.copperBright).frame(width: 16, height: 5)
                    AtomNodeView(element: .beta, size: 34)
                })),
            OnboardingStep(
                title: "Run, Reset, Refine",
                body: "Press Run to simulate your machine (Step advances one cycle so you can study it). Reset stops the run and returns you to editing — your machine is kept, the atoms just go back to the start. Beat the cycle and cost budgets for up to three stars. Let's build!",
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
