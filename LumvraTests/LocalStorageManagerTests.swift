import Testing
@testable import Lumvra

@MainActor
struct LocalStorageManagerTests {
    func makeSUT() -> LocalStorageManager {
        let sut = LocalStorageManager()
        sut.clearAll()
        return sut
    }

    @Test func saveAndLoadProfile() {
        let sut = makeSUT()
        let profile = UserProfile.default
        sut.saveProfile(profile)
        let loaded = sut.loadProfile()
        #expect(loaded?.id == profile.id)
    }

    @Test func saveAndLoadCheckin() {
        let sut = makeSUT()
        let today = Calendar.current.startOfDay(for: Date())
        let checkin = EveningCheckin(date: today, hadAlcohol: true, hadCoffeeAfter2pm: false, exercised: true)
        sut.saveCheckin(checkin)
        let loaded = sut.loadCheckin(for: today)
        #expect(loaded?.hadAlcohol == true)
        #expect(loaded?.exercised == true)
    }

    @Test func checkinNormalisesDate() {
        let sut = makeSUT()
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let checkin = EveningCheckin(date: noon, hadAlcohol: false, hadCoffeeAfter2pm: true, exercised: false)
        sut.saveCheckin(checkin)
        let loaded = sut.loadCheckin(for: Date())
        #expect(loaded?.hadCoffeeAfter2pm == true)
    }

    @Test func cacheAndLoadInsight() {
        let sut = makeSUT()
        let today = Calendar.current.startOfDay(for: Date())
        let insight = SleepInsight(id: UUID(), date: today,
                                   morningInsight: "Test", bedtimeRecommendation: "22:30",
                                   recommendedBedtime: today, sleepScore: 75,
                                   language: "English", dataQuality: .full, generatedAt: today)
        sut.cacheInsight(insight)
        let loaded = sut.loadCachedInsight(for: Date())
        #expect(loaded?.morningInsight == "Test")
    }

    @Test func clearAllRemovesEverything() {
        let sut = makeSUT()
        sut.saveProfile(.default)
        sut.clearAll()
        #expect(sut.loadProfile() == nil)
    }

    @Test func deviceIdIsPersistent() {
        let sut = makeSUT()
        let id1 = sut.loadDeviceId()
        let id2 = sut.loadDeviceId()
        #expect(id1 == id2)
    }
}
