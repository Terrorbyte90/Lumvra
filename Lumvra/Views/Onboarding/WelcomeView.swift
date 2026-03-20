import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var lm: LanguageManager
    var onNext: () -> Void

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.lvPurple)
                    Text("Lumvra")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.lvTextPri)
                    Text(lm.t(en: "Your AI sleep coach", sv: "Din AI-sömncoach"))
                        .font(.title3)
                        .foregroundColor(.lvTextSec)
                }
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "applewatch", en: "Reads Apple Watch sleep data", sv: "Läser Apple Watch sömndata")
                    FeatureRow(icon: "sparkles", en: "AI insight every morning", sv: "AI-insikt varje morgon")
                    FeatureRow(icon: "moon.zzz", en: "Bedtime recommendation every evening", sv: "Rekommendation varje kväll")
                }
                .padding(.horizontal, 32)
                Spacer()
                Button(action: onNext) {
                    Text(lm.t(en: "Get started", sv: "Kom igång"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lvPurple)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

private struct FeatureRow: View {
    @EnvironmentObject var lm: LanguageManager
    let icon: String
    let en: String
    let sv: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.lvPurple)
                .frame(width: 32)
            Text(lm.t(en: en, sv: sv))
                .foregroundColor(.lvTextPri)
        }
    }
}
