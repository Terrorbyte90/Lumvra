import Foundation

struct SleepInsight: Codable {
    let id: UUID
    let date: Date
    let morningInsight: String
    let bedtimeRecommendation: String
    let recommendedBedtime: Date
    let sleepScore: Int
    let language: String
    let dataQuality: DataQuality
    let generatedAt: Date
}
