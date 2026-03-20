import SwiftUI

struct MorningView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var storage: LocalStorageManager
    @State private var insight: String?
    @State private var bedtimeRec: String?
    @State private var showPaywall = false
    private let ai = AIManager()

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text(dateHeader)
                            .font(.headline)
                            .foregroundColor(.lvTextSec)
                        Spacer()
                        DataQualityBadge(quality: hkManager.lastNight.quality)
                    }
                    .padding(.horizontal)

                    let data = hkManager.lastNight

                    if data.quality == .noData {
                        noDataView
                    } else {
                        SleepScoreRing(score: data.score, size: 180)
                            .padding(.top, 8)

                        InsightCard(insight: insight) { showPaywall = true }
                            .padding(.horizontal)

                        if data.quality == .full {
                            StageBar(data: data)
                                .padding(.horizontal)
                        }

                        if data.quality == .basic && !userState.profile.hasSeenWatchPrompt {
                            WatchUpgradePrompt()
                                .padding(.horizontal)
                                .onAppear {
                                    userState.profile.hasSeenWatchPrompt = true
                                    userState.saveProfile()
                                }
                        }

                        HStack(spacing: 16) {
                            Label(formatHours(data.hoursSlept), systemImage: "bed.double")
                            if data.quality == .full {
                                Label(
                                    "\(data.awakeCount) \(lm.t(en: "awakenings", sv: "uppvaknanden"))",
                                    systemImage: "arrow.up.arrow.down"
                                )
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.lvTextSec)

                        if let rec = bedtimeRec {
                            HStack {
                                Image(systemName: "moon.zzz")
                                    .foregroundColor(.lvPurple)
                                Text(lm.t(en: "Tonight: ", sv: "Ikväll: ") + rec)
                                    .foregroundColor(.lvTextPri)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding()
                            .background(Color.lvSurface)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .task { await loadInsights() }
    }

    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 64))
                .foregroundColor(.lvTextTert)
            Text(lm.t(en: "No sleep data for last night", sv: "Ingen sömndata för igår natt"))
                .font(.headline)
                .foregroundColor(.lvTextPri)
            Text(lm.t(
                en: "Wear Apple Watch while sleeping and open the app tomorrow.",
                sv: "Bär Apple Watch när du sover och öppna appen imorgon."
            ))
            .multilineTextAlignment(.center)
            .foregroundColor(.lvTextSec)
            .padding(.horizontal)
        }
        .padding(.top, 60)
    }

    private var dateHeader: String {
        let f = DateFormatter()
        f.dateFormat = lm.isSv ? "EEEE d MMMM" : "EEEE, MMMM d"
        f.locale = Locale(identifier: lm.isSv ? "sv_SE" : "en_US")
        return f.string(from: Date()).capitalized
    }

    private func formatHours(_ h: Double) -> String {
        let hrs = Int(h)
        let mins = Int((h - Double(hrs)) * 60)
        return "\(hrs)h \(mins)m"
    }

    private func loadInsights() async {
        if let cached = storage.loadCachedInsight(for: Date()) {
            insight = cached.morningInsight
            bedtimeRec = cached.bedtimeRecommendation
            return
        }
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        if userState.isPremium {
            let checkin = storage.loadCheckin(for: Calendar.current.startOfDay(for: Date()))
            async let morningTask = ai.generateMorningInsight(
                sleepData: hkManager.lastNight,
                history: hkManager.history,
                checkin: checkin,
                language: lm.resolvedLanguage
            )
            async let bedtimeTask = ai.generateBedtimeRecommendation(
                history: hkManager.history,
                targetWakeTime: userState.profile.targetWakeTime,
                language: lm.resolvedLanguage
            )
            let (m, b) = await (morningTask, bedtimeTask)
            insight = m
            bedtimeRec = b
            let si = SleepInsight(
                id: UUID(),
                date: Calendar.current.startOfDay(for: Date()),
                morningInsight: m,
                bedtimeRecommendation: b,
                recommendedBedtime: ai.parseBedtime(from: b),
                sleepScore: hkManager.lastNight.score,
                language: lm.resolvedLanguage,
                dataQuality: hkManager.lastNight.quality,
                generatedAt: Date()
            )
            storage.cacheInsight(si)
        } else {
            bedtimeRec = f.string(from: userState.profile.targetBedtime)
        }
    }
}
