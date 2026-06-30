import Foundation

// MARK: - Helpers for authoring puzzles with machine-checked reference solutions.
//
// Every builder constructs a Puzzle together with an author reference solution,
// then runs the REAL engine to discover the solving cycle count, which becomes
// the par/star budget. If a reference cannot solve, `referenceCycles` stays 0 and
// the validator will flag it.

func scaled(_ dir: Dir, _ n: Int) -> GridPos {
    GridPos(x: dir.vector.x * n, y: dir.vector.y * n)
}

/// Rotation tokens to turn from `from` orientation to `to` orientation (shorter way),
/// plus the reversing tokens to return.
private func rotationTokens(from: Dir, to: Dir) -> (out: [Instruction], back: [Instruction]) {
    let cw = (to.rawValue - from.rawValue + 4) % 4
    if cw == 0 { return ([], []) }
    if cw <= 2 {
        return (Array(repeating: .rotateCW, count: cw), Array(repeating: .rotateCCW, count: cw))
    } else {
        let ccw = 4 - cw
        return (Array(repeating: .rotateCCW, count: ccw), Array(repeating: .rotateCW, count: ccw))
    }
}

/// Finalize: run the reference solution through the engine to set budgets.
func finalizePuzzle(id: String, chapter: Int, order: Int, title: String, blurb: String,
                    width: Int, height: Int, walls: [GridPos],
                    dispensers: [DispenserDef], sinks: [SinkDef],
                    allowed: [MechanismKind], reference: SolutionModel,
                    cycleSlack: Int = 0) -> Puzzle {
    // Build a temporary puzzle to run the engine (budgets filled afterwards).
    let probe = Puzzle(id: id, chapter: chapter, order: order, title: title, blurb: blurb,
                       width: width, height: height, walls: walls,
                       dispensers: dispensers, sinks: sinks, allowed: allowed,
                       cycleBudget: 999999, costBudget: 999999, reference: reference)
    let sim = Simulation(puzzle: probe, solution: reference)
    let result = sim.run()
    let cycles = result.solved ? result.cycles : 0
    // Give the cycle (par) budget modest breathing room so a sensible — but not
    // perfectly optimal — solution can still earn the speed star. Cost stays tight.
    let budget = cycles > 0 ? Int((Double(cycles) * 1.3).rounded(.up)) + 2 + cycleSlack : 999999
    return Puzzle(id: id, chapter: chapter, order: order, title: title, blurb: blurb,
                  width: width, height: height, walls: walls,
                  dispensers: dispensers, sinks: sinks, allowed: allowed,
                  cycleBudget: budget,
                  costBudget: reference.cost,
                  reference: reference)
}

// MARK: Archetype: single-atom transport (rotate)

func makeTransport(id: String, chapter: Int, order: Int, title: String, blurb: String,
                   width: Int, height: Int, pivot: GridPos,
                   dispDir: Dir, sinkDir: Dir, reach: Int,
                   element: Element, count: Int, walls: [GridPos] = []) -> Puzzle {
    let dCell = pivot + scaled(dispDir, reach)
    let sCell = pivot + scaled(sinkDir, reach)
    let disp = DispenserDef(anchor: dCell, molecule: .single(element))
    let sink = SinkDef(anchor: sCell, target: .single(element), required: count)
    let rot = rotationTokens(from: dispDir, to: sinkDir)
    var tape: [Instruction] = [.grab]
    tape.append(contentsOf: rot.out)
    tape.append(.drop)
    tape.append(contentsOf: rot.back)
    let arm = ArmPlacement(id: 0, pivot: pivot, reach: reach, orientation: dispDir, tape: tape)
    return finalizePuzzle(id: id, chapter: chapter, order: order, title: title, blurb: blurb,
                          width: width, height: height, walls: walls,
                          dispensers: [disp], sinks: [sink],
                          allowed: [.arm], reference: SolutionModel(arms: [arm]))
}

// MARK: Archetype: transport using extend/retract (same direction, two reaches)

