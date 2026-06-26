import SwiftUI

enum GearTab: Int, CaseIterable {
    case workbench, manual, awards, more
    var title: String {
        switch self {
        case .workbench: return "Workbench"
        case .manual: return "Manual"
        case .awards: return "Awards"
        case .more: return "More"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: GameStore
    @State private var tab: GearTab = .workbench
    @State private var showOnboarding = false

    var body: some View {
        ZStack(alignment: .bottom) {
            GearPalette.navy.ignoresSafeArea()
            GearBackdrop().ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .workbench:
                        NavigationView { WorkbenchView() }.navigationViewStyle(StackNavigationViewStyle())
                    case .manual:
                        NavigationView { ManualView() }.navigationViewStyle(StackNavigationViewStyle())
                    case .awards:
                        NavigationView { AwardsView() }.navigationViewStyle(StackNavigationViewStyle())
                    case .more:
                        NavigationView { MoreView() }.navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                tabBar
            }

            achievementToast
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !store.onboardingDone { showOnboarding = true }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { store.setOnboardingDone(); showOnboarding = false }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.workbench) { WorkbenchGlyph(color: $0) }
            tabButton(.manual) { ManualGlyph(color: $0) }
            tabButton(.awards) { AwardsGlyph(color: $0) }
            tabButton(.more) { MoreGlyph(color: $0) }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            GearPalette.panel
                .overlay(Rectangle().frame(height: 1).foregroundColor(GearPalette.line), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton<G: View>(_ t: GearTab, @ViewBuilder glyph: (Color) -> G) -> some View {
        let active = tab == t
        let color = active ? GearPalette.copperBright : GearPalette.haze.opacity(0.7)
        return Button {
            tab = t
        } label: {
            VStack(spacing: 5) {
                glyph(color).frame(width: 26, height: 26)
                Text(t.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder private var achievementToast: some View {
        if let id = store.lastUnlocked.last,
           let ach = Achievement.all.first(where: { $0.id == id }) {
            VStack {
                HStack(spacing: 12) {
                    StarShape(points: 5).fill(GearPalette.gold).frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievement Unlocked")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(GearPalette.gold)
                        Text(ach.title)
                            .font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
                    }
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(GearPalette.panelLift)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(GearPalette.gold.opacity(0.6), lineWidth: 1)))
                .padding(.horizontal, 20)
                .padding(.top, 60)
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                    withAnimation { store.clearToasts() }
                }
            }
        }
    }
}
