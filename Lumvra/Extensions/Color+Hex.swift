import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let lvBackground = Color(hex: "#0f1117")
    static let lvSurface    = Color(hex: "#1a1f2e")
    static let lvSurface2   = Color(hex: "#232940")
    static let lvPurple     = Color(hex: "#7f77dd")
    static let lvTeal       = Color(hex: "#1d9e75")
    static let lvAmber      = Color(hex: "#ef9f27")
    static let lvRed        = Color(hex: "#e05c5c")
    static let lvTextPri    = Color.white
    static let lvTextSec    = Color(hex: "#8b92a5")
    static let lvTextTert   = Color(hex: "#4e5468")

    static func forScore(_ score: Int) -> Color {
        score >= 70 ? .lvTeal : score >= 40 ? .lvAmber : .lvRed
    }
}
