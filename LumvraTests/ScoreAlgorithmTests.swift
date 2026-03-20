import Testing
@testable import Lumvra

struct ScoreAlgorithmTests {
    @Test func basicScoreCappedAt75() {
        let score = HealthKitManager.calculateScore(
            deep: 0, core: 0, rem: 0, total: 0,
            inBed: 480, awakeCount: 0, quality: .basic)
        #expect(score == 75)
    }

    @Test func basicScoreProportional() {
        let score = HealthKitManager.calculateScore(
            deep: 0, core: 0, rem: 0, total: 0,
            inBed: 240, awakeCount: 0, quality: .basic)
        #expect(score == 37)
    }

    @Test func fullScorePerfectNight() {
        let score = HealthKitManager.calculateScore(
            deep: 96, core: 264, rem: 120, total: 480,
            inBed: 480, awakeCount: 0, quality: .full)
        #expect(score == 100)
    }

    @Test func fullScorePenalisesAwakenings() {
        let score = HealthKitManager.calculateScore(
            deep: 96, core: 264, rem: 120, total: 480,
            inBed: 480, awakeCount: 3, quality: .full)
        #expect(score == 94)
    }

    @Test func partialScoreUsesInBed() {
        let score = HealthKitManager.calculateScore(
            deep: 0, core: 0, rem: 0, total: 0,
            inBed: 480, awakeCount: 1, quality: .partial)
        #expect(score == 48)
    }

    @Test func noDataReturnsZero() {
        let score = HealthKitManager.calculateScore(
            deep: 0, core: 0, rem: 0, total: 0,
            inBed: 0, awakeCount: 0, quality: .noData)
        #expect(score == 0)
    }
}
