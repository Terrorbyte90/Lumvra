import SwiftUI

struct LoadingDataView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var userState: UserState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                ProgressView()
                    .tint(.lvPurple)
                    .scaleEffect(1.5)
                Text(lm.t(en: "Reading your sleep patterns...", sv: "Läser dina sömnmönster..."))
                    .foregroundColor(.lvTextPri)
                    .font(.headline)
                Text(lm.t(en: "Analysing 30 nights", sv: "Analyserar 30 nätter"))
                    .foregroundColor(.lvTextSec)
            }
        }
        .task {
            await hkManager.fetchLastNightSleep()
            await hkManager.fetchSleepHistory(days: 30)
            notificationManager.reschedule(profile: userState.profile, language: lm.resolvedLanguage)
            hasCompletedOnboarding = true
        }
    }
}
