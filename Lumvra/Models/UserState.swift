import Foundation
import RevenueCat

@MainActor
class UserState: ObservableObject {
    @Published var profile: UserProfile
    @Published var isPremium: Bool = false

    private let storage: LocalStorageManager

    init(storage: LocalStorageManager) {
        self.storage = storage
        self.profile = storage.loadProfile() ?? .default
        self.isPremium = profile.isPremium
    }

    func refreshPremiumStatus() async {
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        let active = info.entitlements["premium"]?.isActive == true
                  || info.entitlements["lifetime"]?.isActive == true
        isPremium = active
        profile.isPremium = active
        storage.saveProfile(profile)
    }

    func saveProfile() {
        storage.saveProfile(profile)
    }
}
