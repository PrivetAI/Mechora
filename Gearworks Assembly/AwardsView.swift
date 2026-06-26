import SwiftUI

struct AwardsView: View {
    @EnvironmentObject var store: GameStore

    private let statColumns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ZStack {
            GearPalette.navy.ignoresSafeArea()
            GearBackdrop().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GearSectionHeader(title: "Statistics")
                    statsGrid
                    GearSectionHeader(title: "Achievements", accent: GearPalette.gold)
                    achievementsList
                }
                .padding(16)
                .gearReadable()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Awards").font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: statColumns, spacing: 12) {
            statCard("Puzzles Solved", "\(store.totalSolved)/\(PuzzleLibrary.all.count)", GearPalette.copper)
            statCard("Total Stars", "\(store.totalStars)/\(PuzzleLibrary.all.count * 3)", GearPalette.gold)
            statCard("Perfect (3★)", "\(store.perfectSolves)", GearPalette.verdigris)
            statCard("Speed Stars", "\(store.speedStars)", GearPalette.blueprint)
            statCard("Cost Stars", "\(store.costStars)", GearPalette.copperBright)
            statCard("Best Cycles Sum", "\(store.bestCyclesTotal)", GearPalette.ivory)
            statCard("Simulations Run", "\(store.runsStarted)", GearPalette.haze)
            statCard("Achievements", "\(unlockedCount)/\(Achievement.all.count)", GearPalette.gold)
        }
    }

    private var unlockedCount: Int { Achievement.all.filter { store.isAchievementUnlocked($0.id) }.count }

    private func statCard(_ title: String, _ value: String, _ accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.system(size: 22, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(accent)
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(GearPalette.panel)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(GearPalette.line, lineWidth: 1)))
    }

    private var achievementsList: some View {
        VStack(spacing: 10) {
            ForEach(Achievement.all) { ach in
                let unlocked = store.isAchievementUnlocked(ach.id)
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(unlocked ? GearPalette.gold.opacity(0.25) : GearPalette.navyDeep)
                            .frame(width: 42, height: 42)
                        StarShape(points: 5)
                            .fill(unlocked ? GearPalette.gold : GearPalette.haze.opacity(0.35))
                            .frame(width: 22, height: 22)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ach.title).font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundColor(unlocked ? GearPalette.ivory : GearPalette.haze)
                        Text(ach.detail).font(.system(size: 12, weight: .medium)).foregroundColor(GearPalette.haze)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    if unlocked { CheckGlyph(color: GearPalette.verdigris).frame(width: 18, height: 18) }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(GearPalette.panel)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(unlocked ? GearPalette.gold.opacity(0.5) : GearPalette.line, lineWidth: 1)))
            }
        }
    }
}
