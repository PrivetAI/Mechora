import Foundation

// MARK: - Grid geometry (deterministic, integer only, y-down screen space)

struct GridPos: Hashable, Codable {
    var x: Int
    var y: Int

    static func + (a: GridPos, b: GridPos) -> GridPos { GridPos(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: GridPos, b: GridPos) -> GridPos { GridPos(x: a.x - b.x, y: a.y - b.y) }
}

/// Orthogonal directions in y-down (screen) space.
/// 0=E(1,0) 1=S(0,1) 2=W(-1,0) 3=N(0,-1). Rotating clockwise increases the index.
enum Dir: Int, Codable, CaseIterable {
    case east = 0
    case south = 1
    case west = 2
    case north = 3

    var vector: GridPos {
        switch self {
        case .east: return GridPos(x: 1, y: 0)
        case .south: return GridPos(x: 0, y: 1)
        case .west: return GridPos(x: -1, y: 0)
        case .north: return GridPos(x: 0, y: -1)
        }
    }

    var rotatedCW: Dir { Dir(rawValue: (rawValue + 1) % 4)! }
    var rotatedCCW: Dir { Dir(rawValue: (rawValue + 3) % 4)! }
}

/// Rotate a relative offset (point - pivot) clockwise on screen (y-down): (x,y) -> (-y, x).
func rotateCW(_ p: GridPos) -> GridPos { GridPos(x: -p.y, y: p.x) }
/// Rotate counter-clockwise: (x,y) -> (y, -x).
func rotateCCW(_ p: GridPos) -> GridPos { GridPos(x: p.y, y: -p.x) }

/// Rotate an offset by a quarter-turn count (positive = clockwise).
func rotateOffset(_ p: GridPos, quarterTurns: Int) -> GridPos {
    var result = p
    let n = ((quarterTurns % 4) + 4) % 4
    for _ in 0..<n { result = rotateCW(result) }
    return result
}

// MARK: - Atom element types

enum Element: Int, Codable, CaseIterable {
    case alpha = 0   // copper
    case beta = 1    // verdigris
    case gamma = 2   // gold
    case delta = 3   // ivory
    case epsilon = 4 // cyan

    var symbol: String {
        switch self {
        case .alpha: return "A"
        case .beta: return "B"
        case .gamma: return "G"
        case .delta: return "D"
        case .epsilon: return "E"
        }
    }

    var name: String {
        switch self {
        case .alpha: return "Alpha"
        case .beta: return "Beta"
        case .gamma: return "Gamma"
        case .delta: return "Delta"
        case .epsilon: return "Epsilon"
        }
    }
}

// MARK: - Instructions on an arm tape

enum Instruction: Int, Codable, CaseIterable {
    case grab = 0
    case drop = 1
    case rotateCW = 2
    case rotateCCW = 3
    case extend = 4
    case retract = 5
    case trackForward = 6
    case trackBackward = 7
    case wait = 8

    var label: String {
        switch self {
        case .grab: return "Grab"
        case .drop: return "Drop"
        case .rotateCW: return "Turn CW"
        case .rotateCCW: return "Turn CCW"
        case .extend: return "Extend"
        case .retract: return "Retract"
        case .trackForward: return "Track +"
        case .trackBackward: return "Track -"
        case .wait: return "Wait"
        }
    }

    var shortLabel: String {
        switch self {
        case .grab: return "GRB"
        case .drop: return "DRP"
        case .rotateCW: return "CW"
        case .rotateCCW: return "CCW"
        case .extend: return "EXT"
        case .retract: return "RET"
        case .trackForward: return "TK+"
        case .trackBackward: return "TK-"
        case .wait: return "WAIT"
        }
    }
}

// MARK: - Mechanism palette identity (what a puzzle allows the player to place)

enum MechanismKind: Int, Codable, CaseIterable {
    case arm = 0
    case bonder = 1
    case track = 2

    var name: String {
        switch self {
        case .arm: return "Arm"
        case .bonder: return "Bonder"
        case .track: return "Track"
        }
    }

    var cost: Int {
        switch self {
        case .arm: return 20
        case .bonder: return 10
        case .track: return 5
        }
    }
}
