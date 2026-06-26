import Foundation

// MARK: - Molecule spec (a shape of typed atoms with internal bonds)

struct AtomSpec {
    let offset: GridPos
    let element: Element
}

struct MoleculeSpec {
    let atoms: [AtomSpec]
    /// Internal bonds as index pairs into `atoms`.
    let bonds: [(Int, Int)]

    init(atoms: [AtomSpec], bonds: [(Int, Int)] = []) {
        self.atoms = atoms
        self.bonds = bonds
    }

    static func single(_ element: Element) -> MoleculeSpec {
        MoleculeSpec(atoms: [AtomSpec(offset: GridPos(x: 0, y: 0), element: element)])
    }
}

// MARK: - Puzzle-fixed mechanisms

struct DispenserDef {
    let anchor: GridPos
    let molecule: MoleculeSpec
    /// Absolute footprint cells this dispenser owns (anchor + atom offsets).
    var footprint: [GridPos] { molecule.atoms.map { anchor + $0.offset } }
}

struct SinkDef {
    let anchor: GridPos
    let target: MoleculeSpec
    let required: Int
    /// When false the molecule must be delivered in the exact stored orientation
    /// (used by the orientation-matching chapter). Default true = any rotation accepted.
    let allowRotation: Bool

    init(anchor: GridPos, target: MoleculeSpec, required: Int, allowRotation: Bool = true) {
        self.anchor = anchor
        self.target = target
        self.required = required
        self.allowRotation = allowRotation
    }
}

// MARK: - Puzzle definition

struct Puzzle: Identifiable {
    let id: String
    let chapter: Int          // 1...6
    let order: Int            // order within chapter (1-based)
    let title: String
    let blurb: String
    let width: Int
    let height: Int
    let walls: [GridPos]
    let dispensers: [DispenserDef]
    let sinks: [SinkDef]
    let allowed: [MechanismKind]
    let cycleBudget: Int      // star 2 threshold (<=)
    let costBudget: Int       // star 3 threshold (<=)
    let reference: SolutionModel

    var wallSet: Set<GridPos> { Set(walls) }
}

// MARK: - Player / author solution (Codable, persisted)

struct ArmPlacement: Codable, Identifiable {
    var id: Int
    var pivot: GridPos
    var reach: Int            // 1...3
    var orientation: Dir
    var tape: [Instruction]
    var trackPath: [GridPos]? // optional base path for track movement

    init(id: Int, pivot: GridPos, reach: Int, orientation: Dir, tape: [Instruction], trackPath: [GridPos]? = nil) {
        self.id = id
        self.pivot = pivot
        self.reach = max(1, min(3, reach))
        self.orientation = orientation
        self.tape = tape
        self.trackPath = trackPath
    }

    enum CodingKeys: String, CodingKey {
        case id, pivot, reach, orientation, tape, trackPath
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(Int.self, forKey: .id) ?? 0
        pivot = try c.decodeIfPresent(GridPos.self, forKey: .pivot) ?? GridPos(x: 0, y: 0)
        reach = try c.decodeIfPresent(Int.self, forKey: .reach) ?? 1
        orientation = try c.decodeIfPresent(Dir.self, forKey: .orientation) ?? .east
        tape = try c.decodeIfPresent([Instruction].self, forKey: .tape) ?? []
        trackPath = try c.decodeIfPresent([GridPos].self, forKey: .trackPath)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(pivot, forKey: .pivot)
        try c.encode(reach, forKey: .reach)
        try c.encode(orientation, forKey: .orientation)
        try c.encode(tape, forKey: .tape)
        try c.encodeIfPresent(trackPath, forKey: .trackPath)
    }
}

struct SolutionModel: Codable {
    var arms: [ArmPlacement]
    var bonders: [GridPos]
    var tracks: [GridPos]

    init(arms: [ArmPlacement] = [], bonders: [GridPos] = [], tracks: [GridPos] = []) {
        self.arms = arms
        self.bonders = bonders
        self.tracks = tracks
    }

    enum CodingKeys: String, CodingKey { case arms, bonders, tracks }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        arms = try c.decodeIfPresent([ArmPlacement].self, forKey: .arms) ?? []
        bonders = try c.decodeIfPresent([GridPos].self, forKey: .bonders) ?? []
        tracks = try c.decodeIfPresent([GridPos].self, forKey: .tracks) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(arms, forKey: .arms)
        try c.encode(bonders, forKey: .bonders)
        try c.encode(tracks, forKey: .tracks)
    }

    var isEmpty: Bool { arms.isEmpty && bonders.isEmpty && tracks.isEmpty }

    // MARK: Metrics

    /// Total instruction tokens across all arms.
    var instructionCount: Int { arms.reduce(0) { $0 + $1.tape.count } }

    /// Cost = sum of mechanism costs.
    var cost: Int {
        var total = 0
        total += arms.count * MechanismKind.arm.cost
        total += bonders.count * MechanismKind.bonder.cost
        total += tracks.count * MechanismKind.track.cost
        return total
    }

    /// Footprint area = bounding box that covers every placed cell, including
    /// each arm's full reach sweep (all cells its tip can occupy).
    var area: Int {
        var cells: [GridPos] = []
        for arm in arms {
            cells.append(arm.pivot)
            for dir in Dir.allCases {
                for r in 1...arm.reach {
                    cells.append(GridPos(x: arm.pivot.x + dir.vector.x * r,
                                         y: arm.pivot.y + dir.vector.y * r))
                }
            }
            if let path = arm.trackPath { cells.append(contentsOf: path) }
        }
        cells.append(contentsOf: bonders)
        cells.append(contentsOf: tracks)
        guard let first = cells.first else { return 0 }
        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for c in cells {
            minX = min(minX, c.x); maxX = max(maxX, c.x)
            minY = min(minY, c.y); maxY = max(maxY, c.y)
        }
        return (maxX - minX + 1) * (maxY - minY + 1)
    }
}
