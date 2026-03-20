import Foundation
import SwiftUI

@MainActor
class LanguageManager: ObservableObject {
    @AppStorage("selectedLanguage") var selectedLanguage: String = "system"

    var resolvedLanguage: String {
        switch selectedLanguage {
        case "sv": return "Swedish"
        case "en": return "English"
        default:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            return code == "sv" ? "Swedish" : "English"
        }
    }

    var isSv: Bool { resolvedLanguage == "Swedish" }

    func t(en: String, sv: String) -> String { isSv ? sv : en }
}
