import Foundation

struct SleepData: Codable {
    let date: Date
    let quality: DataQuality
    let inBedMinutes: Int
    let totalSleepMinutes: Int
    let bedtime: Date
    let wakeTime: Date
    let score: Int
    let deepMinutes: Int
    let coreMinutes: Int
    let remMinutes: Int
    let awakeCount: Int

    var hoursSlept: Double {
        Double(quality.hasStages ? totalSleepMinutes : inBedMinutes) / 60.0
    }

    var deepPercent: Double {
        guard totalSleepMinutes > 0 else { return 0 }
        return Double(deepMinutes) / Double(totalSleepMinutes)
    }

    var remPercent: Double {
        guard totalSleepMinutes > 0 else { return 0 }
        return Double(remMinutes) / Double(totalSleepMinutes)
    }

    static func empty(date: Date) -> SleepData {
        SleepData(date: date, quality: .noData, inBedMinutes: 0,
                  totalSleepMinutes: 0, bedtime: date, wakeTime: date,
                  score: 0, deepMinutes: 0, coreMinutes: 0,
                  remMinutes: 0, awakeCount: 0)
    }
}
