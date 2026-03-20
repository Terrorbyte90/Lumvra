import SwiftUI

struct InsightCard: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    let insight: String?
    var onUpgrade: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.lvPurple)
                Text(lm.t(en: "Your sleep insight", sv: "Din sömninsikt"))
                    .font(.subheadline.bold())
                    .foregroundColor(.lvTextPri)
                Spacer()
                if !userState.isPremium {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.lvTextTert)
                }
            }
            if userState.isPremium {
                if let insight {
                    Text(insight)
                        .font(.body)
                        .foregroundColor(.lvTextPri)
                } else {
                    ProgressView().tint(.lvPurple)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(lm.t(
                        en: "Your deep sleep increased 40% vs your weekly average...",
                        sv: "Din djupsömn ökade 40% jämfört med veckosnittet..."
                    ))
                    .font(.body)
                    .foregroundColor(.lvTextPri)
                    .blur(radius: 4)
                    Button(action: onUpgrade) {
                        Text(lm.t(en: "Upgrade to see your insight", sv: "Uppgradera för att se din insikt"))
                            .font(.caption.bold())
                            .foregroundColor(.lvPurple)
                    }
                }
            }
        }
        .padding()
        .background(Color.lvSurface)
        .cornerRadius(16)
    }
}
