import SwiftUI

struct EditorView: View {
    let puzzle: Puzzle
    @EnvironmentObject var store: GameStore
    @StateObject private var vm: EditorViewModel
    @State private var showGoal = false

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        // store injected via environment; create VM with a temporary store reference resolved in onAppear-safe way.
        _vm = StateObject(wrappedValue: EditorViewModel(puzzle: puzzle, store: GameStore.shared))
    }

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack {
                GearPalette.navy.ignoresSafeArea()
                GearBackdrop().ignoresSafeArea()
                if landscape {
                    landscapeLayout(geo)
                } else {
                    portraitLayout(geo)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button { showGoal = true } label: {
                    HStack(spacing: 6) {
                        Text("\(puzzle.chapter)-\(puzzle.order)  \(puzzle.title)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(GearPalette.ivory)
                        InfoGlyph(color: GearPalette.copperBright).frame(width: 15, height: 15)
                    }
                }
            }
        }
        .sheet(isPresented: $showGoal) { GoalSheet(puzzle: puzzle).environmentObject(store) }
        .onAppear {
            // Auto-present the goal the first time each puzzle is opened (once).
            if !store.hasSeenGoal(puzzle.id) {
                store.markGoalSeen(puzzle.id)
                showGoal = true
            }
        }
        .onDisappear { vm.onDisappear() }
    }

    // MARK: Layouts

    private func portraitLayout(_ geo: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            ObjectiveBanner(puzzle: puzzle, vm: vm).padding(.horizontal, 10)
            EditorControls(vm: vm)
            boardArea(height: geo.size.height * 0.40)
            ScrollView { controlPanel.padding(.horizontal, 12).padding(.bottom, 12) }
        }
        .padding(.top, 6)
    }

    private func landscapeLayout(_ geo: GeometryProxy) -> some View {
        HStack(spacing: 10) {
            VStack(spacing: 8) {
                ObjectiveBanner(puzzle: puzzle, vm: vm)
                EditorControls(vm: vm)
                boardArea(height: geo.size.height - 150)
            }
            .frame(width: geo.size.width * 0.5)
            ScrollView { controlPanel.padding(.trailing, 10).padding(.bottom, 12) }
                .frame(width: geo.size.width * 0.5 - 10)
        }
        .padding(8)
    }

    private func boardArea(height: CGFloat) -> some View {
        GeometryReader { boardGeo in
            BoardCanvas(vm: vm, screenSize: boardGeo.size, showCoords: store.showGridCoords)
        }
        .frame(height: height)
        .background(RoundedRectangle(cornerRadius: 14).fill(GearPalette.panel.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(GearPalette.line, lineWidth: 1))
        .padding(.horizontal, 10)
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
            MetricsHUDView(vm: vm)
            ArmInspectorView(vm: vm)
            TapeEditorView(vm: vm)
        }
    }
}

// MARK: - Always-visible objective banner

/// Compact, always-on goal reminder at the top of the play screen: shows the
/// sink's target molecule + "× N" and a one-line description of the loop. When
/// no arm has been placed yet it also coaches the very first action.
struct ObjectiveBanner: View {
    let puzzle: Puzzle
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("BUILD")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(GearPalette.navyDeep)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(GearPalette.verdigris))
                ForEach(Array(puzzle.sinks.enumerated()), id: \.offset) { _, sink in
                    HStack(spacing: 4) {
                        ForEach(Array(sink.target.atoms.enumerated()), id: \.offset) { _, a in
                            AtomNodeView(element: a.element, size: 22)
                        }
                        Text("× \(sink.required)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(GearPalette.ivory)
                    }
                }
                Spacer(minLength: 0)
            }
            Text("Carry atoms from the copper inputs to the green output to build this.")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(GearPalette.haze)
                .fixedSize(horizontal: false, vertical: true)
            if !vm.hasArms {
                HStack(spacing: 6) {
                    ArmToolGlyph(color: GearPalette.copperBright).frame(width: 14, height: 14)
                    Text("Start: pick the Arm tool, then tap a grid cell next to a copper input.")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(GearPalette.copperBright)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GearPalette.panel)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(vm.hasArms ? GearPalette.line : GearPalette.copper.opacity(0.7), lineWidth: 1))
        )
    }
}

// MARK: - Arm inspector

