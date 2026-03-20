import Testing
@testable import Lumvra

struct DataQualityTests {
    @Test func fullHasStages() {
        #expect(DataQuality.full.hasStages == true)
    }
    @Test func partialNoStages() {
        #expect(DataQuality.partial.hasStages == false)
    }
    @Test func noDataHasNoData() {
        #expect(DataQuality.noData.hasAnyData == false)
    }
    @Test func labelEnglish() {
        #expect(DataQuality.basic.label(isSv: false) == "Time in bed")
    }
    @Test func labelSwedish() {
        #expect(DataQuality.basic.label(isSv: true) == "Tid i säng")
    }
}
