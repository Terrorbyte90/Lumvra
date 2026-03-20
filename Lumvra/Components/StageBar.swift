import SwiftUI

struct StageBar: View {
    @EnvironmentObject var lm: LanguageManager
    let data: SleepData

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                StagePill(label: lm.t(en: "Deep", sv: "Djup"), minutes: data.deepMinutes, color: .lvPurple)
                StagePill(label: lm.t(en: "Core", sv: "Kärn"), minutes: data.coreMinutes, color: .lvTeal)
                StagePill(label: "REM", minutes: data.remMinutes, color: .lvAmber)
            }
            GeometryReader { geo in
                let total = max(1, data.deepMinutes + data.coreMinutes + data.remMinutes)
                HStack(spacing: 2) {
                    Rectangle().fill(Color.lvPurple)
                        .frame(width: geo.size.width * CGFloat(data.deepMinutes) / CGFloat(total))
                    Rectangle().fill(Color.lvTeal)
                        .frame(width: geo.size.width * CGFloat(data.coreMinutes) / CGFloat(total))
                    Rectangle().fill(Color.lvAmber)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }
}

private struct StagePill: View {
    let label: String
    let minutes: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
            Text(formatMinutes(minutes))
                .font(.caption.bold())
                .foregroundColor(.lvTextPri)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.lvSurface2)
        .cornerRadius(8)
    }

    private func formatMinutes(_ m: Int) -> String {
        m >= 60 ? "\(m/60)h \(m%60)m" : "\(m)m"
    }
}