struct ArmInspectorView: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        GearCard {
            if let arm = vm.selectedArm {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Selected Arm")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(GearPalette.ivory)
                        Spacer()
                        Button { vm.deleteSelectedArm() } label: {
                            HStack(spacing: 5) {
                                EraseToolGlyph(color: GearPalette.alert).frame(width: 14, height: 14)
                                Text("Remove").font(.system(size: 13, weight: .bold)).foregroundColor(GearPalette.alert)
                            }
                        }
                        .disabled(vm.isSimActive)
                        .opacity(vm.isSimActive ? 0.4 : 1)
                    }
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reach").font(.system(size: 12, weight: .bold)).foregroundColor(GearPalette.haze)
                            HStack(spacing: 8) {
                                stepperButton("-") { vm.setReach(arm.reach - 1) }
                                Text("\(arm.reach)")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(GearPalette.ivory).frame(minWidth: 22)
                                stepperButton("+") { vm.setReach(arm.reach + 1) }
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Start Facing").font(.system(size: 12, weight: .bold)).foregroundColor(GearPalette.haze)
                            HStack(spacing: 8) {
                                rotateButton(cw: false)
                                Text(facingName(arm.orientation))
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(GearPalette.copperBright).frame(minWidth: 54)
                                rotateButton(cw: true)
                            }
                        }
                        Spacer()
                    }
                    .opacity(vm.isSimActive ? 0.5 : 1)
                    .disabled(vm.isSimActive)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ArmToolGlyph(color: GearPalette.copperBright).frame(width: 18, height: 18)
                        Text(vm.hasArms ? "No Arm Selected" : "Place Your First Arm")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(GearPalette.ivory)
                    }
                    Text(vm.hasArms
                         ? "Tap an arm on the grid to select it and edit its reach, facing, and program below."
                         : "1. Tap the Arm tool above.\n2. Tap a grid cell next to a copper input.\n3. Tap the arm to program its looping tape, then press Run.")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func facingName(_ d: Dir) -> String {
        switch d { case .east: return "East"; case .south: return "South"; case .west: return "West"; case .north: return "North" }
    }

    private func stepperButton(_ s: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(s).font(.system(size: 20, weight: .black))
                .foregroundColor(GearPalette.navyDeep)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9).fill(GearPalette.copper))
        }.buttonStyle(PlainButtonStyle())
    }

    private func rotateButton(cw: Bool) -> some View {
        Button { vm.rotateSelected(cw: cw) } label: {
            InstructionGlyph(instruction: cw ? .rotateCW : .rotateCCW, color: GearPalette.navyDeep)
                .frame(width: 22, height: 22)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 9).fill(GearPalette.copper))
        }.buttonStyle(PlainButtonStyle())
    }
}

struct InfoGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                Circle().stroke(color, lineWidth: w * 0.1)
                Circle().fill(color).frame(width: w * 0.14, height: w * 0.14).offset(y: -h * 0.2)
                RoundedRectangle(cornerRadius: 1).fill(color).frame(width: w * 0.12, height: h * 0.34).offset(y: h * 0.1)
            }
        }
    }
}

// MARK: - Goal sheet

struct GoalSheet: View {
    let puzzle: Puzzle
    @EnvironmentObject var store: GameStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            GearPalette.navy.ignoresSafeArea()
            GearBackdrop().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GearSectionHeader(title: puzzle.title)
                    Text(puzzle.blurb)
                        .font(.system(size: 15, weight: .medium)).foregroundColor(GearPalette.ivory)
                        .fixedSize(horizontal: false, vertical: true)
                    GearCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Inputs").font(.system(size: 14, weight: .black)).foregroundColor(GearPalette.copperBright)
                            ForEach(Array(puzzle.dispensers.enumerated()), id: \.offset) { _, d in
                                HStack(spacing: 8) {
                                    ForEach(Array(d.molecule.atoms.enumerated()), id: \.offset) { _, a in
                                        AtomNodeView(element: a.element, size: 26)
                                    }
                                    Text("dispenser").font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                                }
                            }
                        }
                    }
                    GearCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Outputs").font(.system(size: 14, weight: .black)).foregroundColor(GearPalette.verdigris)
                            ForEach(Array(puzzle.sinks.enumerated()), id: \.offset) { _, s in
                                HStack(spacing: 8) {
                                    ForEach(Array(s.target.atoms.enumerated()), id: \.offset) { _, a in
                                        AtomNodeView(element: a.element, size: 26)
                                    }
                                    Text("× \(s.required)\(s.allowRotation ? "" : " · exact heading")")
                                        .font(.system(size: 13, weight: .bold)).foregroundColor(GearPalette.haze)
                                }
                            }
                        }
                    }
                    GearCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Targets for stars").font(.system(size: 14, weight: .black)).foregroundColor(GearPalette.gold)
                            Text("Solve it: 1 star").font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                            Text("Finish within \(puzzle.cycleBudget) cycles: speed star").font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                            Text("Build for \(puzzle.costBudget) cost or less: cost star").font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                        }
                    }
                    Button { presentationMode.wrappedValue.dismiss() } label: { Text("Close") }
                        .buttonStyle(GearButtonStyle())
                }
                .padding(18)
                .gearReadable()
            }
        }
        .preferredColorScheme(.dark)
    }
}
