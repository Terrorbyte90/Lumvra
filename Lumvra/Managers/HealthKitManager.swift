import HealthKit
import Foundation

@MainActor
class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    @Published var lastNight: SleepData = .empty(date: Date())
    @Published var history: [SleepData] = []
    @Published var authorizationDenied = false

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationDenied = true
            return
        }
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
        } catch {
            authorizationDenied = true
        }
    }

    func fetchLastNightSleep() async {
        let cal = Calendar.current
        let now = Date()
        // Window: yesterday 6 PM → today noon
        var startComps = cal.dateComponents([.year, .month, .day], from: now)
        startComps.hour = 18
        let todayAt6pm = cal.date(from: startComps) ?? now
        let start = cal.date(byAdding: .day, value: -1, to: todayAt6pm) ?? now
        var endComps = cal.dateComponents([.year, .month, .day], from: now)
        endComps.hour = 12
        let end = cal.date(from: endComps) ?? now
        lastNight = await fetchSleep(from: start, to: end)
    }

    func fetchSleepHistory(days: Int = 30) async {
        var results: [SleepData] = []
        let cal = Calendar.current
        let now = Date()
        for i in 1...days {
            guard let date = cal.date(byAdding: .day, value: -i, to: now) else { continue }
            var startComps = cal.dateComponents([.year, .month, .day], from: date)
            startComps.hour = 18
            let dayAt6pm = cal.date(from: startComps) ?? date
            let start = cal.date(byAdding: .day, value: -1, to: dayAt6pm) ?? date
            var endComps = cal.dateComponents([.year, .month, .day], from: date)
            endComps.hour = 12
            let end = cal.date(from: endComps) ?? date
            let data = await fetchSleep(from: start, to: end)
            if data.quality.hasAnyData { results.append(data) }
        }
        history = results
    }

    private func fetchSleep(from start: Date, to end: Date) async -> SleepData {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { [weak self] _, samples, _ in
                guard let self else {
                    continuation.resume(returning: .empty(date: start))
                    return
                }
                let categorySamples = samples as? [HKCategorySample] ?? []
                if categorySamples.isEmpty {
                    continuation.resume(returning: .empty(date: start))
                } else {
                    continuation.resume(returning: self.process(categorySamples, date: start))
                }
            }
            store.execute(query)
        }
    }

    nonisolated private func process(_ samples: [HKCategorySample], date: Date) -> SleepData {
        var deep = 0, core = 0, rem = 0, awake = 0, inBed = 0

        let hasStageData = samples.contains {
            guard let v = HKCategoryValueSleepAnalysis(rawValue: $0.value) else { return false }
            return v == .asleepDeep || v == .asleepCore || v == .asleepREM
        }

        let primary: [HKCategorySample]
        if hasStageData {
            primary = samples.filter {
                guard let v = HKCategoryValueSleepAnalysis(rawValue: $0.value) else { return false }
                return v == .asleepDeep || v == .asleepCore || v == .asleepREM || v == .awake
            }
        } else {
            primary = samples
        }

        for s in primary {
            guard let v = HKCategoryValueSleepAnalysis(rawValue: s.value) else { continue }
            let mins = Int(s.endDate.timeIntervalSince(s.startDate) / 60)
            switch v {
            case .asleepDeep: deep += mins
            case .asleepCore: core += mins
            case .asleepREM:  rem += mins
            case .awake:      awake += 1
            case .inBed:      inBed += mins
            default: break
            }
        }

        let total = deep + core + rem
        if inBed == 0 {
            inBed = total > 0 ? total : Int((samples.last?.endDate.timeIntervalSince(samples.first?.startDate ?? date) ?? 0) / 60)
        }

        let quality = detectQuality(samples: samples, hasStages: total > 0, hasAwake: awake > 0)
        let score = HealthKitManager.calculateScore(
            deep: deep, core: core, rem: rem,
            total: total, inBed: inBed,
            awakeCount: awake, quality: quality
        )

        return SleepData(
            date: date, quality: quality,
            inBedMinutes: inBed, totalSleepMinutes: total,
            bedtime: samples.first?.startDate ?? date,
            wakeTime: samples.last?.endDate ?? date,
            score: score,
            deepMinutes: deep, coreMinutes: core,
            remMinutes: rem, awakeCount: awake
        )
    }

    nonisolated private func detectQuality(samples: [HKCategorySample], hasStages: Bool, hasAwake: Bool) -> DataQuality {
        if hasStages { return .full }
        // .partial = awake samples from an Apple Watch source (bundle + device model check)
        let hasWatchAwake = hasAwake && samples.contains {
            guard HKCategoryValueSleepAnalysis(rawValue: $0.value) == .awake else { return false }
            let bundleOK = $0.sourceRevision.source.bundleIdentifier.hasPrefix("com.apple.health")
            let deviceOK = $0.device?.model?.lowercased().contains("watch") ?? false
            return bundleOK && deviceOK
        }
        if hasWatchAwake { return .partial }
        let hasInBed = samples.contains {
            HKCategoryValueSleepAnalysis(rawValue: $0.value) == .inBed
        }
        return hasInBed ? .basic : .noData
    }

    // Static so it's directly testable without a HealthKit store
    nonisolated static func calculateScore(deep: Int, core: Int, rem: Int,
                                total: Int, inBed: Int,
                                awakeCount: Int, quality: DataQuality) -> Int {
        switch quality {
        case .noData:
            return 0
        case .basic:
            return min(75, Int(Double(inBed) / 60.0 / 8.0 * 75))
        case .partial:
            var score = 0
            score += min(40, Int(Double(inBed) / 60.0 / 8.0 * 40))
            score += max(0, 10 - awakeCount * 2)
            return min(100, score)
        case .full:
            guard total > 0 else { return 0 }
            var score = 0
            score += min(40, Int(Double(total) / 60.0 / 8.0 * 40))
            score += min(30, Int(Double(deep) / Double(total) / 0.20 * 30))
            score += min(20, Int(Double(rem) / Double(total) / 0.25 * 20))
            score += max(0, 10 - awakeCount * 2)
            return min(100, score)
        }
    }
}
