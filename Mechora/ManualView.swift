import SwiftUI

struct ManualView: View {
    var body: some View {
        ZStack {
            GearPalette.navy.ignoresSafeArea()
            GearBackdrop().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    intro
                    mechanismsSection
                    instructionsSection
                    metricsSection
                    tipsSection
                }
                .padding(16)
                .gearReadable()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Workshop Manual")
                    .font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
            }
        }
    }

    private var intro: some View {
        GearCard {
            VStack(alignment: .leading, spacing: 8) {
                GearSectionHeader(title: "How It Works")
                Text("Mechora is a deterministic machine puzzle. You place mechanisms on a grid and write a looping program for each arm. Every arm runs ONE instruction per cycle, in lockstep. Transform the input atoms into the target product and deliver the required count.")
                    .font(.system(size: 14, weight: .medium)).foregroundColor(GearPalette.ivory)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var mechanismsSection: some View {
        GearCard {
            VStack(alignment: .leading, spacing: 14) {
                GearSectionHeader(title: "Mechanisms", accent: GearPalette.verdigris)
                manualRow(glyph: AnyView(ArmToolGlyph(color: GearPalette.copperBright)),
                          title: "Arm",
                          body: "Anchored at a pivot cell. Its tip reaches 1–3 cells out in the facing direction. It can grab one atom (and everything bonded to it), then carry it by rotating, extending, or retracting.")
                manualRow(glyph: AnyView(BonderToolGlyph(color: GearPalette.gold)),
                          title: "Bonder",
                          body: "Place bonders on adjacent cells. When atoms sit on two linked bonder cells they fuse into one molecule that moves together.")
                manualRow(glyph: AnyView(dispenserGlyph),
                          title: "Dispenser",
                          body: "Fixed input. It emits its atom (or small molecule) whenever its cell is empty, so you have an endless supply.")
                manualRow(glyph: AnyView(sinkGlyph),
                          title: "Sink",
                          body: "Fixed output. Deliver a free molecule that exactly matches the target shape and atom types. Most sinks accept any rotation; orientation-locked sinks demand an exact heading.")
            }
        }
    }

    private var dispenserGlyph: some View {
        RoundedRectangle(cornerRadius: 5).stroke(GearPalette.copper, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            .overlay(Circle().fill(GearPalette.copper.opacity(0.6)).padding(5))
            .frame(width: 24, height: 24)
    }
    private var sinkGlyph: some View {
        RoundedRectangle(cornerRadius: 5).stroke(GearPalette.verdigris, lineWidth: 2)
            .overlay(Circle().fill(GearPalette.verdigris.opacity(0.3)).padding(5))
            .frame(width: 24, height: 24)
    }

    private var instructionsSection: some View {
        GearCard {
            VStack(alignment: .leading, spacing: 12) {
                GearSectionHeader(title: "Instructions", accent: GearPalette.copper)
                ForEach([Instruction.grab, .drop, .rotateCW, .rotateCCW, .extend, .retract, .wait], id: \.rawValue) { ins in
                    HStack(alignment: .top, spacing: 12) {
                        InstructionGlyph(instruction: ins, color: GearPalette.copperBright)
                            .frame(width: 26, height: 26)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(GearPalette.navyDeep))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ins.label).font(.system(size: 14, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
                            Text(instructionDetail(ins)).font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func instructionDetail(_ ins: Instruction) -> String {
        switch ins {
        case .grab: return "Grab the atom at the arm tip (and its bonded group). No effect if hands are full or the tip is empty."
        case .drop: return "Release whatever the arm is holding; the atoms stay where they are."
        case .rotateCW: return "Rotate the arm a quarter-turn clockwise around its pivot, carrying any held atoms."
        case .rotateCCW: return "Rotate a quarter-turn counter-clockwise around the pivot."
        case .extend: return "Push the tip one cell further out (up to reach 3), sliding any held atoms outward."
        case .retract: return "Pull the tip one cell back in (down to reach 1)."
        case .trackForward: return "Move the arm base forward along its track."
        case .trackBackward: return "Move the arm base backward along its track."
        case .wait: return "Do nothing this cycle. Useful for timing two arms together."
        }
    }

    private var metricsSection: some View {
        GearCard {
            VStack(alignment: .leading, spacing: 10) {
                GearSectionHeader(title: "Stars & Metrics", accent: GearPalette.gold)
                bullet("Cycles", "Total lockstep steps to finish. Beat the cycle budget for the speed star.")
                bullet("Cost", "Sum of mechanism costs (arm 20, bonder 10). Stay at or under budget for the cost star.")
                bullet("Area", "Bounding box of your machine, including each arm's full reach.")
                bullet("Instructions", "Total program steps across every arm.")
                Text("Earn stars to unlock later chapters.")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(GearPalette.gold)
            }
        }
    }

    private var tipsSection: some View {
        GearCard {
            VStack(alignment: .leading, spacing: 10) {
                GearSectionHeader(title: "Tips", accent: GearPalette.blueprint)
                bullet("Step it", "Use Step to advance one cycle at a time and watch exactly what each arm does.")
                bullet("Loops", "The tape repeats forever, so a short program can deliver many products.")
                bullet("Collisions", "If two atoms are forced into the same cell the run fails — read the error and adjust timing.")
                bullet("Pan & zoom", "Drag to pan the board, pinch to zoom on larger puzzles.")
            }
        }
    }

    private func manualRow(glyph: AnyView, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            glyph.frame(width: 26, height: 26).padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(GearPalette.navyDeep))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
                Text(body).font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    private func bullet(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 14, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
            Text(body).font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