func makeExtendTransport(id: String, chapter: Int, order: Int, title: String, blurb: String,
                         width: Int, height: Int, pivot: GridPos, dir: Dir,
                         element: Element, count: Int, walls: [GridPos] = []) -> Puzzle {
    let dCell = pivot + scaled(dir, 1)  // grab at reach 1
    let sCell = pivot + scaled(dir, 2)  // deliver at reach 2
    let disp = DispenserDef(anchor: dCell, molecule: .single(element))
    let sink = SinkDef(anchor: sCell, target: .single(element), required: count)
    let tape: [Instruction] = [.grab, .extend, .drop, .retract]
    let arm = ArmPlacement(id: 0, pivot: pivot, reach: 1, orientation: dir, tape: tape)
    return finalizePuzzle(id: id, chapter: chapter, order: order, title: title, blurb: blurb,
                          width: width, height: height, walls: walls,
                          dispensers: [disp], sinks: [sink],
                          allowed: [.arm], reference: SolutionModel(arms: [arm]))
}

// MARK: Archetype: two sources -> two sinks (one arm, four reach positions)

func makeDualSort(id: String, chapter: Int, order: Int, title: String, blurb: String,
                  width: Int, height: Int, pivot: GridPos, reach: Int,
                  elemE: Element, elemW: Element, count: Int, walls: [GridPos] = []) -> Puzzle {
    // E = dispenser elemE, S = sink for elemE, W = dispenser elemW, N = sink for elemW
    let dispE = DispenserDef(anchor: pivot + scaled(.east, reach), molecule: .single(elemE))
    let sinkS = SinkDef(anchor: pivot + scaled(.south, reach), target: .single(elemE), required: count)
    let dispW = DispenserDef(anchor: pivot + scaled(.west, reach), molecule: .single(elemW))
    let sinkN = SinkDef(anchor: pivot + scaled(.north, reach), target: .single(elemW), required: count)
    // tape: grab(E) CW->S drop, CW->W grab CW->N drop, CW->E
    let tape: [Instruction] = [.grab, .rotateCW, .drop, .rotateCW, .grab, .rotateCW, .drop, .rotateCW]
    let arm = ArmPlacement(id: 0, pivot: pivot, reach: reach, orientation: .east, tape: tape)
    return finalizePuzzle(id: id, chapter: chapter, order: order, title: title, blurb: blurb,
                          width: width, height: height, walls: walls,
                          dispensers: [dispE, dispW], sinks: [sinkS, sinkN],
                          allowed: [.arm], reference: SolutionModel(arms: [arm]))
}

// MARK: Archetype: unified assembly / delivery
//
// A molecule occupies `cells` relative to the grabbed cell c1 (cells[0] must be (0,0)).
// c1 is the arm tip = pivot + reach*east. The reference grabs, rotates CW `turns` times,
// drops, then rotates back. Two supply modes:
//   .bonder    -> one dispenser per cell, all marked bonder (atoms bond on spawn)
//   .preBonded -> a single dispenser emits the whole molecule already bonded

enum SupplyMode { case bonder, preBonded }

func makeAssembly(id: String, chapter: Int, order: Int, title: String, blurb: String,
                  width: Int, height: Int, pivot: GridPos, reach: Int, turns: Int,
                  cells: [(GridPos, Element)], bonds: [(Int, Int)],
                  count: Int, mode: SupplyMode, allowRotation: Bool = true,
                  walls: [GridPos] = []) -> Puzzle {
    let c1 = pivot + scaled(.east, reach)
    var dispensers: [DispenserDef] = []
    var bonders: [GridPos] = []
    if mode == .bonder {
        for (off, elem) in cells {
            let cell = c1 + off
            dispensers.append(DispenserDef(anchor: cell, molecule: .single(elem)))
            bonders.append(cell)
        }
    } else {
        let atoms = cells.map { AtomSpec(offset: $0.0, element: $0.1) }
        dispensers.append(DispenserDef(anchor: c1, molecule: MoleculeSpec(atoms: atoms, bonds: bonds)))
    }
    // target = molecule rotated by `turns` quarter-turns, anchored at landed cell of atom0
    let sinkAnchor = pivot + rotateOffset(GridPos(x: reach, y: 0), quarterTurns: turns)
    let targetAtoms = cells.map { AtomSpec(offset: rotateOffset($0.0, quarterTurns: turns), element: $0.1) }
    let sink = SinkDef(anchor: sinkAnchor,
                       target: MoleculeSpec(atoms: targetAtoms, bonds: bonds),
                       required: count, allowRotation: allowRotation)
    var tape: [Instruction] = [.grab]
    tape.append(contentsOf: Array(repeating: .rotateCW, count: turns))
    tape.append(.drop)
    tape.append(contentsOf: Array(repeating: .rotateCCW, count: turns))
    let arm = ArmPlacement(id: 0, pivot: pivot, reach: reach, orientation: .east, tape: tape)
    let allowed: [MechanismKind] = mode == .bonder ? [.arm, .bonder] : [.arm]
    return finalizePuzzle(id: id, chapter: chapter, order: order, title: title, blurb: blurb,
                          width: width, height: height, walls: walls,
                          dispensers: dispensers, sinks: [sink], allowed: allowed,
                          reference: SolutionModel(arms: [arm], bonders: bonders))
}

