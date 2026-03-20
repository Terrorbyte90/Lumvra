import SwiftUI
import RevenueCat

@main
struct LumvraApp: App {
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var storage: LocalStorageManager
    @StateObject private var userState: UserState
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var notificationManager = NotificationManager()

    init() {
        // Share a single LocalStorageManager between storage env object and UserState
        let s = LocalStorageManager()
        _storage = StateObject(wrappedValue: s)
        _userState = StateObject(wrappedValue: UserState(storage: s))
        Purchases.configure(withAPIKey: ConfigManager.value(for: "REVENUECAT_API_KEY"))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environmentObject(storage)
                .environmentObject(healthKitManager)
                .environmentObject(notificationManager)
                .environmentObject(userState)
                .preferredColorScheme(.dark)
                .task { await userState.refreshPremiumStatus() }
        }
    }
}
