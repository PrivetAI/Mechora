import Foundation

// MARK: - Runtime atom & bond

struct RuntimeAtom {
    var pos: GridPos
    let element: Element
}

struct Bond: Hashable {
    let a: Int
    let b: Int
    init(_ x: Int, _ y: Int) { a = min(x, y); b = max(x, y) }
}

struct ArmRuntime {
    var pivot: GridPos
    var reach: Int
    var orientation: Dir
    var tape: [Instruction]
    var ptr: Int = 0
    var anchor: Int? = nil          // grabbed atom id (component representative)
    var trackPath: [GridPos]?
    var trackIndex: Int = 0

    var tip: GridPos {
        GridPos(x: pivot.x + orientation.vector.x * reach,
                y: pivot.y + orientation.vector.y * reach)
    }
}

enum SimStatus: Equatable {
    case running
    case solved
    case failed(String)
}

// MARK: - Run result (for validation & metrics)

struct RunResult {
    let solved: Bool
    let cycles: Int
    let failureReason: String?
}

// MARK: - The deterministic tick simulation engine

final class Simulation {
    let puzzle: Puzzle
    let bonderSet: Set<GridPos>

    private(set) var atoms: [Int: RuntimeAtom] = [:]
    private(set) var bonds: Set<Bond> = []
    private(set) var arms: [ArmRuntime] = []
    private(set) var delivered: [Int]
    private(set) var status: SimStatus = .running
    private(set) var tick: Int = 0

    private var nextAtomId = 1
    let tickCap: Int

    init(puzzle: Puzzle, solution: SolutionModel, tickCap: Int = 4000) {
        self.puzzle = puzzle
        self.bonderSet = Set(solution.bonders)
        self.tickCap = tickCap
        self.delivered = Array(repeating: 0, count: puzzle.sinks.count)

        for placement in solution.arms {
            var rt = ArmRuntime(pivot: placement.pivot,
                                reach: max(1, min(3, placement.reach)),
                                orientation: placement.orientation,
                                tape: placement.tape,
                                trackPath: placement.trackPath)
            if let path = placement.trackPath, let idx = path.firstIndex(of: placement.pivot) {
                rt.trackIndex = idx
            }
            arms.append(rt)
        }
    }

    // MARK: Queries

    func atomId(at pos: GridPos) -> Int? {
        for (id, atom) in atoms where atom.pos == pos { return id }
        return nil
    }

    func atomById(_ id: Int) -> GridPos? { atoms[id]?.pos }

    private func componentOf(_ atomId: Int) -> Set<Int> {
        var seen: Set<Int> = [atomId]
        var stack = [atomId]
        while let cur = stack.popLast() {
            for bond in bonds {
                if bond.a == cur, !seen.contains(bond.b) { seen.insert(bond.b); stack.append(bond.b) }
                if bond.b == cur, !seen.contains(bond.a) { seen.insert(bond.a); stack.append(bond.a) }
            }
        }
        return seen
    }

    private func heldByOthers(excluding index: Int) -> Set<Int> {
        var held: Set<Int> = []
        for (i, arm) in arms.enumerated() where i != index {
            if let anchor = arm.anchor, atoms[anchor] != nil {
                held.formUnion(componentOf(anchor))
            }
        }
        return held
    }

    private var allHeld: Set<Int> {
        var held: Set<Int> = []
        for arm in arms {
            if let anchor = arm.anchor, atoms[anchor] != nil {
                held.formUnion(componentOf(anchor))
            }
        }
        return held
    }

    // MARK: Tick

    func step() {
        guard status == .running else { return }

        spawnPhase()
        for i in arms.indices { execute(armIndex: i) }
        bondingPhase()
        consumePhase()

        if let err = validate() {
            status = .failed(err)
            return
        }

        for i in arms.indices where !arms[i].tape.isEmpty {
            arms[i].ptr = (arms[i].ptr + 1) % arms[i].tape.count
        }
        tick += 1

        if delivered.indices.allSatisfy({ delivered[$0] >= puzzle.sinks[$0].required }) {
            status = .solved
            return
        }
        if tick >= tickCap {
            status = .failed("Tick cap (\(tickCap)) reached without solving.")
        }
    }

    private func spawnPhase() {
        for disp in puzzle.dispensers {
            let footprint = disp.footprint
            let occupied = footprint.contains { atomId(at: $0) != nil }
            if occupied { continue }
            var ids: [Int] = []
            for spec in disp.molecule.atoms {
                let id = nextAtomId; nextAtomId += 1
                atoms[id] = RuntimeAtom(pos: disp.anchor + spec.offset, element: spec.element)
                ids.append(id)
            }
            for (i, j) in disp.molecule.bonds {
                if i < ids.count, j < ids.count { bonds.insert(Bond(ids[i], ids[j])) }
            }
        }
    }

