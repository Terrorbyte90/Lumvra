import UserNotifications
import Foundation

@MainActor
class NotificationManager: ObservableObject {
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func reschedule(profile: UserProfile, language: String) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let isSv = language == "Swedish"

        if profile.morningNotificationsEnabled {
            let wakeComponents = Calendar.current.dateComponents([.hour, .minute], from: profile.targetWakeTime)
            var hour = wakeComponents.hour ?? 7
            var minute = (wakeComponents.minute ?? 0) + 15
            if minute >= 60 { minute -= 60; hour = (hour + 1) % 24 }
            schedule(
                id: "lumvra.morning",
                title: isSv ? "God morgon 🌙" : "Good morning 🌙",
                body: isSv ? "Din sömninsikt för igår natt är redo." : "Your sleep insight from last night is ready.",
                hour: hour, minute: minute
            )
        }

        if profile.eveningNotificationsEnabled {
            let bedComponents = Calendar.current.dateComponents([.hour, .minute], from: profile.targetBedtime)
            var hour = bedComponents.hour ?? 22
            var minute = (bedComponents.minute ?? 30) - 60
            if minute < 0 { minute += 60; hour = (hour - 1 + 24) % 24 }
            schedule(
                id: "lumvra.evening",
                title: isSv ? "Kvällskoll 🌙" : "Evening check-in 🌙",
                body: isSv ? "Logga din dag för bättre sömninsikter." : "Log your day for better sleep insights.",
                hour: hour, minute: minute
            )
        }
    }

    private func schedule(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
