import SwiftUI

struct WorkbenchView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ZStack {
            GearPalette.navy.ignoresSafeArea()
            GearBackdrop().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    ForEach(1...6, id: \.self) { ch in
                        chapterCard(ch)
                    }
                }
                .padding(16)
                .gearReadable()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Workbench")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(GearPalette.ivory)
            }
        }
    }

    private var header: some View {
        GearCard {
            HStack(spacing: 14) {
                ZStack {
                    GearCogShape(teeth: 10).fill(GearPalette.copper).frame(width: 48, height: 48)
                    Circle().fill(GearPalette.navyDeep).frame(width: 16, height: 16)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drafting Room")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(GearPalette.ivory)
                    Text("\(store.totalSolved)/\(PuzzleLibrary.all.count) solved · \(store.totalStars) stars")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(GearPalette.haze)
                }
                Spacer()
            }
        }
    }

    private func chapterCard(_ ch: Int) -> some View {
        let puzzles = PuzzleLibrary.chapter(ch)
        let solved = puzzles.filter { store.isSolved($0.id) }.count
        let starsEarned = puzzles.reduce(0) { $0 + store.stars(for: $1) }
        let unlocked = store.isChapterUnlocked(ch)
        return Group {
            if unlocked {
                NavigationLink(destination: PuzzleListView(chapter: ch)) {
                    chapterCardBody(ch, solved: solved, total: puzzles.count, stars: starsEarned, unlocked: true)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                chapterCardBody(ch, solved: solved, total: puzzles.count, stars: starsEarned, unlocked: false)
            }
        }
    }

    private func chapterCardBody(_ ch: Int, solved: Int, total: Int, stars: Int, unlocked: Bool) -> some View {
        GearCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Chapter \(ch)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(GearPalette.copperBright)
                    Spacer()
                    if unlocked {
                        Text("\(solved)/\(total)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(GearPalette.haze)
                    } else {
                        HStack(spacing: 5) {
                            LockGlyph(color: GearPalette.haze).frame(width: 14, height: 14)
                            Text("\(store.chapterStarRequirement(ch)) stars")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(GearPalette.haze)
                        }
                    }
                }
                Text(PuzzleLibrary.chapterTitles[ch] ?? "")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(unlocked ? GearPalette.ivory : GearPalette.haze)
                Text(PuzzleLibrary.chapterBlurbs[ch] ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GearPalette.haze)
                    .fixedSize(horizontal: false, vertical: true)
                if unlocked {
                    ProgressBar(value: total == 0 ? 0 : Double(solved) / Double(total))
                        .frame(height: 7)
                    HStack(spacing: 4) {
                        StarShape(points: 5).fill(GearPalette.gold).frame(width: 14, height: 14)
                        Text("\(stars)/\(total * 3)")
                            .font(.system(size: 12, weight: .bold)).foregroundColor(GearPalette.gold)
                        Spacer()
                        Text("Open")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(GearPalette.copperBright)
                    }
                }
            }
        }
        .opacity(unlocked ? 1 : 0.7)
    }
}

struct ProgressBar: View {
    let value: Double
    var body: some View {
        GeometryReader { p in
            ZStack(alignment: .leading) {
                Capsule().fill(GearPalette.navyDeep)
                Capsule().fill(GearPalette.copper)
                    .frame(width: max(0, min(1, value)) * p.size.width)
            }
        }
    }
}

struct LockGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.12).fill(color)
                    .frame(width: w * 0.7, height: h * 0.48)
                    .offset(y: h * 0.16)
                Path { path in
                    path.addArc(center: CGPoint(x: w * 0.5, y: h * 0.34), radius: w * 0.22,
                                startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                }.stroke(color, lineWidth: w * 0.1)
            }
        }
    }
}

// MARK: - Puzzle list

struct PuzzleListView: View {
    let chapter: Int
    @EnvironmentObject var store: GameStore

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ZStack {
            GearPalette.navy.ignoresSafeArea()
            GearBackdrop().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(PuzzleLibrary.chapterBlurbs[chapter] ?? "")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(GearPalette.haze)
                        .fixedSize(horizontal: false, vertical: true)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(PuzzleLibrary.chapter(chapter)) { puzzle in
                            NavigationLink(destination: EditorView(puzzle: puzzle)) {
                                puzzleCell(puzzle)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(16)
                .gearReadable()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(PuzzleLibrary.chapterTitles[chapter] ?? "Puzzles")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(GearPalette.ivory)
            }
        }
    }

    private func puzzleCell(_ puzzle: Puzzle) -> some View {
        let stars = store.stars(for: puzzle)
        let solved = store.isSolved(puzzle.id)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(puzzle.chapter)-\(puzzle.order)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(GearPalette.copperBright)
                Spacer()
                if solved {
                    CheckGlyph(color: GearPalette.verdigris).frame(width: 16, height: 16)
                }
            }
            Text(puzzle.title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(GearPalette.ivory)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 2)
            StarRow(filled: stars, total: 3, size: 14)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(GearPalette.panel)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(solved ? GearPalette.verdigris.opacity(0.5) : GearPalette.line, lineWidth: 1))
        )
    }
}

struct CheckGlyph: View {
    let color: Color
    var body: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            Path { path in
                path.move(to: CGPoint(x: w * 0.18, y: h * 0.52))
                path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.76))
                path.addLine(to: CGPoint(x: w * 0.84, y: h * 0.24))
            }.stroke(color, style: StrokeStyle(lineWidth: w * 0.16, lineCap: .round, lineJoin: .round))
        }
    }
}
