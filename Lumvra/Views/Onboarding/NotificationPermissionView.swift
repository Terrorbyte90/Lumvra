import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var notificationManager: NotificationManager
    var onNext: () -> Void

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.lvAmber)
                VStack(spacing: 12) {
                    Text(lm.t(en: "Morning insights", sv: "Morgoninsikter"))
                        .font(.title2.bold())
                        .foregroundColor(.lvTextPri)
                    Text(lm.t(
                        en: "We'll remind you every morning when your sleep insight is ready.",
                        sv: "Vi påminner dig varje morgon när din sömninsikt är klar."
                    ))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.lvTextSec)
                    .padding(.horizontal)
                }
                Spacer()
                VStack(spacing: 12) {
                    Button {
                        Task {
                            _ = await notificationManager.requestPermission()
                            onNext()
                        }
                    } label: {
                        Text(lm.t(en: "Allow notifications", sv: "Tillåt notiser"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lvPurple)
                            .cornerRadius(16)
                    }
                    Button(action: onNext) {
                        Text(lm.t(en: "Skip", sv: "Hoppa över"))
                            .foregroundColor(.lvTextSec)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
