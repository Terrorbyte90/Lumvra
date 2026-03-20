import Foundation

struct EveningCheckin: Codable {
    // Always Calendar.current.startOfDay(for: Date())
    let date: Date
    var hadAlcohol: Bool
    var hadCoffeeAfter2pm: Bool
    var exercised: Bool
}
