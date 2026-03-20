import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var lm: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MorningView()
                .tabItem { Label(lm.t(en: "Today", sv: "Idag"), systemImage: "moon.stars") }
                .tag(0)

            EveningView()
                .tabItem { Label(lm.t(en: "Evening", sv: "Kväll"), systemImage: "sunset") }
                .tag(1)

            TrendsView()
                .tabItem { Label(lm.t(en: "Trends", sv: "Trender"), systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(lm.t(en: "Settings", sv: "Inställningar"), systemImage: "gearshape") }
            .tag(3)
        }
        .tint(.lvPurple)
    }
}
