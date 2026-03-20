import Foundation

// No-op stub — same API surface as LocalStorageManager.
// Activate by replacing no-ops with real Supabase calls.
@MainActor
class SupabaseManager: SleepStorage {
    func loadProfile() -> UserProfile? { nil }
    func saveProfile(_ profile: UserProfile) {}
    func loadCheckin(for date: Date) -> EveningCheckin? { nil }
    func saveCheckin(_ checkin: EveningCheckin) {}
    func loadCachedInsight(for date: Date) -> SleepInsight? { nil }
    func cacheInsight(_ insight: SleepInsight) {}
    func clearAll() {}
    func loadDeviceId() -> UUID { UUID() }
}
