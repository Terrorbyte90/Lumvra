import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var userState: UserState

    var body: some View {
        if userState.isPremium {
            TrendsContentView()
        } else {
            PaywallView()
        }
    }
}

private struct TrendsContentView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager

    private var last7: [SleepData] { Array(hkManager.history.prefix(7)) }
    private var avgScore: Int { last7.map(\.score).reduce(0, +) / max(1, last7.count) }
    private var avgDeep: Int { last7.map(\.deepMinutes).reduce(0, +) / max(1, last7.count) }
    private var avgCore: Int { last7.map(\.coreMinutes).reduce(0, +) / max(1, last7.count) }
    private var avgREM: Int  { last7.map(\.remMinutes).reduce(0, +) / max(1, last7.count) }

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(lm.t(en: "Trends", sv: "Trender"))
                        .font(.title2.bold())
                        .foregroundColor(.lvTextPri)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(lm.t(en: "Last 7 nights", sv: "Senaste 7 nätterna"))
                            .font(.subheadline.bold())
                            .foregroundColor(.lvTextSec)
                            .padding(.horizontal)

                        Chart(last7.reversed(), id: \.date) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Score", data.score)
                            )
                            .foregroundStyle(Color.forScore(data.score))
                        }
                        .frame(height: 120)
                        .padding(.horizontal)

                        Text(lm.t(en: "Average: \(avgScore)", sv: "Snitt: \(avgScore)"))
                            .font(.caption)
                            .foregroundColor(.lvTextSec)
                            .padding(.horizontal)
                    }

                    if avgDeep + avgCore + avgREM > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lm.t(en: "Sleep stages (avg)", sv: "Sömnsteg (snitt)"))
                                .font(.subheadline.bold())
                                .foregroundColor(.lvTextSec)
                                .padding(.horizontal)
                            StageAvgRow(label: lm.t(en: "Deep", sv: "Djup"), minutes: avgDeep, color: .lvPurple, total: avgDeep + avgCore + avgREM)
                            StageAvgRow(label: lm.t(en: "Core", sv: "Kärn"), minutes: avgCore, color: .lvTeal,   total: avgDeep + avgCore + avgREM)
                            StageAvgRow(label: "REM", minutes: avgREM, color: .lvAmber, total: avgDeep + avgCore + avgREM)
                        }
                    }

                    if hkManager.history.count >= 14 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lm.t(en: "Correlations", sv: "Korrelationer"))
                                .font(.subheadline.bold())
                                .foregroundColor(.lvTextSec)
                                .padding(.horizontal)
                            Text(lm.t(
                                en: "Log evening check-ins for at least 14 nights to see correlations.",
                                sv: "Logga kvällscheck-ins i minst 14 nätter för att se korrelationer."
                            ))
                            .font(.caption)
                            .foregroundColor(.lvTextTert)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

private struct StageAvgRow: View {
    let label: String
    let minutes: Int
    let color: Color
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.lvTextPri)
                .frame(width: 48, alignment: .leading)
            Text("\(minutes)m")
                .font(.subheadline.bold())
                .foregroundColor(color)
                .frame(width: 48)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.lvSurface2)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * CGFloat(minutes) / CGFloat(max(1, total)))
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
}
