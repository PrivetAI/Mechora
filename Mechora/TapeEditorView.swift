import SwiftUI

struct TapeEditorView: View {
    @ObservedObject var vm: EditorViewModel

    // instructions offered to the player (track is engine-only)
    private let palette: [Instruction] = [.grab, .drop, .rotateCW, .rotateCCW, .extend, .retract, .wait]

    var body: some View {
        GearCard {
            if let arm = vm.selectedArm {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Program Tape")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(GearPalette.ivory)
                        Spacer()
                        if let cur = vm.currentTapeIndex(forArmId: arm.id) {
                            Text("▶ running · step \(cur + 1)/\(arm.tape.count)")
                                .font(.system(size: 12, weight: .black)).foregroundColor(GearPalette.verdigris)
                        } else {
                            Text("\(arm.tape.count) steps · loops")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(GearPalette.haze)
                        }
                        if !arm.tape.isEmpty {
                            Button { vm.clearTape() } label: {
                                Text("Clear").font(.system(size: 12, weight: .bold)).foregroundColor(GearPalette.alert)
                            }.disabled(vm.isSimActive).opacity(vm.isSimActive ? 0.4 : 1)
                        }
                    }

                    tapeStrip(arm)

                    Text("Add instruction")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(GearPalette.haze)
                    paletteGrid
                        .opacity(vm.isSimActive ? 0.4 : 1)
                        .disabled(vm.isSimActive)
                }
            } else {
                Text("Select an arm to edit its program.")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
            }
        }
    }

    @ViewBuilder private func tapeStrip(_ arm: ArmPlacement) -> some View {
        if arm.tape.isEmpty {
            Text("Empty. Add Grab / Drop / Turn instructions below. The tape repeats forever.")
                .font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                let cur = vm.currentTapeIndex(forArmId: arm.id)
                HStack(spacing: 8) {
                    ForEach(Array(arm.tape.enumerated()), id: \.offset) { idx, ins in
                        tapeToken(index: idx, instruction: ins, isCurrent: idx == cur)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func tapeToken(index: Int, instruction: Instruction, isCurrent: Bool) -> some View {
        VStack(spacing: 4) {
            Text(isCurrent ? "▶ \(index + 1)" : "\(index + 1)")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(isCurrent ? GearPalette.verdigris : GearPalette.haze)
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 3) {
                    InstructionGlyph(instruction: instruction, color: GearPalette.copperBright)
                        .frame(width: 26, height: 26)
                    Text(instruction.shortLabel)
                        .font(.system(size: 9, weight: .black)).foregroundColor(GearPalette.ivory)
                }
                .padding(8)
                .frame(width: 60)
                .background(RoundedRectangle(cornerRadius: 10).fill(isCurrent ? GearPalette.panelLift : GearPalette.navyDeep))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(isCurrent ? GearPalette.verdigris : GearPalette.line, lineWidth: isCurrent ? 2.5 : 1))
            }
            if !vm.isSimActive {
                HStack(spacing: 6) {
                    miniButton("‹") { vm.moveInstruction(at: index, by: -1) }
                    miniButton("✕") { vm.removeInstruction(at: index) }
                    miniButton("›") { vm.moveInstruction(at: index, by: 1) }
                }
            }
        }
    }

    private func miniButton(_ s: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(s).font(.system(size: 13, weight: .black)).foregroundColor(GearPalette.ivory)
                .frame(width: 18, height: 20)
                .background(RoundedRectangle(cornerRadius: 5).fill(GearPalette.panelLift))
        }.buttonStyle(PlainButtonStyle())
    }

    private var paletteGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], spacing: 8) {
            ForEach(palette, id: \.rawValue) { ins in
                Button { vm.appendInstruction(ins) } label: {
                    HStack(spacing: 6) {
                        InstructionGlyph(instruction: ins, color: GearPalette.navyDeep)
                            .frame(width: 18, height: 18)
                        Text(ins.label).font(.system(size: 11, weight: .black)).foregroundColor(GearPalette.navyDeep)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 9).fill(GearPalette.copper))
                    .contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}