    private func execute(armIndex i: Int) {
        let instr = arms[i].tape.isEmpty ? Instruction.wait : arms[i].tape[arms[i].ptr]
        switch instr {
        case .grab:
            if arms[i].anchor == nil {
                if let target = atomId(at: arms[i].tip) {
                    let comp = componentOf(target)
                    if comp.isDisjoint(with: heldByOthers(excluding: i)) {
                        arms[i].anchor = target
                    }
                }
            }
        case .drop:
            arms[i].anchor = nil
        case .rotateCW:
            arms[i].orientation = arms[i].orientation.rotatedCW
            transformHeld(armIndex: i) { rotateCW($0) }
        case .rotateCCW:
            arms[i].orientation = arms[i].orientation.rotatedCCW
            transformHeld(armIndex: i) { rotateCCW($0) }
        case .extend:
            if arms[i].reach < 3 {
                let delta = arms[i].orientation.vector
                arms[i].reach += 1
                translateHeld(armIndex: i, by: delta)
            }
        case .retract:
            if arms[i].reach > 1 {
                let delta = GridPos(x: -arms[i].orientation.vector.x, y: -arms[i].orientation.vector.y)
                arms[i].reach -= 1
                translateHeld(armIndex: i, by: delta)
            }
        case .trackForward:
            moveTrack(armIndex: i, step: 1)
        case .trackBackward:
            moveTrack(armIndex: i, step: -1)
        case .wait:
            break
        }
    }

    /// Rotate held component around the arm pivot.
    private func transformHeld(armIndex i: Int, _ rot: (GridPos) -> GridPos) {
        guard let anchor = arms[i].anchor, atoms[anchor] != nil else { return }
        let pivot = arms[i].pivot
        for id in componentOf(anchor) {
            guard var atom = atoms[id] else { continue }
            let rel = atom.pos - pivot
            let newRel = rot(rel)
            atom.pos = pivot + newRel
            atoms[id] = atom
        }
    }

    private func translateHeld(armIndex i: Int, by delta: GridPos) {
        guard let anchor = arms[i].anchor, atoms[anchor] != nil else { return }
        for id in componentOf(anchor) {
            guard var atom = atoms[id] else { continue }
            atom.pos = atom.pos + delta
            atoms[id] = atom
        }
    }

    private func moveTrack(armIndex i: Int, step: Int) {
        guard let path = arms[i].trackPath, !path.isEmpty else { return }
        let newIndex = arms[i].trackIndex + step
        guard newIndex >= 0, newIndex < path.count else { return }
        let delta = path[newIndex] - path[arms[i].trackIndex]
        arms[i].trackIndex = newIndex
        arms[i].pivot = path[newIndex]
        translateHeld(armIndex: i, by: delta)
    }

    private func bondingPhase() {
        guard !bonderSet.isEmpty else { return }
        for cell in bonderSet {
            guard let a = atomId(at: cell) else { continue }
            // bond with east and south neighbours (covers all pairs once)
            for neighbour in [GridPos(x: cell.x + 1, y: cell.y), GridPos(x: cell.x, y: cell.y + 1)] {
                guard bonderSet.contains(neighbour), let b = atomId(at: neighbour) else { continue }
                bonds.insert(Bond(a, b))
            }
        }
    }

    private func consumePhase() {
        let held = allHeld
        for (sinkIndex, sink) in puzzle.sinks.enumerated() {
            if delivered[sinkIndex] >= sink.required { continue }
            let rotations = sink.allowRotation ? [0, 1, 2, 3] : [0]
            for q in rotations {
                if tryConsume(sink: sink, quarterTurns: q, held: held) {
                    delivered[sinkIndex] += 1
                    break
                }
            }
        }
    }

    private func tryConsume(sink: SinkDef, quarterTurns q: Int, held: Set<Int>) -> Bool {
        var matchedIds: [Int] = []
        for spec in sink.target.atoms {
            let cell = sink.anchor + rotateOffset(spec.offset, quarterTurns: q)
            guard let id = atomId(at: cell), let atom = atoms[id] else { return false }
            if atom.element != spec.element { return false }
            if held.contains(id) { return false }
            matchedIds.append(id)
        }
        // matched atoms must form EXACTLY one connected component (no extra atoms attached)
        let idSet = Set(matchedIds)
        guard let first = matchedIds.first else { return false }
        if componentOf(first) != idSet { return false }
        // verify internal bonds of the target are present
        for (i, j) in sink.target.bonds {
            if i < matchedIds.count, j < matchedIds.count {
                if !bonds.contains(Bond(matchedIds[i], matchedIds[j])) { return false }
            }
        }
        // consume
        for id in matchedIds {
            atoms.removeValue(forKey: id)
            bonds = bonds.filter { $0.a != id && $0.b != id }
        }
        return true
    }

    private func validate() -> String? {
        var seen: [GridPos: Int] = [:]
        let walls = puzzle.wallSet
        for (_, atom) in atoms {
            let p = atom.pos
            if p.x < 0 || p.x >= puzzle.width || p.y < 0 || p.y >= puzzle.height {
                return "A part was pushed off the board."
            }
            if walls.contains(p) {
                return "A part collided with a wall."
            }
            if let prev = seen[p], prev != 0 {
                return "Two parts collided in the same cell."
            }
            seen[p, default: 0] += 1
            if seen[p]! > 1 { return "Two parts collided in the same cell." }
        }
        return nil
    }

    // MARK: Full run (used by validator & metric evaluation)

    func run() -> RunResult {
        while status == .running { step() }
        switch status {
        case .solved: return RunResult(solved: true, cycles: tick, failureReason: nil)
        case .failed(let r): return RunResult(solved: false, cycles: tick, failureReason: r)
        case .running: return RunResult(solved: false, cycles: tick, failureReason: "Did not terminate")
        }
    }
}
