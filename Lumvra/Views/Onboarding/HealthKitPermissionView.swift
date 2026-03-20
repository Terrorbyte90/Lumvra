import SwiftUI

struct HealthKitPermissionView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager
    var onNext: () -> Void

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.lvTeal)
                VStack(spacing: 12) {
                    Text(lm.t(en: "Sleep data access", sv: "Tillgång till sömndata"))
                        .font(.title2.bold())
                        .foregroundColor(.lvTextPri)
                    Text(lm.t(
                        en: "Lumvra reads your sleep data from Apple Health. Your data never leaves your device.",
                        sv: "Lumvra läser din sömndata från Apple Health. Din data lämnar aldrig din telefon."
                    ))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.lvTextSec)
                    .padding(.horizontal)
                }
                Spacer()
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await hkManager.requestAuthorization()
                            onNext()
                        }
                    } label: {
                        Text(lm.t(en: "Allow Health access", sv: "Tillåt hälsotillgång"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lvPurple)
                            .cornerRadius(16)
                    }
                    Button(action: onNext) {
                        Text(lm.t(en: "Continue without access", sv: "Fortsätt utan tillgång"))
                            .foregroundColor(.lvTextSec)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