// MARK: Archetype: merge two sources into one sink

func makeMerge(id: String, chapter: Int, order: Int, title: String, blurb: String,
               width: Int, height: Int, pivot: GridPos, reach: Int,
               element: Element, count: Int, walls: [GridPos] = []) -> Puzzle {
    // dispensers East and West; sink South. Even count.
    let dispE = DispenserDef(anchor: pivot + scaled(.east, reach), molecule: .single(element))
    let dispW = DispenserDef(anchor: pivot + scaled(.west, reach), molecule: .single(element))
    let sink = SinkDef(anchor: pivot + scaled(.south, reach), target: .single(element), required: count)
    // orient E: grab, CW->S drop, CW->W grab, CCW->S drop, CCW->E
    let tape: [Instruction] = [.grab, .rotateCW, .drop, .rotateCW, .grab, .rotateCCW, .drop, .rotateCCW]
    let arm = ArmPlacement(id: 0, pivot: pivot, reach: reach, orientation: .east, tape: tape)
    return finalizePuzzle(id: id, chapter: chapter, order: order, title: title, blurb: blurb,
                          width: width, height: height, walls: walls,
                          dispensers: [dispE, dispW], sinks: [sink],
                          allowed: [.arm], reference: SolutionModel(arms: [arm]))
}

// MARK: Archetype: bond two atoms (adjacent dispensers + bonder), deliver pair

func makeBondPair(id: String, chapter: Int, order: Int, title: String, blurb: String,
                  width: Int, height: Int, pivot: GridPos, reach: Int,
                  elemMain: Element, elemSide: Element, count: Int, walls: [GridPos] = []) -> Puzzle {
    // DA at tip (east), elemMain; DB south-adjacent to DA, elemSide. Bonders on both.
    let c1 = pivot + scaled(.east, reach)            // main atom, grabbed
    let c2 = GridPos(x: c1.x, y: c1.y + 1)           // side atom, south of c1
    let dispA = DispenserDef(anchor: c1, molecule: .single(elemMain))
    let dispB = DispenserDef(anchor: c2, molecule: .single(elemSide))
    // After grab + rotateCW: main -> pivot+south*reach (call Sa); side rotates around pivot:
    // side rel (reach, 1) -> rotateCW (-1, reach); abs = pivot + (-1, reach)
    let sinkAnchor = pivot + scaled(.south, reach)   // main lands here
    // target canonical: atom0 main at (0,0), atom1 side at (-1,0), bond(0,1)
    let target = MoleculeSpec(atoms: [AtomSpec(offset: GridPos(x: 0, y: 0), element: elemMain),
                                      AtomSpec(offset: GridPos(x: -1, y: 0), element: elemSide)],
                              bonds: [(0, 1)])
    let sink = SinkDef(anchor: sinkAnchor, target: target, required: count)
    let tape: [Instruction] = [.grab, .rotateCW, .drop, .rotateCCW]
    let arm = ArmPlacement(id: 0, pivot: pivot, reach: reach, orientation: .east, tape: tape)
    return finalizePuzzle(id: id, chapter: chapter, order: order, title: title, blurb: blurb,
                          width: width, height: height, walls: walls,
                          dispensers: [dispA, dispB], sinks: [sink],
                          allowed: [.arm, .bonder],
                          reference: SolutionModel(arms: [arm], bonders: [c1, c2]))
}
