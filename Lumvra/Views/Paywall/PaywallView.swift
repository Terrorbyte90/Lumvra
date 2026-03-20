import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false

    let features: [(String, String, String)] = [
        ("sparkles", "Personalised AI morning insight based on your data", "Personlig AI-insikt varje morgon baserad på din data"),
        ("moon.zzz", "Evening coaching & check-in", "Kvällscoaching och check-in"),
        ("chart.line.uptrend.xyaxis", "90 days of history + trends", "90 dagars historik och trender"),
        ("arrow.triangle.2.circlepath", "Correlation analysis", "Korrelationsanalys"),
        ("minus.circle", "Sleep debt tracker", "Sömnunderskott-tracker"),
        ("text.badge.checkmark", "Weekly summary", "Veckosammanfattning"),
    ]

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("✨")
                            .font(.system(size: 48))
                        Text(lm.t(en: "Lumvra Premium", sv: "Lumvra Premium"))
                            .font(.title.bold())
                            .foregroundColor(.lvTextPri)
                        Text(lm.t(en: "Your personal AI sleep coach", sv: "Din personliga AI-sömncoach"))
                            .foregroundColor(.lvTextSec)
                    }
                    .padding(.top, 32)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features, id: \.0) { icon, en, sv in
                            HStack(spacing: 12) {
                                Image(systemName: icon)
                                    .foregroundColor(.lvPurple)
                                    .frame(width: 24)
                                Text(lm.t(en: en, sv: sv))
                                    .foregroundColor(.lvTextPri)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        Button { purchase(.yearly) } label: {
                            VStack(spacing: 4) {
                                Text(lm.t(en: "Try free for 7 days", sv: "Prova gratis i 7 dagar"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(lm.t(en: "then 499 kr / year", sv: "sedan 499 kr/år"))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lvPurple)
                            .cornerRadius(16)
                        }

                        Button { purchase(.monthly) } label: {
                            Text(lm.t(en: "79 kr / month", sv: "79 kr / månad"))
                                .foregroundColor(.lvTextSec)
                        }

                        Button { purchase(.lifetime) } label: {
                            Text(lm.t(en: "Lifetime: 399 kr (without AI) →", sv: "Livstid: 399 kr (utan AI) →"))
                                .font(.caption)
                                .foregroundColor(.lvTextTert)
                        }
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 16) {
                        Button {
                            Task {
                                _ = try? await Purchases.shared.restorePurchases()
                                await userState.refreshPremiumStatus()
                                if userState.isPremium { dismiss() }
                            }
                        } label: {
                            Text(lm.t(en: "Restore purchases", sv: "Återställ köp"))
                                .font(.caption)
                                .foregroundColor(.lvTextSec)
                        }

                        Button { dismiss() } label: {
                            Text(lm.t(en: "Close", sv: "Stäng"))
                                .font(.caption)
                                .foregroundColor(.lvTextSec)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.lvPurple)
            }
        }
    }

    private func purchase(_ type: ProductType) {
        Task {
            isLoading = true
            defer { isLoading = false }
            guard let offering = try? await Purchases.shared.offerings().current,
                  let package = offering.package(identifier: type.packageId) else { return }
            if let result = try? await Purchases.shared.purchase(package: package) {
                if result.customerInfo.entitlements[type.entitlement]?.isActive == true {
                    await userState.refreshPremiumStatus()
                    dismiss()
                }
            }
        }
    }
}

private enum ProductType {
    case monthly, yearly, lifetime
    var packageId: String {
        switch self {
        case .monthly:  return "com.terrorbyte90.lumvra.premium.monthly"
        case .yearly:   return "com.terrorbyte90.lumvra.premium.yearly"
        case .lifetime: return "com.terrorbyte90.lumvra.lifetime"
        }
    }
    var entitlement: String {
        self == .lifetime ? "lifetime" : "premium"
    }
}
