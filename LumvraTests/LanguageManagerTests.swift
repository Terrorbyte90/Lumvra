import Testing
@testable import Lumvra

@MainActor
struct LanguageManagerTests {
    @Test func englishResolvesEnglish() {
        let lm = LanguageManager()
        lm.selectedLanguage = "en"
        #expect(lm.resolvedLanguage == "English")
        #expect(lm.isSv == false)
    }

    @Test func svResolvesSwedish() {
        let lm = LanguageManager()
        lm.selectedLanguage = "sv"
        #expect(lm.resolvedLanguage == "Swedish")
        #expect(lm.isSv == true)
    }

    @Test func tHelperReturnsCorrectString() {
        let lm = LanguageManager()
        lm.selectedLanguage = "sv"
        #expect(lm.t(en: "Hello", sv: "Hej") == "Hej")
        lm.selectedLanguage = "en"
        #expect(lm.t(en: "Hello", sv: "Hej") == "Hello")
    }
}
