import SwiftUI

// Kept as a convenience stack for the landscape layout.
struct EditorControls: View {
    @ObservedObject var vm: EditorViewModel
    var body: some View {
        VStack(spacing: 8) {
            MechToolRow(vm: vm)
            MechSimRow(vm: vm)
        }
        .padding(.horizontal, 10)
    }
}

// MARK: - Build tools (Select / Arm / Bonder / Erase)

struct MechToolRow: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        HStack(spacing: 8) {
            toolButton(.select) { SelectToolGlyph(color: $0) }
            if vm.puzzle.allowed.contains(.arm) { toolButton(.arm) { ArmToolGlyph(color: $0) } }
            if vm.puzzle.allowed.contains(.bonder) { toolButton(.bonder) { BonderToolGlyph(color: $0) } }
            toolButton(.erase) { EraseToolGlyph(color: $0) }
        }
        .opacity(vm.isSimActive ? 0.4 : 1)
        .disabled(vm.isSimActive)
    }

    private func toolButton<G: View>(_ t: EditTool, @ViewBuilder glyph: (Color) -> G) -> some View {
        let active = vm.tool == t
        let color = active ? GearPalette.navyDeep : GearPalette.ivory
        return Button { vm.tool = t } label: {
            VStack(spacing: 3) {
                glyph(color).frame(width: 20, height: 20)
                Text(t.name).font(.system(size: 10, weight: .bold)).foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(active ? GearPalette.copper : GearPalette.panel))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(GearPalette.line, lineWidth: active ? 0 : 1))
            .contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Simulation transport (Reset / Step / Run·Pause / Speed)

struct MechSimRow: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        HStack(spacing: 8) {
            // While a simulation is active, Reset is the clear way back to editing,
            // so highlight it; when idle it stays a quiet secondary control.
            simButton(label: vm.isSimActive ? "Reset · Edit" : "Reset",
                      fill: vm.isSimActive ? GearPalette.copper : GearPalette.panel,
                      textColor: vm.isSimActive ? GearPalette.navyDeep : GearPalette.ivory) {
                ResetGlyph(color: vm.isSimActive ? GearPalette.navyDeep : GearPalette.ivory).frame(width: 18, height: 18)
            } action: { vm.reset() }

            simButton(label: "Step", fill: GearPalette.panel, textColor: GearPalette.ivory) {
                StepGlyph(color: GearPalette.ivory).frame(width: 18, height: 18)
            } action: { vm.stepOnce() }

            if vm.phase == .running {
                simButton(label: "Pause", fill: GearPalette.copper, textColor: GearPalette.navyDeep) {
                    PauseGlyph(color: GearPalette.navyDeep).frame(width: 18, height: 18)
                } action: { vm.pause() }
            } else {
                simButton(label: "Run", fill: GearPalette.verdigris, textColor: GearPalette.ivory) {
                    PlayGlyph(color: GearPalette.ivory).frame(width: 18, height: 18)
                } action: { vm.run() }
            }

            Button { vm.cycleSpeed() } label: {
                VStack(spacing: 3) {
                    Text(vm.speedLabels[vm.speedIndex])
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(GearPalette.gold)
                    Text("Speed").font(.system(size: 10, weight: .bold)).foregroundColor(GearPalette.haze)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(GearPalette.panel))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GearPalette.line, lineWidth: 1))
                .contentShape(Rectangle())
            }.buttonStyle(PlainButtonStyle())
        }
    }

    private func simButton<G: View>(label: String, fill: Color, textColor: Color,
                                    @ViewBuilder glyph: () -> G, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                glyph()
                Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(fill))
            .contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
    }
}
