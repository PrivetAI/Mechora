import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: GameStore
    @State private var showPrivacy = false
    @State private var showResetConfirm = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            GearPalette.navy.ignoresSafeArea()
            GearBackdrop().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GearSectionHeader(title: "Settings")
                    toggleRow(title: "Sound Cues",
                              detail: "Subtle interface feedback (kept fully on-device).",
                              isOn: store.soundOn) { store.toggleSound() }
                    toggleRow(title: "Show Grid Coordinates",
                              detail: "Overlay row and column numbers on the board.",
                              isOn: store.showGridCoords) { store.toggleGridCoords() }

                    GearCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Replay Tutorial")
                                .font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
                            Text("Walk through the five-step introduction again.")
                                .font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                            Button { showOnboarding = true } label: { Text("Open Tutorial") }
                                .buttonStyle(GearButtonStyle(fill: GearPalette.verdigris, textColor: GearPalette.ivory))
                        }
                    }

                    GearCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Privacy")
                                .font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
                            Text("All progress is stored locally on this device. No accounts, no tracking.")
                                .font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                                .fixedSize(horizontal: false, vertical: true)
                            Button { showPrivacy = true } label: { Text("Privacy Policy") }
                                .buttonStyle(GearButtonStyle())
                        }
                    }

                    GearCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reset Progress")
                                .font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(GearPalette.alert)
                            Text("Erase all solutions, stars, and achievements. This cannot be undone.")
                                .font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                                .fixedSize(horizontal: false, vertical: true)
                            Button { showResetConfirm = true } label: { Text("Reset Everything") }
                                .buttonStyle(GearButtonStyle(fill: GearPalette.alert, textColor: GearPalette.ivory))
                        }
                    }

                    aboutCard
                }
                .padding(16)
                .gearReadable()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("More").font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            GearGlassPanel(urlString: "https://example.com")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { showOnboarding = false }
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(title: Text("Reset all progress?"),
                  message: Text("This permanently erases every solution, star, and achievement."),
                  primaryButton: .destructive(Text("Reset")) { store.resetProgress() },
                  secondaryButton: .cancel())
        }
    }

    private var aboutCard: some View {
        GearCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Gearworks Assembly")
                    .font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
                Text("A deterministic spatial-automation puzzle. Version 1.0")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
                Text("\(PuzzleLibrary.all.count) puzzles across 6 chapters.")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(GearPalette.haze)
            }
        }
    }

    private func toggleRow(title: String, detail: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        GearCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
                    Text(detail).font(.system(size: 12, weight: .medium)).foregroundColor(GearPalette.haze)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button(action: action) {
                    ZStack(alignment: isOn ? .trailing : .leading) {
                        Capsule().fill(isOn ? GearPalette.verdigris : GearPalette.navyDeep)
                            .frame(width: 50, height: 30)
                        Circle().fill(GearPalette.ivory).frame(width: 24, height: 24).padding(3)
                    }
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}
