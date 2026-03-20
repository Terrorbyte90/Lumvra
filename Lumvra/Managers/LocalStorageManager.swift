import Foundation
import Security

protocol SleepStorage {
    func loadProfile() -> UserProfile?
    func saveProfile(_ profile: UserProfile)
    func loadCheckin(for date: Date) -> EveningCheckin?
    func saveCheckin(_ checkin: EveningCheckin)
    func loadCachedInsight(for date: Date) -> SleepInsight?
    func cacheInsight(_ insight: SleepInsight)
    func clearAll()
    func loadDeviceId() -> UUID
}

@MainActor
class LocalStorageManager: ObservableObject, SleepStorage {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let profileKey = "userProfile"
    private let checkinsKey = "eveningCheckins"
    private let insightCacheKey = "insightCache"

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }

    func loadProfile() -> UserProfile? {
        guard let data = defaults.data(forKey: profileKey) else { return nil }
        return try? decoder.decode(UserProfile.self, from: data)
    }

    func saveProfile(_ profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: profileKey)
        }
    }

    func loadCheckin(for date: Date) -> EveningCheckin? {
        let key = dateFormatter.string(from: Calendar.current.startOfDay(for: date))
        guard let data = defaults.data(forKey: checkinsKey),
              let dict = try? decoder.decode([String: EveningCheckin].self, from: data) else { return nil }
        return dict[key]
    }

    func saveCheckin(_ checkin: EveningCheckin) {
        let key = dateFormatter.string(from: Calendar.current.startOfDay(for: checkin.date))
        var dict: [String: EveningCheckin] = [:]
        if let data = defaults.data(forKey: checkinsKey),
           let existing = try? decoder.decode([String: EveningCheckin].self, from: data) {
            dict = existing
        }
        dict[key] = checkin
        if let data = try? encoder.encode(dict) {
            defaults.set(data, forKey: checkinsKey)
        }
    }

    func loadCachedInsight(for date: Date) -> SleepInsight? {
        let key = dateFormatter.string(from: Calendar.current.startOfDay(for: date))
        guard let data = defaults.data(forKey: insightCacheKey),
              let dict = try? decoder.decode([String: SleepInsight].self, from: data) else { return nil }
        return dict[key]
    }

    func cacheInsight(_ insight: SleepInsight) {
        let key = dateFormatter.string(from: Calendar.current.startOfDay(for: insight.date))
        var dict: [String: SleepInsight] = [:]
        if let data = defaults.data(forKey: insightCacheKey),
           let existing = try? decoder.decode([String: SleepInsight].self, from: data) {
            dict = existing
        }
        dict[key] = insight
        if let data = try? encoder.encode(dict) {
            defaults.set(data, forKey: insightCacheKey)
        }
    }

    func clearAll() {
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: checkinsKey)
        defaults.removeObject(forKey: insightCacheKey)
        deleteDeviceIdFromKeychain()
    }

    func loadDeviceId() -> UUID {
        let service = "com.terrorbyte90.lumvra"
        let account = "deviceId"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let str = String(data: data, encoding: .utf8),
           let uuid = UUID(uuidString: str) {
            return uuid
        }
        let newId = UUID()
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: newId.uuidString.data(using: .utf8)!
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        return newId
    }

    private func deleteDeviceIdFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.terrorbyte90.lumvra",
            kSecAttrAccount as String: "deviceId"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
