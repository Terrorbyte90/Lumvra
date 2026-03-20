import Foundation

struct UserProfile: Codable {
    let id: UUID
    var targetBedtime: Date
    var targetWakeTime: Date
    var targetSleepHours: Double
    var alcoholTracking: Bool
    var coffeeTracking: Bool
    var exerciseTracking: Bool
    var isPremium: Bool
    var hasSeenWatchPrompt: Bool
    var language: String
    var morningNotificationsEnabled: Bool
    var eveningNotificationsEnabled: Bool

    static var `default`: UserProfile {
        let cal = Calendar.current
        let bedtime = cal.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
        let wakeTime = cal.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        return UserProfile(
            id: UUID(),
            targetBedtime: bedtime,
            targetWakeTime: wakeTime,
            targetSleepHours: 8.0,
            alcoholTracking: true,
            coffeeTracking: true,
            exerciseTracking: true,
            isPremium: false,
            hasSeenWatchPrompt: false,
            language: "system",
            morningNotificationsEnabled: true,
            eveningNotificationsEnabled: true
        )
    }
}
