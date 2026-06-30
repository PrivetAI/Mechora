import SwiftUI
import Foundation

// MARK: - Persisted save state

struct SaveState: Codable {
    var version: Int
    var solutions: [String: SolutionModel]   // puzzleId -> working/solved solution
    var solvedIds: [String]
    var bestCycles: [String: Int]
    var bestCost: [String: Int]
    var bestArea: [String: Int]
    var bestInstr: [String: Int]
    var unlockedAchievements: [String]
    var runsStarted: Int
    var onboardingDone: Bool
    var soundOn: Bool
    var showGridCoords: Bool

    init() {
        version = 1
        solutions = [:]
        solvedIds = []
        bestCycles = [:]
        bestCost = [:]
        bestArea = [:]
        bestInstr = [:]
        unlockedAchievements = []
        runsStarted = 0
        onboardingDone = false
        soundOn = true
        showGridCoords = false
    }

    enum CodingKeys: String, CodingKey {
        case version, solutions, solvedIds, bestCycles, bestCost, bestArea, bestInstr
        case unlockedAchievements, runsStarted, onboardingDone, soundOn, showGridCoords
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        solutions = try c.decodeIfPresent([String: SolutionModel].self, forKey: .solutions) ?? [:]
        solvedIds = try c.decodeIfPresent([String].self, forKey: .solvedIds) ?? []
        bestCycles = try c.decodeIfPresent([String: Int].self, forKey: .bestCycles) ?? [:]
        bestCost = try c.decodeIfPresent([String: Int].self, forKey: .bestCost) ?? [:]
        bestArea = try c.decodeIfPresent([String: Int].self, forKey: .bestArea) ?? [:]
        bestInstr = try c.decodeIfPresent([String: Int].self, forKey: .bestInstr) ?? [:]
        unlockedAchievements = try c.decodeIfPresent([String].self, forKey: .unlockedAchievements) ?? []
        runsStarted = try c.decodeIfPresent(Int.self, forKey: .runsStarted) ?? 0
        onboardingDone = try c.decodeIfPresent(Bool.self, forKey: .onboardingDone) ?? false
        soundOn = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? true
        showGridCoords = try c.decodeIfPresent(Bool.self, forKey: .showGridCoords) ?? false
    }
}

// MARK: - Store

final class GameStore: ObservableObject {
    static let shared = GameStore()

    @Published private(set) var state: SaveState
    @Published var lastUnlocked: [String] = []   // achievement ids unlocked this session (for toast)

    private let key = "gwa.state.v1"

    // chapter unlock thresholds (cumulative stars)
    private let chapterThreshold: [Int: Int] = [1: 0, 2: 5, 3: 12, 4: 20, 5: 30, 6: 40]

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(SaveState.self, from: data) {
            state = decoded
        } else {
            state = SaveState()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func saveNow() { persist() }

    // MARK: Solutions

    func solution(for puzzleId: String) -> SolutionModel? { state.solutions[puzzleId] }

    func storeWorkingSolution(_ solution: SolutionModel, for puzzleId: String) {
        state.solutions[puzzleId] = solution
        persist()
    }

    // MARK: Progress queries

    func isSolved(_ puzzleId: String) -> Bool { state.solvedIds.contains(puzzleId) }

    func stars(for puzzle: Puzzle) -> Int {
        guard isSolved(puzzle.id) else { return 0 }
        var s = 1
        if let cyc = state.bestCycles[puzzle.id], cyc <= puzzle.cycleBudget { s += 1 }
        if let cost = state.bestCost[puzzle.id], cost <= puzzle.costBudget { s += 1 }
        return s
    }

    var totalStars: Int { PuzzleLibrary.all.reduce(0) { $0 + stars(for: $1) } }
    var totalSolved: Int { state.solvedIds.count }
    var perfectSolves: Int { PuzzleLibrary.all.filter { stars(for: $0) == 3 }.count }
    var speedStars: Int { PuzzleLibrary.all.filter { isSolved($0.id) && (state.bestCycles[$0.id] ?? .max) <= $0.cycleBudget }.count }
    var costStars: Int { PuzzleLibrary.all.filter { isSolved($0.id) && (state.bestCost[$0.id] ?? .max) <= $0.costBudget }.count }
    var runsStarted: Int { state.runsStarted }
    var bestCyclesTotal: Int { state.solvedIds.reduce(0) { $0 + (state.bestCycles[$1] ?? 0) } }

    func bestCycles(_ id: String) -> Int? { state.bestCycles[id] }
    func bestCost(_ id: String) -> Int? { state.bestCost[id] }
    func bestArea(_ id: String) -> Int? { state.bestArea[id] }
    func bestInstr(_ id: String) -> Int? { state.bestInstr[id] }

    func chapterSolvedCount(_ ch: Int) -> Int {
        PuzzleLibrary.chapter(ch).filter { isSolved($0.id) }.count
    }
    func chapterComplete(_ ch: Int) -> Bool {
        let list = PuzzleLibrary.chapter(ch)
        return !list.isEmpty && list.allSatisfy { isSolved($0.id) }
    }
    func chapterPerfect(_ ch: Int) -> Bool {
        let list = PuzzleLibrary.chapter(ch)
        return !list.isEmpty && list.allSatisfy { stars(for: $0) == 3 }
    }

    func isChapterUnlocked(_ ch: Int) -> Bool {
        totalStars >= (chapterThreshold[ch] ?? 0)
    }
    func chapterStarRequirement(_ ch: Int) -> Int { chapterThreshold[ch] ?? 0 }

    // MARK: Recording a run

    func incrementRuns() {
        state.runsStarted += 1
        persist()
        checkAchievements()
    }

    /// Record a successful solve with its metrics. Returns the new star count.
    @discardableResult
    func recordSolve(puzzle: Puzzle, cycles: Int, cost: Int, area: Int, instr: Int) -> Int {
        if !state.solvedIds.contains(puzzle.id) { state.solvedIds.append(puzzle.id) }
        if cycles < (state.bestCycles[puzzle.id] ?? Int.max) { state.bestCycles[puzzle.id] = cycles }
        if cost < (state.bestCost[puzzle.id] ?? Int.max) { state.bestCost[puzzle.id] = cost }
        if area < (state.bestArea[puzzle.id] ?? Int.max) { state.bestArea[puzzle.id] = area }
        if instr < (state.bestInstr[puzzle.id] ?? Int.max) { state.bestInstr[puzzle.id] = instr }
        persist()
        checkAchievements()
        return stars(for: puzzle)
    }

    // MARK: Settings

    func setOnboardingDone() { state.onboardingDone = true; persist() }
    var onboardingDone: Bool { state.onboardingDone }

    func toggleSound() { state.soundOn.toggle(); persist() }
    var soundOn: Bool { state.soundOn }

    func toggleGridCoords() { state.showGridCoords.toggle(); persist() }
    var showGridCoords: Bool { state.showGridCoords }

    func resetProgress() {
        state = SaveState()
        state.onboardingDone = true   // don't re-show onboarding after a manual reset
        persist()
        objectWillChange.send()
    }

    // MARK: Achievements

    func isAchievementUnlocked(_ id: String) -> Bool { state.unlockedAchievements.contains(id) }

    private func unlock(_ id: String) {
        guard !state.unlockedAchievements.contains(id) else { return }
        state.unlockedAchievements.append(id)
        lastUnlocked.append(id)
    }

    func clearToasts() { lastUnlocked.removeAll() }

    func checkAchievements() {
        for a in Achievement.all where !isAchievementUnlocked(a.id) {
            if a.condition(self) { unlock(a.id) }
        }
        persist()
    }
}
