import Foundation

enum DataQuality: String, Codable {
    case full, partial, basic, noData

    var hasStages: Bool { self == .full }
    var hasAnyData: Bool { self != .noData }

    func label(isSv: Bool) -> String {
        switch self {
        case .full:    return "Apple Watch"
        case .partial: return isSv ? "Begränsad data" : "Limited data"
        case .basic:   return isSv ? "Tid i säng" : "Time in bed"
        case .noData:  return isSv ? "Ingen data" : "No data"
        }
    }
}
