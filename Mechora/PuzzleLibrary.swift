import Foundation

private func g(_ x: Int, _ y: Int) -> GridPos { GridPos(x: x, y: y) }

/// All hand-authored puzzles. Each is built with a machine-checked reference
/// solution; cycle/cost budgets are derived from running that reference.
enum PuzzleLibrary {

    static let all: [Puzzle] = buildAll()

    static func puzzle(id: String) -> Puzzle? { all.first { $0.id == id } }

    static func chapter(_ n: Int) -> [Puzzle] { all.filter { $0.chapter == n }.sorted { $0.order < $1.order } }

    static let chapterTitles: [Int: String] = [
        1: "Transit Bay",
        2: "Sorting Floor",
        3: "Bonding Bench",
        4: "Molecule Forge",
        5: "Orientation Jig",
        6: "Production Wing"
    ]

    static let chapterBlurbs: [Int: String] = [
        1: "Learn the arm: grab a part and place it on the sink.",
        2: "Route two element streams to the right outputs.",
        3: "Fuse two atoms with a bonder, then deliver the pair.",
        4: "Assemble chains and branches of three and four atoms.",
        5: "Deliver pre-built molecules in the exact required heading.",
        6: "High-volume lines. Tighten cycles and cost."
    ]

    private static func buildAll() -> [Puzzle] {
        var p: [Puzzle] = []

        // ===== Chapter 1 — single-atom transport =====
        p.append(makeTransport(id: "1-1", chapter: 1, order: 1, title: "First Delivery",
            blurb: "Grab the Alpha part and lower it onto the sink. Deliver 3.",
            width: 9, height: 9, pivot: g(4, 4), dispDir: .east, sinkDir: .south, reach: 2, element: .alpha, count: 3))
        p.append(makeTransport(id: "1-2", chapter: 1, order: 2, title: "Lift and Place",
            blurb: "Carry the Beta part up to the northern sink. Deliver 3.",
            width: 9, height: 9, pivot: g(4, 4), dispDir: .east, sinkDir: .north, reach: 2, element: .beta, count: 3))
        p.append(makeExtendTransport(id: "1-3", chapter: 1, order: 3, title: "Reach Out",
            blurb: "Use Extend to push the part one cell further before dropping. Deliver 3.",
            width: 9, height: 9, pivot: g(2, 4), dir: .east, element: .gamma, count: 3))
        p.append(makeTransport(id: "1-4", chapter: 1, order: 4, title: "The Long Way",
            blurb: "The sink sits opposite the dispenser. Half-turn the part across. Deliver 4.",
            width: 9, height: 9, pivot: g(4, 4), dispDir: .east, sinkDir: .west, reach: 2, element: .delta, count: 4))
        p.append(makeTransport(id: "1-5", chapter: 1, order: 5, title: "Across the Bench",
            blurb: "A long reach arm spans the whole bench. Deliver 3.",
            width: 11, height: 11, pivot: g(5, 5), dispDir: .north, sinkDir: .south, reach: 3, element: .alpha, count: 3))
        p.append(makeTransport(id: "1-6", chapter: 1, order: 6, title: "Quick Hands",
            blurb: "A short reach arm makes a tight quarter-turn. Deliver 5.",
            width: 7, height: 7, pivot: g(3, 3), dispDir: .east, sinkDir: .south, reach: 1, element: .epsilon, count: 5))
        p.append(makeExtendTransport(id: "1-7", chapter: 1, order: 7, title: "Drop Low",
            blurb: "Extend downward to reach the lower sink. Deliver 4.",
            width: 9, height: 9, pivot: g(4, 2), dir: .south, element: .beta, count: 4))
        p.append(makeTransport(id: "1-8", chapter: 1, order: 8, title: "Full Sweep",
            blurb: "A maximum reach arm runs the part the long way round. Deliver 5.",
            width: 11, height: 11, pivot: g(5, 5), dispDir: .east, sinkDir: .west, reach: 3, element: .gamma, count: 5))

        // ===== Chapter 2 — two-atom delivery + ordering =====
        p.append(makeDualSort(id: "2-1", chapter: 2, order: 1, title: "Twin Lines",
            blurb: "Alpha to the south sink, Beta to the north sink. Deliver 2 of each.",
            width: 9, height: 9, pivot: g(4, 4), reach: 2, elemE: .alpha, elemW: .beta, count: 2))
        p.append(makeDualSort(id: "2-2", chapter: 2, order: 2, title: "Parallel Output",
            blurb: "Keep both streams flowing. Deliver 3 of each.",
            width: 9, height: 9, pivot: g(4, 4), reach: 2, elemE: .gamma, elemW: .delta, count: 3))
        p.append(makeMerge(id: "2-3", chapter: 2, order: 3, title: "Convergence",
            blurb: "Two dispensers, one sink. Feed both into it. Deliver 6.",
            width: 9, height: 9, pivot: g(4, 4), reach: 2, element: .alpha, count: 6))
        p.append(makeDualSort(id: "2-4", chapter: 2, order: 4, title: "Wide Sort",
            blurb: "A long-reach sorter handling two elements. Deliver 2 of each.",
            width: 13, height: 13, pivot: g(6, 6), reach: 3, elemE: .alpha, elemW: .epsilon, count: 2))
        p.append(makeMerge(id: "2-5", chapter: 2, order: 5, title: "Steady Feed",
            blurb: "Merge two Gamma streams into a single output. Deliver 8.",
            width: 9, height: 9, pivot: g(4, 4), reach: 2, element: .gamma, count: 8))
        p.append(makeTransport(id: "2-6", chapter: 2, order: 6, title: "High Demand",
            blurb: "One line, heavy quota. Deliver 8 Delta parts.",
            width: 9, height: 9, pivot: g(4, 4), dispDir: .east, sinkDir: .south, reach: 2, element: .delta, count: 8))
        p.append(makeDualSort(id: "2-7", chapter: 2, order: 7, title: "Balanced Run",
            blurb: "Two outputs running together. Deliver 4 of each.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, elemE: .beta, elemW: .gamma, count: 4))
        p.append(makeDualSort(id: "2-8", chapter: 2, order: 8, title: "Master Sort",
            blurb: "A demanding sort of two elements. Deliver 5 of each.",
            width: 13, height: 13, pivot: g(6, 6), reach: 3, elemE: .epsilon, elemW: .delta, count: 5))

        // ===== Chapter 3 — bond two atoms =====
        p.append(makeAssembly(id: "3-1", chapter: 3, order: 1, title: "First Bond",
            blurb: "Place a bonder between the two dispensers so the atoms fuse, then deliver the pair. Deliver 2.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta)], bonds: [(0, 1)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "3-2", chapter: 3, order: 2, title: "Side by Side",
            blurb: "Bond a horizontal pair and carry it over. Deliver 2.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, turns: 1,
            cells: [(g(0, 0), .gamma), (g(1, 0), .delta)], bonds: [(0, 1)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "3-3", chapter: 3, order: 3, title: "Half Turn Bond",
            blurb: "Bond the pair, then swing it a half-turn to the far sink. Deliver 2.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, turns: 2,
            cells: [(g(0, 0), .alpha), (g(0, 1), .gamma)], bonds: [(0, 1)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "3-4", chapter: 3, order: 4, title: "Steady Pair",
            blurb: "Keep the bonded pairs coming. Deliver 3.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, turns: 1,
            cells: [(g(0, 0), .gamma), (g(0, 1), .delta)], bonds: [(0, 1)], count: 3, mode: .bonder))
        p.append(makeAssembly(id: "3-5", chapter: 3, order: 5, title: "Matched Pair",
            blurb: "Two atoms of the same element, fused. Deliver 2.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, turns: 1,
            cells: [(g(0, 0), .epsilon), (g(0, 1), .epsilon)], bonds: [(0, 1)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "3-6", chapter: 3, order: 6, title: "Reverse Bond",
            blurb: "Bond, then take the three-quarter route to the sink. Deliver 2.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, turns: 3,
            cells: [(g(0, 0), .beta), (g(0, 1), .gamma)], bonds: [(0, 1)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "3-7", chapter: 3, order: 7, title: "Bonded Cargo",
            blurb: "Bond a mixed pair and ship it. Deliver 3.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, turns: 1,
            cells: [(g(0, 0), .epsilon), (g(0, 1), .alpha)], bonds: [(0, 1)], count: 3, mode: .bonder))
        p.append(makeAssembly(id: "3-8", chapter: 3, order: 8, title: "Cross Bench",
            blurb: "Bond a horizontal pair and run it across the bench. Deliver 3.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, turns: 2,
            cells: [(g(0, 0), .alpha), (g(1, 0), .beta)], bonds: [(0, 1)], count: 3, mode: .bonder))

        // ===== Chapter 4 — three & four atom molecules =====
        p.append(makeAssembly(id: "4-1", chapter: 4, order: 1, title: "Triple Chain",
            blurb: "Bond three atoms into a chain and deliver it. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(0, 2), .gamma)], bonds: [(0, 1), (1, 2)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "4-2", chapter: 4, order: 2, title: "Triplet",
            blurb: "Three identical atoms, fused in a line. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .delta), (g(0, 1), .delta), (g(0, 2), .delta)], bonds: [(0, 1), (1, 2)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "4-3", chapter: 4, order: 3, title: "The Elbow",
            blurb: "Assemble an L-shaped molecule. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(1, 1), .gamma)], bonds: [(0, 1), (1, 2)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "4-4", chapter: 4, order: 4, title: "Quad Chain",
            blurb: "Bond a four-atom chain. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(0, 2), .gamma), (g(0, 3), .delta)], bonds: [(0, 1), (1, 2), (2, 3)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "4-5", chapter: 4, order: 5, title: "Branch Unit",
            blurb: "A branched molecule with a side atom. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(1, 1), .gamma), (g(0, 2), .delta)], bonds: [(0, 1), (1, 2), (1, 3)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "4-6", chapter: 4, order: 6, title: "Long Arm",
            blurb: "A horizontal three-atom bar. Deliver 2.",
            width: 13, height: 13, pivot: g(5, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .gamma), (g(1, 0), .beta), (g(2, 0), .alpha)], bonds: [(0, 1), (1, 2)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "4-7", chapter: 4, order: 7, title: "The Block",
            blurb: "Fuse a two-by-two square block. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(1, 0), .beta), (g(0, 1), .gamma), (g(1, 1), .delta)],
            bonds: [(0, 1), (0, 2), (1, 3), (2, 3)], count: 2, mode: .bonder))
        p.append(makeAssembly(id: "4-8", chapter: 4, order: 8, title: "Alternating Rod",
            blurb: "A four-atom rod of alternating elements. Deliver 3.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(0, 2), .alpha), (g(0, 3), .beta)], bonds: [(0, 1), (1, 2), (2, 3)], count: 3, mode: .bonder))

        // ===== Chapter 5 — orientation matching (rotation-locked sinks) =====
        p.append(makeAssembly(id: "5-1", chapter: 5, order: 1, title: "Orient North",
            blurb: "The dispenser hands you a finished pair. The sink only accepts one heading. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta)], bonds: [(0, 1)], count: 2, mode: .preBonded, allowRotation: false))
        p.append(makeAssembly(id: "5-2", chapter: 5, order: 2, title: "Flip It",
            blurb: "Rotate the pre-built pair a half-turn to match the sink. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 2,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta)], bonds: [(0, 1)], count: 2, mode: .preBonded, allowRotation: false))
        p.append(makeAssembly(id: "5-3", chapter: 5, order: 3, title: "Aligned Chain",
            blurb: "Deliver a three-atom chain in exact orientation. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(0, 2), .gamma)], bonds: [(0, 1), (1, 2)], count: 2, mode: .preBonded, allowRotation: false))
        p.append(makeAssembly(id: "5-4", chapter: 5, order: 4, title: "Quarter Right",
            blurb: "A three-quarter turn sets the heading the sink demands. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 3,
            cells: [(g(0, 0), .gamma), (g(1, 0), .delta)], bonds: [(0, 1)], count: 2, mode: .preBonded, allowRotation: false))
        p.append(makeAssembly(id: "5-5", chapter: 5, order: 5, title: "Set the Elbow",
            blurb: "An L-shaped piece must land facing the right way. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(1, 1), .gamma)], bonds: [(0, 1), (1, 2)], count: 2, mode: .preBonded, allowRotation: false))
        p.append(makeAssembly(id: "5-6", chapter: 5, order: 6, title: "Mirror Match",
            blurb: "A symmetric chain, exact heading required. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 2,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(0, 2), .alpha)], bonds: [(0, 1), (1, 2)], count: 2, mode: .preBonded, allowRotation: false))
        p.append(makeAssembly(id: "5-7", chapter: 5, order: 7, title: "Corner Piece",
            blurb: "A corner molecule, oriented to spec. Deliver 2.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(1, 0), .gamma)], bonds: [(0, 1), (0, 2)], count: 2, mode: .preBonded, allowRotation: false))
        p.append(makeAssembly(id: "5-8", chapter: 5, order: 8, title: "Precise Rod",
            blurb: "A four-atom rod delivered in exact orientation. Deliver 3.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(0, 2), .gamma), (g(0, 3), .delta)], bonds: [(0, 1), (1, 2), (2, 3)], count: 3, mode: .preBonded, allowRotation: false))

        // ===== Chapter 6 — multi-output / efficiency =====
        p.append(makeDualSort(id: "6-1", chapter: 6, order: 1, title: "Double Duty",
            blurb: "Two outputs, heavy quota. Deliver 4 of each.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, elemE: .alpha, elemW: .beta, count: 4))
        p.append(makeMerge(id: "6-2", chapter: 6, order: 2, title: "Mass Convergence",
            blurb: "Drive two streams into one sink at volume. Deliver 10.",
            width: 11, height: 11, pivot: g(5, 5), reach: 2, element: .gamma, count: 10))
        p.append(makeAssembly(id: "6-3", chapter: 6, order: 3, title: "Mass Bonding",
            blurb: "A three-atom chain line at volume. Deliver 4.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(0, 2), .gamma)], bonds: [(0, 1), (1, 2)], count: 4, mode: .bonder))
        p.append(makeAssembly(id: "6-4", chapter: 6, order: 4, title: "Throughput",
            blurb: "Pre-built pairs at high cadence. Deliver 5.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 2,
            cells: [(g(0, 0), .delta), (g(0, 1), .epsilon)], bonds: [(0, 1)], count: 5, mode: .preBonded))
        p.append(makeDualSort(id: "6-5", chapter: 6, order: 5, title: "Wide Throughput",
            blurb: "A long-reach dual line under quota. Deliver 4 of each.",
            width: 13, height: 13, pivot: g(6, 6), reach: 3, elemE: .gamma, elemW: .epsilon, count: 4))
        p.append(makeAssembly(id: "6-6", chapter: 6, order: 6, title: "Elbow Line",
            blurb: "An L-shaped molecule production run. Deliver 4.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(1, 1), .gamma)], bonds: [(0, 1), (1, 2)], count: 4, mode: .bonder))
        p.append(makeAssembly(id: "6-7", chapter: 6, order: 7, title: "Quad Run",
            blurb: "Four-atom chains at volume. Deliver 4.",
            width: 13, height: 13, pivot: g(6, 6), reach: 2, turns: 1,
            cells: [(g(0, 0), .alpha), (g(0, 1), .beta), (g(0, 2), .gamma), (g(0, 3), .delta)], bonds: [(0, 1), (1, 2), (2, 3)], count: 4, mode: .bonder))
        p.append(makeDualSort(id: "6-8", chapter: 6, order: 8, title: "The Foreman's Test",
            blurb: "The final line. Two elements, top quota. Deliver 6 of each.",
            width: 13, height: 13, pivot: g(6, 6), reach: 3, elemE: .alpha, elemW: .delta, count: 6))

        return p
    }
}
