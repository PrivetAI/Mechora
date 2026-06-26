import SwiftUI
import Foundation

enum EditTool: Int, CaseIterable {
    case select, arm, bonder, erase
    var name: String {
        switch self {
        case .select: return "Select"
        case .arm: return "Arm"
        case .bonder: return "Bonder"
        case .erase: return "Erase"
        }
    }
}

enum SimPhase: Equatable {
    case idle
    case running
    case paused
    case solved
    case failed(String)
}

final class EditorViewModel: ObservableObject {
    let puzzle: Puzzle
    private weak var store: GameStore?

    @Published var solution: SolutionModel
    @Published var tool: EditTool = .arm
    @Published var selectedArmId: Int? = nil
    @Published var phase: SimPhase = .idle
    @Published var speedIndex: Int = 0       // 0=1x, 1=2x, 2=4x
    @Published var statusText: String = "Build your machine, then press Run."
    @Published private(set) var simTick: Int = 0
    @Published private(set) var delivered: [Int] = []
    @Published var refreshToken: Int = 0      // bump to force canvas redraw during sim

    private(set) var sim: Simulation? = nil
    private var timer: Timer?
    private var nextArmId = 0

    let speeds: [Double] = [0.45, 0.25, 0.13]
    let speedLabels = ["1x", "2x", "4x"]

    init(puzzle: Puzzle, store: GameStore) {
        self.puzzle = puzzle
        self.store = store
        if let saved = store.solution(for: puzzle.id) {
            self.solution = saved
        } else {
            self.solution = SolutionModel()
        }
        self.delivered = Array(repeating: 0, count: puzzle.sinks.count)
        self.nextArmId = (solution.arms.map { $0.id }.max() ?? -1) + 1
        if let first = solution.arms.first { selectedArmId = first.id }
        if solution.arms.isEmpty { tool = .arm } else { tool = .select }
    }

    // MARK: Selected arm

    var selectedArm: ArmPlacement? {
        guard let id = selectedArmId else { return nil }
        return solution.arms.first { $0.id == id }
    }

    private func updateSelectedArm(_ transform: (inout ArmPlacement) -> Void) {
        guard let id = selectedArmId, let idx = solution.arms.firstIndex(where: { $0.id == id }) else { return }
        transform(&solution.arms[idx])
        persist()
    }

    // MARK: Editing

    var isSimActive: Bool { sim != nil }

    private func mechanismOccupies(_ cell: GridPos) -> Bool {
        if solution.arms.contains(where: { $0.pivot == cell }) { return true }
        return false
    }

    private func isBlockedForArm(_ cell: GridPos) -> Bool {
        if cell.x < 0 || cell.x >= puzzle.width || cell.y < 0 || cell.y >= puzzle.height { return true }
        if puzzle.wallSet.contains(cell) { return true }
        if puzzle.dispensers.contains(where: { $0.footprint.contains(cell) }) { return true }
        if puzzle.sinks.contains(where: { sink in sink.target.atoms.contains(where: { sink.anchor + $0.offset == cell }) }) { return true }
        return false
    }

    func tapCell(_ cell: GridPos) {
        guard !isSimActive else { return }   // must reset before editing
        switch tool {
        case .select:
            if let arm = solution.arms.first(where: { $0.pivot == cell }) {
                selectedArmId = arm.id
            }
        case .arm:
            guard puzzle.allowed.contains(.arm) else { statusText = "Arms are not available here."; return }
            if mechanismOccupies(cell) {
                if let arm = solution.arms.first(where: { $0.pivot == cell }) { selectedArmId = arm.id }
                return
            }
            if isBlockedForArm(cell) { statusText = "Cannot place an arm there."; return }
            let arm = ArmPlacement(id: nextArmId, pivot: cell, reach: 1, orientation: .east,
                                   tape: [.grab, .rotateCW, .drop, .rotateCCW])
            nextArmId += 1
            solution.arms.append(arm)
            selectedArmId = arm.id
            persist()
        case .bonder:
            guard puzzle.allowed.contains(.bonder) else { statusText = "Bonders are not available here."; return }
            if cell.x < 0 || cell.x >= puzzle.width || cell.y < 0 || cell.y >= puzzle.height { return }
            if puzzle.wallSet.contains(cell) { return }
            if let idx = solution.bonders.firstIndex(of: cell) {
                solution.bonders.remove(at: idx)
            } else {
                solution.bonders.append(cell)
            }
            persist()
        case .erase:
            if let idx = solution.arms.firstIndex(where: { $0.pivot == cell }) {
                let removedId = solution.arms[idx].id
                solution.arms.remove(at: idx)
                if selectedArmId == removedId { selectedArmId = solution.arms.first?.id }
            } else if let idx = solution.bonders.firstIndex(of: cell) {
                solution.bonders.remove(at: idx)
            }
            persist()
        }
    }

    // MARK: Selected-arm controls

