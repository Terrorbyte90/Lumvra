import SwiftUI

struct WatchUpgradePrompt: View {
    @EnvironmentObject var lm: LanguageManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.title2)
                .foregroundColor(.lvPurple)
            VStack(alignment: .leading, spacing: 2) {
                Text(lm.t(en: "Get deeper insights", sv: "Få djupare insikter"))
                    .font(.subheadline.bold())
                    .foregroundColor(.lvTextPri)
                Text(lm.t(
                    en: "Wear Apple Watch while sleeping for sleep stages",
                    sv: "Bär Apple Watch när du sover för sömnsteg"
                ))
                .font(.caption)
                .foregroundColor(.lvTextSec)
            }
        }
        .padding()
        .background(Color.lvSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lvPurple.opacity(0.3), lineWidth: 1))
    }
}
