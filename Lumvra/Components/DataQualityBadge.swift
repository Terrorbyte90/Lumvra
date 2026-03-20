import SwiftUI

struct DataQualityBadge: View {
    @EnvironmentObject var lm: LanguageManager
    let quality: DataQuality

    var body: some View {
        Text(quality.label(isSv: lm.isSv))
            .font(.caption2.bold())
            .foregroundColor(.lvTextSec)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.lvSurface2)
            .cornerRadius(6)
    }
}