    func setReach(_ r: Int) { updateSelectedArm { $0.reach = max(1, min(3, r)) } }
    func rotateSelected(cw: Bool) {
        updateSelectedArm { $0.orientation = cw ? $0.orientation.rotatedCW : $0.orientation.rotatedCCW }
    }
    func appendInstruction(_ ins: Instruction) { updateSelectedArm { $0.tape.append(ins) } }
    func removeInstruction(at index: Int) {
        updateSelectedArm { if index >= 0 && index < $0.tape.count { $0.tape.remove(at: index) } }
    }
    func moveInstruction(at index: Int, by delta: Int) {
        updateSelectedArm {
            let new = index + delta
            guard index >= 0, index < $0.tape.count, new >= 0, new < $0.tape.count else { return }
            $0.tape.swapAt(index, new)
        }
    }
    func clearTape() { updateSelectedArm { $0.tape.removeAll() } }
    func deleteSelectedArm() {
        guard let id = selectedArmId, let idx = solution.arms.firstIndex(where: { $0.id == id }) else { return }
        solution.arms.remove(at: idx)
        selectedArmId = solution.arms.first?.id
        persist()
    }

    private func persist() { store?.storeWorkingSolution(solution, for: puzzle.id) }

    // MARK: Simulation

    private func ensureSim() -> Bool {
        if sim != nil { return true }
        guard !solution.arms.isEmpty else {
            statusText = "Place at least one arm first."
            phase = .idle
            return false
        }
        sim = Simulation(puzzle: puzzle, solution: solution)
        simTick = 0
        delivered = Array(repeating: 0, count: puzzle.sinks.count)
        didRecordSolve = false
        store?.incrementRuns()
        return true
    }

    func stepOnce() {
        stopTimer()
        guard ensureSim() else { return }
        guard let s = sim, s.status == .running else { return }
        s.step()
        syncFromSim()
        phase = phaseFor(s)
        refreshToken &+= 1
    }

    func run() {
        guard ensureSim() else { return }
        guard let s = sim else { return }
        if s.status != .running { return }
        phase = .running
        startTimer()
    }

    func pause() {
        stopTimer()
        if let s = sim, s.status == .running { phase = .paused }
    }

    func reset() {
        stopTimer()
        sim = nil
        simTick = 0
        delivered = Array(repeating: 0, count: puzzle.sinks.count)
        phase = .idle
        statusText = "Build your machine, then press Run."
        refreshToken &+= 1
    }

    func cycleSpeed() {
        speedIndex = (speedIndex + 1) % speeds.count
        if phase == .running { startTimer() }
    }

    private func startTimer() {
        stopTimer()
        let interval = speeds[speedIndex]
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tickFromTimer()
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func tickFromTimer() {
        guard let s = sim else { stopTimer(); return }
        guard s.status == .running else { stopTimer(); phase = phaseFor(s); return }
        s.step()
        syncFromSim()
        refreshToken &+= 1
        if s.status != .running {
            stopTimer()
            phase = phaseFor(s)
        }
    }

    private func syncFromSim() {
        guard let s = sim else { return }
        simTick = s.tick
        delivered = s.delivered
    }

    private func phaseFor(_ s: Simulation) -> SimPhase {
        switch s.status {
        case .running: return .running
        case .solved:
            handleSolved()
            return .solved
        case .failed(let r): return .failed(r)
        }
    }

    private var didRecordSolve = false
    private func handleSolved() {
        guard let s = sim, !didRecordSolve else { return }
        didRecordSolve = true
        let stars = store?.recordSolve(puzzle: puzzle,
                                       cycles: s.tick,
                                       cost: solution.cost,
                                       area: solution.area,
                                       instr: solution.instructionCount) ?? 0
        statusText = "Solved in \(s.tick) cycles · \(stars) star\(stars == 1 ? "" : "s")"
    }

    func onDisappear() {
        stopTimer()
        persist()
    }

    // MARK: Rendering helpers

    /// Atoms to draw: live sim atoms, or a static preview of dispenser contents.
    func renderAtoms() -> [(GridPos, Element, Bool)] {
        if let s = sim {
            return s.atoms.values.map { ($0.pos, $0.element, false) }
        }
        var preview: [(GridPos, Element, Bool)] = []
        for d in puzzle.dispensers {
            for a in d.molecule.atoms {
                preview.append((d.anchor + a.offset, a.element, true))
            }
        }
        return preview
    }

    func renderBonds() -> [(GridPos, GridPos)] {
        guard let s = sim else {
            // preview internal dispenser bonds
            var out: [(GridPos, GridPos)] = []
            for d in puzzle.dispensers {
                for (i, j) in d.molecule.bonds {
                    out.append((d.anchor + d.molecule.atoms[i].offset, d.anchor + d.molecule.atoms[j].offset))
                }
            }
            return out
        }
        var out: [(GridPos, GridPos)] = []
        for b in s.bonds {
            if let pa = s.atomById(b.a), let pb = s.atomById(b.b) { out.append((pa, pb)) }
        }
        return out
    }

    struct ArmRender { let pivot: GridPos; let tip: GridPos; let reach: Int; let id: Int; let holding: Bool }

    func renderArms() -> [ArmRender] {
        if let s = sim {
            return s.arms.enumerated().map { (i, a) in
                ArmRender(pivot: a.pivot, tip: a.tip, reach: a.reach,
                          id: solution.arms.indices.contains(i) ? solution.arms[i].id : i,
                          holding: a.anchor != nil)
            }
        }
        return solution.arms.map { arm in
            let tip = GridPos(x: arm.pivot.x + arm.orientation.vector.x * arm.reach,
                              y: arm.pivot.y + arm.orientation.vector.y * arm.reach)
            return ArmRender(pivot: arm.pivot, tip: tip, reach: arm.reach, id: arm.id, holding: false)
        }
    }
}
