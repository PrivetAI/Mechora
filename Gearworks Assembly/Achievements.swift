import Foundation

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let condition: (GameStore) -> Bool

    static let all: [Achievement] = [
        Achievement(id: "first_solve", title: "First Assembly",
                    detail: "Solve your first puzzle.") { $0.totalSolved >= 1 },
        Achievement(id: "ten_solved", title: "Apprentice",
                    detail: "Solve 10 puzzles.") { $0.totalSolved >= 10 },
        Achievement(id: "twentyfive_solved", title: "Journeyman",
                    detail: "Solve 25 puzzles.") { $0.totalSolved >= 25 },
        Achievement(id: "all_solved", title: "Master Engineer",
                    detail: "Solve every puzzle in the workshop.") { $0.totalSolved >= PuzzleLibrary.all.count },
        Achievement(id: "ch1_done", title: "Transit Bay Cleared",
                    detail: "Solve all of Chapter 1.") { $0.chapterComplete(1) },
        Achievement(id: "ch2_done", title: "Sorting Floor Cleared",
                    detail: "Solve all of Chapter 2.") { $0.chapterComplete(2) },
        Achievement(id: "ch3_done", title: "Bonding Bench Cleared",
                    detail: "Solve all of Chapter 3.") { $0.chapterComplete(3) },
        Achievement(id: "ch4_done", title: "Molecule Forge Cleared",
                    detail: "Solve all of Chapter 4.") { $0.chapterComplete(4) },
        Achievement(id: "ch5_done", title: "Orientation Jig Cleared",
                    detail: "Solve all of Chapter 5.") { $0.chapterComplete(5) },
        Achievement(id: "ch6_done", title: "Production Wing Cleared",
                    detail: "Solve all of Chapter 6.") { $0.chapterComplete(6) },
        Achievement(id: "first_star3", title: "Flawless",
                    detail: "Earn 3 stars on a puzzle.") { $0.perfectSolves >= 1 },
        Achievement(id: "ten_star3", title: "Precision Work",
                    detail: "Earn 3 stars on 10 puzzles.") { $0.perfectSolves >= 10 },
        Achievement(id: "ten_speed", title: "Fast Hands",
                    detail: "Earn the speed star on 10 puzzles.") { $0.speedStars >= 10 },
        Achievement(id: "ten_cost", title: "Frugal Builder",
                    detail: "Earn the cost star on 10 puzzles.") { $0.costStars >= 10 },
        Achievement(id: "fifty_stars", title: "Star Collector",
                    detail: "Earn 50 total stars.") { $0.totalStars >= 50 },
        Achievement(id: "hundred_stars", title: "Star Foreman",
                    detail: "Earn 100 total stars.") { $0.totalStars >= 100 },
        Achievement(id: "perfect_ch5", title: "Orientation Ace",
                    detail: "Earn 3 stars on all of Chapter 5.") { $0.chapterPerfect(5) },
        Achievement(id: "perfect_ch6", title: "Efficiency Expert",
                    detail: "Earn 3 stars on all of Chapter 6.") { $0.chapterPerfect(6) },
        Achievement(id: "first_bond", title: "Chemist",
                    detail: "Solve a bonding puzzle in Chapter 3.") { $0.chapterSolvedCount(3) >= 1 },
        Achievement(id: "first_forge", title: "Molecule Maker",
                    detail: "Solve a puzzle in Chapter 4.") { $0.chapterSolvedCount(4) >= 1 },
        Achievement(id: "tinkerer", title: "Tinkerer",
                    detail: "Start the simulation 25 times.") { $0.runsStarted >= 25 },
        Achievement(id: "machinist", title: "Machinist",
                    detail: "Start the simulation 100 times.") { $0.runsStarted >= 100 }
    ]
}
