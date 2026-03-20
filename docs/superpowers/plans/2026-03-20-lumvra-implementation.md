# Lumvra Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete Lumvra iOS sleep coach app — HealthKit reader, AI morning insights via Claude Haiku, RevenueCat subscriptions, local persistence, en/sv localisation — ready for App Store submission.

**Architecture:** SwiftUI app with `@EnvironmentObject` managers injected at root. All persistence via `LocalStorageManager` (UserDefaults) during development; `SupabaseManager` is a no-op stub with the same protocol. HealthKit read-only. AI via direct REST to Anthropic.

**Tech Stack:** Swift 6.1.2, SwiftUI, iOS 17+, HealthKit, RevenueCat 5.x (SPM), xcodegen, Claude Haiku 4.5 REST API.

---

## File Map

```
Lumvra/
├── project.yml                          # xcodegen config
├── .gitignore
├── Config.example.plist
├── Lumvra/
│   ├── LumvraApp.swift
│   ├── ContentView.swift
│   ├── Config/
│   │   └── ConfigManager.swift
│   ├── Extensions/
│   │   └── Color+Hex.swift
│   ├── Models/
│   │   ├── DataQuality.swift
│   │   ├── SleepData.swift
│   │   ├── SleepInsight.swift
│   │   ├── EveningCheckin.swift
│   │   ├── UserProfile.swift
│   │   └── UserState.swift
│   ├── Managers/
│   │   ├── LocalStorageManager.swift
│   │   ├── SupabaseManager.swift
│   │   ├── LanguageManager.swift
│   │   ├── HealthKitManager.swift
│   │   ├── NotificationManager.swift
│   │   └── AIManager.swift
│   ├── Views/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingContainerView.swift
│   │   │   ├── WelcomeView.swift
│   │   │   ├── HealthKitPermissionView.swift
│   │   │   ├── NotificationPermissionView.swift
│   │   │   └── LoadingDataView.swift
│   │   ├── Main/
│   │   │   ├── MainTabView.swift
│   │   │   ├── MorningView.swift
│   │   │   ├── EveningView.swift
│   │   │   └── TrendsView.swift
│   │   ├── Settings/
│   │   │   └── SettingsView.swift
│   │   └── Paywall/
│   │       └── PaywallView.swift
│   ├── Components/
│   │   ├── SleepScoreRing.swift
│   │   ├── InsightCard.swift
│   │   ├── StageBar.swift
│   │   ├── CheckInButton.swift
│   │   ├── WatchUpgradePrompt.swift
│   │   └── DataQualityBadge.swift
│   ├── Resources/
│   │   └── Localizable.xcstrings
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/
└── LumvraTests/
    ├── ScoreAlgorithmTests.swift
    ├── LanguageManagerTests.swift
    ├── LocalStorageManagerTests.swift
    └── DataQualityTests.swift
```

---

## Phase 1 — Project Setup

### Task 1: GitHub repo

**Files:** none (CLI only)

- [ ] Create public repo:
```bash
gh repo create Lumvra --public --description "AI sleep coach for iOS" --clone=false
```
- [ ] Verify:
```bash
gh repo view Terrorbyte90/Lumvra
```

---

### Task 2: xcodegen project.yml + .gitignore

**Files:**
- Create: `project.yml`
- Create: `.gitignore`
- Create: `Config.example.plist`

- [ ] Write `project.yml`:
```yaml
name: Lumvra
options:
  bundleIdPrefix: com.terrorbyte90
  deploymentTarget:
    iOS: "17.0"
  defaultConfig: Debug
  xcodeVersion: "16.0"

settings:
  SWIFT_VERSION: "6"
  SWIFT_STRICT_CONCURRENCY: complete
  IPHONEOS_DEPLOYMENT_TARGET: 17.0
  ENABLE_USER_SCRIPT_SANDBOXING: NO

targets:
  Lumvra:
    type: application
    platform: iOS
    sources:
      - path: Lumvra
        excludes:
          - "**/.DS_Store"
    info:
      path: Lumvra/Info.plist
      properties:
        CFBundleDisplayName: Lumvra
        NSHealthShareUsageDescription: "Lumvra reads your sleep data from Apple Health to generate personalised insights. Your data never leaves your device."
        UILaunchStoryboardName: ""
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
          UISceneConfigurations: {}
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.terrorbyte90.lumvra
      MARKETING_VERSION: "1.0"
      CURRENT_PROJECT_VERSION: "1"
      DEVELOPMENT_TEAM: ""
      CODE_SIGN_STYLE: Automatic
    dependencies:
      - package: RevenueCat
        product: RevenueCat
    entitlements:
      path: Lumvra/Lumvra.entitlements
      properties:
        com.apple.developer.healthkit: true
    scheme:
      testTargets:
        - LumvraTests

  LumvraTests:
    type: bundle.unit-test
    platform: iOS
    sources: [LumvraTests]
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.terrorbyte90.lumvraTests
    dependencies:
      - target: Lumvra

packages:
  RevenueCat:
    url: https://github.com/RevenueCat/purchases-ios.git
    from: 5.0.0
```

- [ ] Write `.gitignore`:
```
Lumvra/Config/Config.plist
*.xcuserstate
DerivedData/
.DS_Store
*.xcworkspace/xcuserdata/
xcuserdata/
.build/
```

- [ ] Write `Config.example.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ANTHROPIC_API_KEY</key>
    <string>sk-ant-REPLACE_ME</string>
    <key>SUPABASE_URL</key>
    <string>https://REPLACE_ME.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>REPLACE_ME</string>
    <key>REVENUECAT_API_KEY</key>
    <string>appl_REPLACE_ME</string>
</dict>
</plist>
```

---

### Task 3: Create folder structure + run xcodegen + initial commit

**Files:** all source folders

- [ ] Create all source directories and entitlements file:
```bash
cd "/Users/tedsvard/Library/Mobile Documents/com~apple~CloudDocs/Lumvra"
mkdir -p Lumvra/Config Lumvra/Extensions Lumvra/Models Lumvra/Managers
mkdir -p Lumvra/Views/Onboarding Lumvra/Views/Main Lumvra/Views/Settings Lumvra/Views/Paywall
mkdir -p Lumvra/Components Lumvra/Resources
mkdir -p Lumvra/Assets.xcassets/AppIcon.appiconset
mkdir -p LumvraTests
```

- [ ] Create `Lumvra/Lumvra.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.healthkit</key>
    <true/>
</dict>
</plist>
```

- [ ] Copy Config.example.plist to actual Config.plist (fill in real keys before testing AI/RevenueCat):
```bash
cp Config.example.plist "Lumvra/Config/Config.plist"
```

- [ ] Run xcodegen:
```bash
cd "/Users/tedsvard/Library/Mobile Documents/com~apple~CloudDocs/Lumvra"
xcodegen generate
```
Expected: `Generating project Lumvra` with no errors.

- [ ] Init git, connect remote, initial commit:
```bash
cd "/Users/tedsvard/Library/Mobile Documents/com~apple~CloudDocs/Lumvra"
git init
git remote add origin https://github.com/Terrorbyte90/Lumvra.git
git add project.yml .gitignore Config.example.plist docs/
git commit -m "chore: initial project scaffold with xcodegen"
git branch -M main
git push -u origin main
```

---

## Phase 2 — Models & Extensions

### Task 4: Color+Hex.swift + ConfigManager

**Files:**
- Create: `Lumvra/Extensions/Color+Hex.swift`
- Create: `Lumvra/Config/ConfigManager.swift`

- [ ] Write `Lumvra/Extensions/Color+Hex.swift`:
```swift
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
```

- [ ] Write `Lumvra/Config/ConfigManager.swift`:
```swift
import Foundation

enum ConfigManager {
    static func value(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return ""
        }
        return dict[key] as? String ?? ""
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Extensions/ Lumvra/Config/ConfigManager.swift
git commit -m "feat: add Color palette extensions and ConfigManager"
```

---

### Task 5: DataQuality + SleepData models

**Files:**
- Create: `Lumvra/Models/DataQuality.swift`
- Create: `Lumvra/Models/SleepData.swift`
- Create: `LumvraTests/DataQualityTests.swift`

- [ ] Write `Lumvra/Models/DataQuality.swift`:
```swift
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
```

- [ ] Write `Lumvra/Models/SleepData.swift`:
```swift
import Foundation

struct SleepData: Codable {
    let date: Date
    let quality: DataQuality
    let inBedMinutes: Int
    let totalSleepMinutes: Int
    let bedtime: Date
    let wakeTime: Date
    let score: Int
    let deepMinutes: Int
    let coreMinutes: Int
    let remMinutes: Int
    let awakeCount: Int

    var hoursSlept: Double {
        Double(quality.hasStages ? totalSleepMinutes : inBedMinutes) / 60.0
    }

    var deepPercent: Double {
        guard totalSleepMinutes > 0 else { return 0 }
        return Double(deepMinutes) / Double(totalSleepMinutes)
    }

    var remPercent: Double {
        guard totalSleepMinutes > 0 else { return 0 }
        return Double(remMinutes) / Double(totalSleepMinutes)
    }

    static func empty(date: Date) -> SleepData {
        SleepData(date: date, quality: .noData, inBedMinutes: 0,
                  totalSleepMinutes: 0, bedtime: date, wakeTime: date,
                  score: 0, deepMinutes: 0, coreMinutes: 0,
                  remMinutes: 0, awakeCount: 0)
    }
}
```

- [ ] Write `LumvraTests/DataQualityTests.swift`:
```swift
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
```

- [ ] Build + run tests:
```bash
cd "/Users/tedsvard/Library/Mobile Documents/com~apple~CloudDocs/Lumvra"
xcodebuild test -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:LumvraTests/DataQualityTests 2>&1 | tail -20
```
Expected: `** TEST SUCCEEDED **`

- [ ] Commit:
```bash
git add Lumvra/Models/DataQuality.swift Lumvra/Models/SleepData.swift LumvraTests/DataQualityTests.swift
git commit -m "feat: add DataQuality and SleepData models"
```

---

### Task 6: SleepInsight + EveningCheckin models

**Files:**
- Create: `Lumvra/Models/SleepInsight.swift`
- Create: `Lumvra/Models/EveningCheckin.swift`

- [ ] Write `Lumvra/Models/SleepInsight.swift`:
```swift
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
```

- [ ] Write `Lumvra/Models/EveningCheckin.swift`:
```swift
import Foundation

struct EveningCheckin: Codable {
    // Always Calendar.current.startOfDay(for: Date())
    let date: Date
    var hadAlcohol: Bool
    var hadCoffeeAfter2pm: Bool
    var exercised: Bool
}
```

- [ ] Commit:
```bash
git add Lumvra/Models/SleepInsight.swift Lumvra/Models/EveningCheckin.swift
git commit -m "feat: add SleepInsight and EveningCheckin models"
```

---

### Task 7: UserProfile + UserState

**Files:**
- Create: `Lumvra/Models/UserProfile.swift`
- Create: `Lumvra/Models/UserState.swift`

- [ ] Write `Lumvra/Models/UserProfile.swift`:
```swift
import Foundation

struct UserProfile: Codable {
    let id: UUID
    var targetBedtime: Date
    var targetWakeTime: Date
    var targetSleepHours: Double
    var alcoholTracking: Bool
    var coffeeTracking: Bool
    var exerciseTracking: Bool
    var isPremium: Bool
    var hasSeenWatchPrompt: Bool
    var language: String
    var morningNotificationsEnabled: Bool
    var eveningNotificationsEnabled: Bool

    static var `default`: UserProfile {
        let cal = Calendar.current
        let bedtime = cal.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
        let wakeTime = cal.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        return UserProfile(
            id: UUID(),
            targetBedtime: bedtime,
            targetWakeTime: wakeTime,
            targetSleepHours: 8.0,
            alcoholTracking: true,
            coffeeTracking: true,
            exerciseTracking: true,
            isPremium: false,
            hasSeenWatchPrompt: false,
            language: "system",
            morningNotificationsEnabled: true,
            eveningNotificationsEnabled: true
        )
    }
}
```

- [ ] Write `Lumvra/Models/UserState.swift`:
```swift
import Foundation
import RevenueCat

@MainActor
class UserState: ObservableObject {
    @Published var profile: UserProfile
    @Published var isPremium: Bool = false

    private let storage: LocalStorageManager

    init(storage: LocalStorageManager) {
        self.storage = storage
        self.profile = storage.loadProfile() ?? .default
        self.isPremium = profile.isPremium
    }

    func refreshPremiumStatus() async {
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        let active = info.entitlements["premium"]?.isActive == true
                  || info.entitlements["lifetime"]?.isActive == true
        isPremium = active
        profile.isPremium = active
        storage.saveProfile(profile)
    }

    func saveProfile() {
        storage.saveProfile(profile)
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Models/UserProfile.swift Lumvra/Models/UserState.swift
git commit -m "feat: add UserProfile and UserState models"
```

---

## Phase 3 — Managers

### Task 8: LocalStorageManager + SupabaseManager stub

**Files:**
- Create: `Lumvra/Managers/LocalStorageManager.swift`
- Create: `Lumvra/Managers/SupabaseManager.swift`
- Create: `LumvraTests/LocalStorageManagerTests.swift`

- [ ] Write `Lumvra/Managers/LocalStorageManager.swift`:
```swift
import Foundation
import Security

protocol SleepStorage {
    func loadProfile() -> UserProfile?
    func saveProfile(_ profile: UserProfile)
    func loadCheckin(for date: Date) -> EveningCheckin?
    func saveCheckin(_ checkin: EveningCheckin)
    func loadCachedInsight(for date: Date) -> SleepInsight?
    func cacheInsight(_ insight: SleepInsight)
    func clearAll()
    func loadDeviceId() -> UUID
}

@MainActor
class LocalStorageManager: ObservableObject, SleepStorage {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let profileKey = "userProfile"
    private let checkinsKey = "eveningCheckins"
    private let insightCacheKey = "insightCache"

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }

    func loadProfile() -> UserProfile? {
        guard let data = defaults.data(forKey: profileKey) else { return nil }
        return try? decoder.decode(UserProfile.self, from: data)
    }

    func saveProfile(_ profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: profileKey)
        }
    }

    func loadCheckin(for date: Date) -> EveningCheckin? {
        let key = dateFormatter.string(from: Calendar.current.startOfDay(for: date))
        guard let data = defaults.data(forKey: checkinsKey),
              let dict = try? decoder.decode([String: EveningCheckin].self, from: data) else { return nil }
        return dict[key]
    }

    func saveCheckin(_ checkin: EveningCheckin) {
        let key = dateFormatter.string(from: Calendar.current.startOfDay(for: checkin.date))
        var dict: [String: EveningCheckin] = [:]
        if let data = defaults.data(forKey: checkinsKey),
           let existing = try? decoder.decode([String: EveningCheckin].self, from: data) {
            dict = existing
        }
        dict[key] = checkin
        if let data = try? encoder.encode(dict) {
            defaults.set(data, forKey: checkinsKey)
        }
    }

    func loadCachedInsight(for date: Date) -> SleepInsight? {
        let key = dateFormatter.string(from: Calendar.current.startOfDay(for: date))
        guard let data = defaults.data(forKey: insightCacheKey),
              let dict = try? decoder.decode([String: SleepInsight].self, from: data) else { return nil }
        return dict[key]
    }

    func cacheInsight(_ insight: SleepInsight) {
        let key = dateFormatter.string(from: Calendar.current.startOfDay(for: insight.date))
        var dict: [String: SleepInsight] = [:]
        if let data = defaults.data(forKey: insightCacheKey),
           let existing = try? decoder.decode([String: SleepInsight].self, from: data) {
            dict = existing
        }
        dict[key] = insight
        if let data = try? encoder.encode(dict) {
            defaults.set(data, forKey: insightCacheKey)
        }
    }

    func clearAll() {
        defaults.removeObject(forKey: profileKey)
        defaults.removeObject(forKey: checkinsKey)
        defaults.removeObject(forKey: insightCacheKey)
        deleteDeviceIdFromKeychain()
    }

    func loadDeviceId() -> UUID {
        let service = "com.terrorbyte90.lumvra"
        let account = "deviceId"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let str = String(data: data, encoding: .utf8),
           let uuid = UUID(uuidString: str) {
            return uuid
        }
        let newId = UUID()
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: newId.uuidString.data(using: .utf8)!
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        return newId
    }

    private func deleteDeviceIdFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.terrorbyte90.lumvra",
            kSecAttrAccount as String: "deviceId"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

- [ ] Write `Lumvra/Managers/SupabaseManager.swift`:
```swift
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
```

- [ ] Write `LumvraTests/LocalStorageManagerTests.swift`:
```swift
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
```

- [ ] Run tests:
```bash
cd "/Users/tedsvard/Library/Mobile Documents/com~apple~CloudDocs/Lumvra"
xcodebuild test -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:LumvraTests/LocalStorageManagerTests 2>&1 | tail -20
```

- [ ] Commit:
```bash
git add Lumvra/Managers/LocalStorageManager.swift Lumvra/Managers/SupabaseManager.swift LumvraTests/LocalStorageManagerTests.swift
git commit -m "feat: add LocalStorageManager with SleepStorage protocol and SupabaseManager stub"
```

---

### Task 9: LanguageManager

**Files:**
- Create: `Lumvra/Managers/LanguageManager.swift`
- Create: `LumvraTests/LanguageManagerTests.swift`

- [ ] Write `Lumvra/Managers/LanguageManager.swift`:
```swift
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
```

- [ ] Write `LumvraTests/LanguageManagerTests.swift`:
```swift
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
```

- [ ] Run tests:
```bash
xcodebuild test -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:LumvraTests/LanguageManagerTests 2>&1 | tail -20
```

- [ ] Commit:
```bash
git add Lumvra/Managers/LanguageManager.swift LumvraTests/LanguageManagerTests.swift
git commit -m "feat: add LanguageManager with en/sv resolution"
```

---

### Task 10: HealthKitManager + score algorithm

**Files:**
- Create: `Lumvra/Managers/HealthKitManager.swift`
- Create: `LumvraTests/ScoreAlgorithmTests.swift`

- [ ] Write `LumvraTests/ScoreAlgorithmTests.swift` first (TDD):
```swift
import Testing
@testable import Lumvra

struct ScoreAlgorithmTests {
    @Test func basicScoreCappedAt75() {
        // 8h in bed = 75
        let score = HealthKitManager.calculateScore(
            deep: 0, core: 0, rem: 0, total: 0,
            inBed: 480, awakeCount: 0, quality: .basic)
        #expect(score == 75)
    }

    @Test func basicScoreProportional() {
        // 4h in bed = ~37
        let score = HealthKitManager.calculateScore(
            deep: 0, core: 0, rem: 0, total: 0,
            inBed: 240, awakeCount: 0, quality: .basic)
        #expect(score == 37)
    }

    @Test func fullScorePerfectNight() {
        // 8h total, 20% deep (96m), 25% REM (120m), 0 awakenings
        let score = HealthKitManager.calculateScore(
            deep: 96, core: 264, rem: 120, total: 480,
            inBed: 480, awakeCount: 0, quality: .full)
        #expect(score == 100)
    }

    @Test func fullScorePenalisesAwakenings() {
        let score = HealthKitManager.calculateScore(
            deep: 96, core: 264, rem: 120, total: 480,
            inBed: 480, awakeCount: 3, quality: .full)
        #expect(score == 94) // -6 for 3 awakenings
    }

    @Test func partialScoreUsesInBed() {
        let score = HealthKitManager.calculateScore(
            deep: 0, core: 0, rem: 0, total: 0,
            inBed: 480, awakeCount: 1, quality: .partial)
        #expect(score == 48) // 40 duration + 8 awake
    }

    @Test func noDataReturnsZero() {
        let score = HealthKitManager.calculateScore(
            deep: 0, core: 0, rem: 0, total: 0,
            inBed: 0, awakeCount: 0, quality: .noData)
        #expect(score == 0)
    }
}
```

- [ ] Run test (expect failure — HealthKitManager not yet written):
```bash
xcodebuild test -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:LumvraTests/ScoreAlgorithmTests 2>&1 | tail -20
```

- [ ] Write `Lumvra/Managers/HealthKitManager.swift`:
```swift
import HealthKit
import Foundation

@MainActor
class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    @Published var lastNight: SleepData = .empty(date: Date())
    @Published var history: [SleepData] = []
    @Published var authorizationDenied = false

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationDenied = true
            return
        }
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        do {
            try await store.requestAuthorization(toShare: [], read: [sleepType])
        } catch {
            authorizationDenied = true
        }
    }

    func fetchLastNightSleep() async {
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        let start = cal.date(byAdding: .day, value: -1, to: cal.date(from: components) ?? Date()) ?? Date()
        let end: Date = {
            var c = cal.dateComponents([.year, .month, .day], from: Date())
            c.hour = 12
            return cal.date(from: c) ?? Date()
        }()
        lastNight = await fetchSleep(from: start, to: end)
    }

    func fetchSleepHistory(days: Int = 30) async {
        var results: [SleepData] = []
        let cal = Calendar.current
        for i in 1...days {
            guard let date = cal.date(byAdding: .day, value: -i, to: Date()) else { continue }
            var startComps = cal.dateComponents([.year, .month, .day], from: date)
            startComps.hour = 18
            let start = cal.date(byAdding: .day, value: -1, to: cal.date(from: startComps) ?? date) ?? date
            var endComps = cal.dateComponents([.year, .month, .day], from: date)
            endComps.hour = 12
            let end = cal.date(from: endComps) ?? date
            let data = await fetchSleep(from: start, to: end)
            if data.quality.hasAnyData { results.append(data) }
        }
        history = results
    }

    private func fetchSleep(from start: Date, to end: Date) async -> SleepData {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                let categorySamples = samples as? [HKCategorySample] ?? []
                if categorySamples.isEmpty {
                    continuation.resume(returning: .empty(date: start))
                    return
                }
                continuation.resume(returning: self.process(categorySamples, date: start))
            }
            store.execute(query)
        }
    }

    private func process(_ samples: [HKCategorySample], date: Date) -> SleepData {
        var deep = 0, core = 0, rem = 0, awake = 0, inBed = 0

        let hasStageData = samples.contains {
            guard let v = HKCategoryValueSleepAnalysis(rawValue: $0.value) else { return false }
            return v == .asleepDeep || v == .asleepCore || v == .asleepREM
        }

        let primary: [HKCategorySample]
        if hasStageData {
            primary = samples.filter {
                guard let v = HKCategoryValueSleepAnalysis(rawValue: $0.value) else { return false }
                return v == .asleepDeep || v == .asleepCore || v == .asleepREM || v == .awake
            }
        } else {
            primary = samples
        }

        for s in primary {
            guard let v = HKCategoryValueSleepAnalysis(rawValue: s.value) else { continue }
            let mins = Int(s.endDate.timeIntervalSince(s.startDate) / 60)
            switch v {
            case .asleepDeep: deep += mins
            case .asleepCore: core += mins
            case .asleepREM:  rem += mins
            case .awake:      awake += 1
            case .inBed:      inBed += mins
            default: break
            }
        }

        let total = deep + core + rem
        if inBed == 0 { inBed = total > 0 ? total : Int((samples.last?.endDate.timeIntervalSince(samples.first?.startDate ?? date) ?? 0) / 60) }

        let quality = detectQuality(samples: samples, hasStages: total > 0, hasAwake: awake > 0)
        let score = HealthKitManager.calculateScore(deep: deep, core: core, rem: rem,
                                                    total: total, inBed: inBed,
                                                    awakeCount: awake, quality: quality)

        return SleepData(
            date: date, quality: quality, inBedMinutes: inBed, totalSleepMinutes: total,
            bedtime: samples.first?.startDate ?? date,
            wakeTime: samples.last?.endDate ?? date,
            score: score, deepMinutes: deep, coreMinutes: core,
            remMinutes: rem, awakeCount: awake
        )
    }

    private func detectQuality(samples: [HKCategorySample], hasStages: Bool, hasAwake: Bool) -> DataQuality {
        if hasStages { return .full }
        // .partial = awake samples from an Apple Watch source (bundle + device model check)
        let hasWatchAwake = hasAwake && samples.contains {
            guard HKCategoryValueSleepAnalysis(rawValue: $0.value) == .awake else { return false }
            let bundleOK = $0.sourceRevision.source.bundleIdentifier.hasPrefix("com.apple.health")
            let deviceOK = $0.device?.model?.lowercased().contains("watch") ?? false
            return bundleOK && deviceOK
        }
        if hasWatchAwake { return .partial }
        let hasInBed = samples.contains {
            HKCategoryValueSleepAnalysis(rawValue: $0.value) == .inBed
        }
        return hasInBed ? .basic : .noData
    }

    // Static for testability
    static func calculateScore(deep: Int, core: Int, rem: Int,
                                total: Int, inBed: Int,
                                awakeCount: Int, quality: DataQuality) -> Int {
        switch quality {
        case .noData:
            return 0
        case .basic:
            return min(75, Int(Double(inBed) / 60.0 / 8.0 * 75))
        case .partial:
            var score = 0
            score += min(40, Int(Double(inBed) / 60.0 / 8.0 * 40))
            score += max(0, 10 - awakeCount * 2)
            return min(100, score)
        case .full:
            guard total > 0 else { return 0 }
            var score = 0
            score += min(40, Int(Double(total) / 60.0 / 8.0 * 40))
            score += min(30, Int(Double(deep) / Double(total) / 0.20 * 30))
            score += min(20, Int(Double(rem) / Double(total) / 0.25 * 20))
            score += max(0, 10 - awakeCount * 2)
            return min(100, score)
        }
    }
}
```

- [ ] Run tests:
```bash
xcodebuild test -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:LumvraTests/ScoreAlgorithmTests 2>&1 | tail -20
```
Expected: `** TEST SUCCEEDED **`

- [ ] Commit:
```bash
git add Lumvra/Managers/HealthKitManager.swift LumvraTests/ScoreAlgorithmTests.swift
git commit -m "feat: add HealthKitManager with score algorithm (TDD)"
```

---

### Task 11: NotificationManager

**Files:**
- Create: `Lumvra/Managers/NotificationManager.swift`

- [ ] Write `Lumvra/Managers/NotificationManager.swift`:
```swift
import UserNotifications
import Foundation

@MainActor
class NotificationManager: ObservableObject {
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func reschedule(profile: UserProfile, language: String) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let isSv = language == "Swedish"

        if profile.morningNotificationsEnabled {
            let wakeComponents = Calendar.current.dateComponents([.hour, .minute], from: profile.targetWakeTime)
            var hour = (wakeComponents.hour ?? 7)
            var minute = (wakeComponents.minute ?? 0) + 15
            if minute >= 60 { minute -= 60; hour = (hour + 1) % 24 }
            schedule(
                id: "lumvra.morning",
                title: isSv ? "God morgon 🌙" : "Good morning 🌙",
                body: isSv ? "Din sömninsikt för igår natt är redo." : "Your sleep insight from last night is ready.",
                hour: hour, minute: minute
            )
        }

        if profile.eveningNotificationsEnabled {
            let bedComponents = Calendar.current.dateComponents([.hour, .minute], from: profile.targetBedtime)
            var hour = (bedComponents.hour ?? 22)
            var minute = (bedComponents.minute ?? 30) - 60
            if minute < 0 { minute += 60; hour = (hour - 1 + 24) % 24 }
            schedule(
                id: "lumvra.evening",
                title: isSv ? "Kvällskoll 🌙" : "Evening check-in 🌙",
                body: isSv ? "Logga din dag för bättre sömninsikter." : "Log your day for better sleep insights.",
                hour: hour, minute: minute
            )
        }
    }

    private func schedule(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Managers/NotificationManager.swift
git commit -m "feat: add NotificationManager for local morning/evening notifications"
```

---

### Task 12: AIManager

**Files:**
- Create: `Lumvra/Managers/AIManager.swift`

- [ ] Write `Lumvra/Managers/AIManager.swift`:
```swift
import Foundation

enum AIError: Error {
    case invalidResponse
    case emptyContent
}

// final + Sendable: all stored properties are let (value types or Sendable) — safe for cross-actor capture
final class AIManager: Sendable {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5-20251001"

    init() {
        self.apiKey = ConfigManager.value(for: "ANTHROPIC_API_KEY")
    }

    func generateMorningInsight(sleepData: SleepData,
                                 history: [SleepData],
                                 checkin: EveningCheckin?,
                                 language: String) async -> String {
        guard sleepData.quality.hasAnyData else {
            return language == "Swedish"
                ? "Ingen sömndata hittades. Bär din Apple Watch för att få personliga insikter."
                : "No sleep data found. Wear your Apple Watch to get personal insights."
        }

        let avg7 = Array(history.prefix(7))
        let systemPrompt: String
        var inputDict: [String: Any] = [
            "score": sleepData.score,
            "inBed": sleepData.inBedMinutes
        ]

        if sleepData.quality == .full {
            let avgDeep = avg7.map(\.deepMinutes).reduce(0,+) / max(1, avg7.count)
            let avgTotal = avg7.map(\.totalSleepMinutes).reduce(0,+) / max(1, avg7.count)
            inputDict["deep"] = sleepData.deepMinutes
            inputDict["core"] = sleepData.coreMinutes
            inputDict["rem"] = sleepData.remMinutes
            inputDict["wake"] = sleepData.awakeCount
            inputDict["avg7deep"] = avgDeep
            inputDict["avg7total"] = avgTotal
            systemPrompt = """
            You are a concise sleep coach. Respond ONLY in \(language).
            Full sleep stage data available (deep, core, REM, awakenings).
            Generate ONE specific, personalised insight about last night's sleep. Max 28 words.
            Be specific — use the exact numbers. Never say "it seems" or "it appears". Be direct.
            No markdown, no lists, plain sentence only.
            """
        } else {
            let avgInBed = avg7.map(\.inBedMinutes).reduce(0,+) / max(1, avg7.count)
            inputDict["avg7inBed"] = avgInBed
            systemPrompt = """
            You are a concise sleep coach. Respond ONLY in \(language).
            Only time-in-bed data available — no sleep stages. Mention this limitation naturally.
            Generate ONE personalised insight about last night's sleep. Max 28 words.
            No markdown, no lists, plain sentence only.
            """
        }

        if let c = checkin {
            if c.hadAlcohol { inputDict["alcohol"] = true }
            if c.hadCoffeeAfter2pm { inputDict["lateCoffee"] = true }
            if c.exercised { inputDict["exercised"] = true }
        }

        let userMessage = (try? String(data: JSONSerialization.data(withJSONObject: inputDict), encoding: .utf8)) ?? "{}"

        return await callHaiku(system: systemPrompt, user: userMessage, maxTokens: 80)
            ?? (language == "Swedish" ? "Öppna appen imorgon bitti för din sömninsikt." : "Open the app tomorrow morning for your sleep insight.")
    }

    func generateBedtimeRecommendation(history: [SleepData],
                                        targetWakeTime: Date,
                                        language: String) async -> String {
        let recent = Array(history.prefix(7))
        let avgBedHour = recent.compactMap { d -> Double? in
            let c = Calendar.current.dateComponents([.hour, .minute], from: d.bedtime)
            return Double(c.hour ?? 22) + Double(c.minute ?? 0) / 60.0
        }.reduce(0,+) / Double(max(1, recent.count))

        let avgScore = recent.map(\.score).reduce(0,+) / max(1, recent.count)
        let wakeHour = Calendar.current.component(.hour, from: targetWakeTime)

        let systemPrompt = """
        You are a sleep coach. Respond ONLY in \(language).
        Give ONE bedtime recommendation for tonight: state the time in HH:MM format followed by one short reason.
        Max 20 words total. No markdown, plain text only.
        """
        let userMessage = "{\"wake_at\":\(wakeHour),\"avg_bedtime\":\(String(format: "%.1f", avgBedHour)),\"avg_score\":\(avgScore),\"target_hours\":8}"

        return await callHaiku(system: systemPrompt, user: userMessage, maxTokens: 60)
            ?? formatTime(targetWakeTime)
    }

    func parseBedtime(from text: String, today: Date = Date()) -> Date {
        let pattern = #"\b(\d{2}):(\d{2})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let hourRange = Range(match.range(at: 1), in: text),
              let minRange = Range(match.range(at: 2), in: text),
              let hour = Int(text[hourRange]),
              let minute = Int(text[minRange]) else {
            return Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? today
        }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: today)
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? today
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func callHaiku(system: String, user: String, maxTokens: Int) async -> String? {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [["role": "user", "content": user]]
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = bodyData

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first,
              let text = content["text"] as? String, !text.isEmpty else { return nil }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Managers/AIManager.swift
git commit -m "feat: add AIManager with Claude Haiku integration"
```

---

## Phase 4 — App Entry Point

### Task 13: LumvraApp.swift + ContentView.swift

**Files:**
- Create: `Lumvra/LumvraApp.swift`
- Create: `Lumvra/ContentView.swift`

- [ ] Write `Lumvra/LumvraApp.swift`:
```swift
import SwiftUI
import RevenueCat

@main
struct LumvraApp: App {
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var storage: LocalStorageManager
    @StateObject private var userState: UserState
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var notificationManager = NotificationManager()

    init() {
        // Share a single LocalStorageManager between storage env object and UserState
        let s = LocalStorageManager()
        _storage = StateObject(wrappedValue: s)
        _userState = StateObject(wrappedValue: UserState(storage: s))
        Purchases.configure(withAPIKey: ConfigManager.value(for: "REVENUECAT_API_KEY"))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .environmentObject(storage)
                .environmentObject(healthKitManager)
                .environmentObject(notificationManager)
                .environmentObject(userState)
                .preferredColorScheme(.dark)
                .task { await userState.refreshPremiumStatus() }
        }
    }
}
```

- [ ] Write `Lumvra/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/LumvraApp.swift Lumvra/ContentView.swift
git commit -m "feat: add app entry point with environment injection"
```

---

## Phase 5 — Onboarding

### Task 14: WelcomeView

**Files:**
- Create: `Lumvra/Views/Onboarding/WelcomeView.swift`

- [ ] Write `Lumvra/Views/Onboarding/WelcomeView.swift`:
```swift
import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var lm: LanguageManager
    var onNext: () -> Void

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                // App icon + name
                VStack(spacing: 16) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.lvPurple)
                    Text("Lumvra")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.lvTextPri)
                    Text(lm.t(en: "Your AI sleep coach", sv: "Din AI-sömncoach"))
                        .font(.title3)
                        .foregroundColor(.lvTextSec)
                }

                // Feature rows
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "applewatch", en: "Reads Apple Watch sleep data", sv: "Läser Apple Watch sömndata")
                    FeatureRow(icon: "sparkles", en: "AI insight every morning", sv: "AI-insikt varje morgon")
                    FeatureRow(icon: "moon.zzz", en: "Bedtime recommendation every evening", sv: "Rekommendation varje kväll")
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: onNext) {
                    Text(lm.t(en: "Get started", sv: "Kom igång"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lvPurple)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

private struct FeatureRow: View {
    @EnvironmentObject var lm: LanguageManager
    let icon: String
    let en: String
    let sv: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.lvPurple)
                .frame(width: 32)
            Text(lm.t(en: en, sv: sv))
                .foregroundColor(.lvTextPri)
        }
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Views/Onboarding/WelcomeView.swift
git commit -m "feat: add WelcomeView onboarding step"
```

---

### Task 15: HealthKitPermissionView + NotificationPermissionView

**Files:**
- Create: `Lumvra/Views/Onboarding/HealthKitPermissionView.swift`
- Create: `Lumvra/Views/Onboarding/NotificationPermissionView.swift`

- [ ] Write `Lumvra/Views/Onboarding/HealthKitPermissionView.swift`:
```swift
import SwiftUI

struct HealthKitPermissionView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager
    var onNext: () -> Void

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.lvTeal)
                VStack(spacing: 12) {
                    Text(lm.t(en: "Sleep data access", sv: "Tillgång till sömndata"))
                        .font(.title2.bold())
                        .foregroundColor(.lvTextPri)
                    Text(lm.t(
                        en: "Lumvra reads your sleep data from Apple Health. Your data never leaves your device.",
                        sv: "Lumvra läser din sömndata från Apple Health. Din data lämnar aldrig din telefon."
                    ))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.lvTextSec)
                    .padding(.horizontal)
                }
                Spacer()
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await hkManager.requestAuthorization()
                            onNext()
                        }
                    } label: {
                        Text(lm.t(en: "Allow Health access", sv: "Tillåt hälsotillgång"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lvPurple)
                            .cornerRadius(16)
                    }
                    Button(action: onNext) {
                        Text(lm.t(en: "Continue without access", sv: "Fortsätt utan tillgång"))
                            .foregroundColor(.lvTextSec)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
```

- [ ] Write `Lumvra/Views/Onboarding/NotificationPermissionView.swift`:
```swift
import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var notificationManager: NotificationManager
    var onNext: () -> Void

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.lvAmber)
                VStack(spacing: 12) {
                    Text(lm.t(en: "Morning insights", sv: "Morgoninsikter"))
                        .font(.title2.bold())
                        .foregroundColor(.lvTextPri)
                    Text(lm.t(
                        en: "We'll remind you every morning when your sleep insight is ready.",
                        sv: "Vi påminner dig varje morgon när din sömninsikt är klar."
                    ))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.lvTextSec)
                    .padding(.horizontal)
                }
                Spacer()
                VStack(spacing: 12) {
                    Button {
                        Task {
                            _ = await notificationManager.requestPermission()
                            onNext()
                        }
                    } label: {
                        Text(lm.t(en: "Allow notifications", sv: "Tillåt notiser"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lvPurple)
                            .cornerRadius(16)
                    }
                    Button(action: onNext) {
                        Text(lm.t(en: "Skip", sv: "Hoppa över"))
                            .foregroundColor(.lvTextSec)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Views/Onboarding/HealthKitPermissionView.swift Lumvra/Views/Onboarding/NotificationPermissionView.swift
git commit -m "feat: add HealthKit and notification permission onboarding screens"
```

---

### Task 16: LoadingDataView + OnboardingContainerView

**Files:**
- Create: `Lumvra/Views/Onboarding/LoadingDataView.swift`
- Create: `Lumvra/Views/Onboarding/OnboardingContainerView.swift`

- [ ] Write `Lumvra/Views/Onboarding/LoadingDataView.swift`:
```swift
import SwiftUI

struct LoadingDataView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var userState: UserState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                ProgressView()
                    .tint(.lvPurple)
                    .scaleEffect(1.5)
                Text(lm.t(en: "Reading your sleep patterns...", sv: "Läser dina sömnmönster..."))
                    .foregroundColor(.lvTextPri)
                    .font(.headline)
                Text(lm.t(en: "Analysing 30 nights", sv: "Analyserar 30 nätter"))
                    .foregroundColor(.lvTextSec)
            }
        }
        .task {
            await hkManager.fetchLastNightSleep()
            await hkManager.fetchSleepHistory(days: 30)
            notificationManager.reschedule(profile: userState.profile, language: lm.resolvedLanguage)
            hasCompletedOnboarding = true
        }
    }
}
```

- [ ] Write `Lumvra/Views/Onboarding/OnboardingContainerView.swift`:
```swift
import SwiftUI

enum OnboardingStep {
    case welcome, healthKit, notifications, loading
}

struct OnboardingContainerView: View {
    @State private var step: OnboardingStep = .welcome

    var body: some View {
        switch step {
        case .welcome:
            WelcomeView { step = .healthKit }
        case .healthKit:
            HealthKitPermissionView { step = .notifications }
        case .notifications:
            NotificationPermissionView { step = .loading }
        case .loading:
            LoadingDataView()
        }
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Views/Onboarding/LoadingDataView.swift Lumvra/Views/Onboarding/OnboardingContainerView.swift
git commit -m "feat: complete onboarding flow with data loading"
```

---

## Phase 6 — Components

### Task 17: SleepScoreRing + StageBar

**Files:**
- Create: `Lumvra/Components/SleepScoreRing.swift`
- Create: `Lumvra/Components/StageBar.swift`

- [ ] Write `Lumvra/Components/SleepScoreRing.swift`:
```swift
import SwiftUI

struct SleepScoreRing: View {
    let score: Int
    let size: CGFloat

    private var color: Color { Color.forScore(score) }
    private var progress: Double { Double(score) / 100.0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.lvSurface2, lineWidth: size * 0.08)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundColor(.lvTextPri)
                Text("Sleep Score")
                    .font(.system(size: size * 0.09))
                    .foregroundColor(.lvTextSec)
            }
        }
        .frame(width: size, height: size)
    }
}
```

- [ ] Write `Lumvra/Components/StageBar.swift`:
```swift
import SwiftUI

struct StageBar: View {
    @EnvironmentObject var lm: LanguageManager
    let data: SleepData

    var body: some View {
        VStack(spacing: 12) {
            // Stage pills
            HStack(spacing: 8) {
                StagePill(label: lm.t(en: "Deep", sv: "Djup"), minutes: data.deepMinutes, color: .lvPurple)
                StagePill(label: lm.t(en: "Core", sv: "Kärn"), minutes: data.coreMinutes, color: .lvTeal)
                StagePill(label: "REM", minutes: data.remMinutes, color: .lvAmber)
            }
            // Bar
            GeometryReader { geo in
                let total = max(1, data.deepMinutes + data.coreMinutes + data.remMinutes)
                HStack(spacing: 2) {
                    Rectangle().fill(Color.lvPurple)
                        .frame(width: geo.size.width * CGFloat(data.deepMinutes) / CGFloat(total))
                    Rectangle().fill(Color.lvTeal)
                        .frame(width: geo.size.width * CGFloat(data.coreMinutes) / CGFloat(total))
                    Rectangle().fill(Color.lvAmber)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }
}

private struct StagePill: View {
    let label: String
    let minutes: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
            Text(formatMinutes(minutes))
                .font(.caption.bold())
                .foregroundColor(.lvTextPri)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.lvSurface2)
        .cornerRadius(8)
    }

    private func formatMinutes(_ m: Int) -> String {
        m >= 60 ? "\(m/60)h \(m%60)m" : "\(m)m"
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Components/SleepScoreRing.swift Lumvra/Components/StageBar.swift
git commit -m "feat: add SleepScoreRing and StageBar components"
```

---

### Task 18: InsightCard + WatchUpgradePrompt + DataQualityBadge + CheckInButton

**Files:**
- Create: `Lumvra/Components/InsightCard.swift`
- Create: `Lumvra/Components/WatchUpgradePrompt.swift`
- Create: `Lumvra/Components/DataQualityBadge.swift`
- Create: `Lumvra/Components/CheckInButton.swift`

- [ ] Write `Lumvra/Components/InsightCard.swift`:
```swift
import SwiftUI

struct InsightCard: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    let insight: String?
    var onUpgrade: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.lvPurple)
                Text(lm.t(en: "Your sleep insight", sv: "Din sömninsikt"))
                    .font(.subheadline.bold())
                    .foregroundColor(.lvTextPri)
                Spacer()
                if !userState.isPremium {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.lvTextTert)
                }
            }
            if userState.isPremium {
                if let insight {
                    Text(insight)
                        .font(.body)
                        .foregroundColor(.lvTextPri)
                } else {
                    ProgressView().tint(.lvPurple)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(lm.t(en: "Your deep sleep increased 40% vs your weekly average...", sv: "Din djupsömn ökade 40% jämfört med veckosnittet..."))
                        .font(.body)
                        .foregroundColor(.lvTextPri)
                        .blur(radius: 4)
                    Button(action: onUpgrade) {
                        Text(lm.t(en: "Upgrade to see your insight", sv: "Uppgradera för att se din insikt"))
                            .font(.caption.bold())
                            .foregroundColor(.lvPurple)
                    }
                }
            }
        }
        .padding()
        .background(Color.lvSurface)
        .cornerRadius(16)
    }
}
```

- [ ] Write `Lumvra/Components/WatchUpgradePrompt.swift`:
```swift
import SwiftUI

struct WatchUpgradePrompt: View {
    @EnvironmentObject var lm: LanguageManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.title2)
                .foregroundColor(.lvPurple)
            VStack(alignment: .leading, spacing: 2) {
                Text(lm.t(en: "Get deeper insights", sv: "Få djupare insikter"))
                    .font(.subheadline.bold())
                    .foregroundColor(.lvTextPri)
                Text(lm.t(en: "Wear Apple Watch while sleeping for sleep stages",
                           sv: "Bär Apple Watch när du sover för sömnsteg"))
                    .font(.caption)
                    .foregroundColor(.lvTextSec)
            }
        }
        .padding()
        .background(Color.lvSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lvPurple.opacity(0.3), lineWidth: 1))
    }
}
```

- [ ] Write `Lumvra/Components/DataQualityBadge.swift`:
```swift
import SwiftUI

struct DataQualityBadge: View {
    @EnvironmentObject var lm: LanguageManager
    let quality: DataQuality

    var body: some View {
        Text(quality.label(isSv: lm.isSv))
            .font(.caption2.bold())
            .foregroundColor(.lvTextSec)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.lvSurface2)
            .cornerRadius(6)
    }
}
```

- [ ] Write `Lumvra/Components/CheckInButton.swift`:
```swift
import SwiftUI

struct CheckInButton: View {
    @EnvironmentObject var lm: LanguageManager
    let icon: String
    let en: String
    let sv: String
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack {
                Text(icon)
                Text(lm.t(en: en, sv: sv))
                    .foregroundColor(.lvTextPri)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? .lvTeal : .lvTextTert)
            }
            .padding()
            .background(Color.lvSurface)
            .cornerRadius(12)
        }
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Components/InsightCard.swift Lumvra/Components/WatchUpgradePrompt.swift Lumvra/Components/DataQualityBadge.swift Lumvra/Components/CheckInButton.swift
git commit -m "feat: add InsightCard, WatchUpgradePrompt, DataQualityBadge, CheckInButton components"
```

---

## Phase 7 — Main Views

### Task 19: PaywallView

**Files:**
- Create: `Lumvra/Views/Paywall/PaywallView.swift`

- [ ] Write `Lumvra/Views/Paywall/PaywallView.swift`:
```swift
import SwiftUI
import RevenueCat

struct PaywallView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    @Environment(\.dismiss) private var dismiss
    @State private var offerings: Offerings?
    @State private var isLoading = false

    let features: [(String, String, String)] = [
        ("sparkles", "Personalised AI morning insight based on your data", "Personlig AI-insikt varje morgon baserad på din data"),
        ("moon.zzz", "Evening coaching & check-in", "Kvällscoaching och check-in"),
        ("chart.line.uptrend.xyaxis", "90 days of history + trends", "90 dagars historik och trender"),
        ("arrow.triangle.2.circlepath", "Correlation analysis", "Korrelationsanalys"),
        ("minus.circle", "Sleep debt tracker", "Sömnunderskott-tracker"),
        ("text.badge.checkmark", "Weekly summary", "Veckosammanfattning"),
    ]

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("✨")
                            .font(.system(size: 48))
                        Text(lm.t(en: "Lumvra Premium", sv: "Lumvra Premium"))
                            .font(.title.bold())
                            .foregroundColor(.lvTextPri)
                        Text(lm.t(en: "Your personal AI sleep coach", sv: "Din personliga AI-sömncoach"))
                            .foregroundColor(.lvTextSec)
                    }
                    .padding(.top, 32)

                    // Features
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features, id: \.0) { icon, en, sv in
                            HStack(spacing: 12) {
                                Image(systemName: icon)
                                    .foregroundColor(.lvPurple)
                                    .frame(width: 24)
                                Text(lm.t(en: en, sv: sv))
                                    .foregroundColor(.lvTextPri)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // CTAs
                    VStack(spacing: 12) {
                        // Yearly (primary)
                        Button { purchase(.yearly) } label: {
                            VStack(spacing: 4) {
                                Text(lm.t(en: "Try free for 7 days", sv: "Prova gratis i 7 dagar"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(lm.t(en: "then 499 kr / year", sv: "sedan 499 kr/år"))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lvPurple)
                            .cornerRadius(16)
                        }

                        // Monthly (secondary)
                        Button { purchase(.monthly) } label: {
                            Text(lm.t(en: "79 kr / month", sv: "79 kr / månad"))
                                .foregroundColor(.lvTextSec)
                        }

                        // Lifetime (tertiary)
                        Button { purchase(.lifetime) } label: {
                            Text(lm.t(en: "Lifetime: 399 kr (without AI) →", sv: "Livstid: 399 kr (utan AI) →"))
                                .font(.caption)
                                .foregroundColor(.lvTextTert)
                        }
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 16) {
                        Button {
                            Task {
                                _ = try? await Purchases.shared.restorePurchases()
                                await userState.refreshPremiumStatus()
                                if userState.isPremium { dismiss() }
                            }
                        } label: {
                            Text(lm.t(en: "Restore purchases", sv: "Återställ köp"))
                                .font(.caption)
                                .foregroundColor(.lvTextSec)
                        }

                        Button { dismiss() } label: {
                            Text(lm.t(en: "Close", sv: "Stäng"))
                                .font(.caption)
                                .foregroundColor(.lvTextSec)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            if isLoading { ProgressView().tint(.lvPurple) }
        }
    }

    private func purchase(_ type: ProductType) {
        Task {
            isLoading = true
            defer { isLoading = false }
            guard let offering = try? await Purchases.shared.offerings().current,
                  let package = offering.package(identifier: type.packageId) else { return }
            if let result = try? await Purchases.shared.purchase(package: package) {
                if result.customerInfo.entitlements[type.entitlement]?.isActive == true {
                    await userState.refreshPremiumStatus()
                    dismiss()
                }
            }
        }
    }
}

private enum ProductType {
    case monthly, yearly, lifetime
    var packageId: String {
        switch self {
        case .monthly:  return "com.terrorbyte90.lumvra.premium.monthly"
        case .yearly:   return "com.terrorbyte90.lumvra.premium.yearly"
        case .lifetime: return "com.terrorbyte90.lumvra.lifetime"
        }
    }
    var entitlement: String {
        self == .lifetime ? "lifetime" : "premium"
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Views/Paywall/PaywallView.swift
git commit -m "feat: add PaywallView with RevenueCat purchase flow"
```

---

### Task 20: MorningView

**Files:**
- Create: `Lumvra/Views/Main/MorningView.swift`

- [ ] Write `Lumvra/Views/Main/MorningView.swift`:
```swift
import SwiftUI

struct MorningView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var storage: LocalStorageManager
    @State private var insight: String?
    @State private var bedtimeRec: String?
    @State private var showPaywall = false
    private let ai = AIManager()

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text(dateHeader)
                            .font(.headline)
                            .foregroundColor(.lvTextSec)
                        Spacer()
                        DataQualityBadge(quality: hkManager.lastNight.quality)
                    }
                    .padding(.horizontal)

                    let data = hkManager.lastNight

                    if data.quality == .noData {
                        noDataView
                    } else {
                        // Score ring
                        SleepScoreRing(score: data.score, size: 180)
                            .padding(.top, 8)

                        // Insight card
                        InsightCard(insight: insight) { showPaywall = true }
                            .padding(.horizontal)

                        // Stage bar (hidden for basic/noData)
                        if data.quality == .full {
                            StageBar(data: data)
                                .padding(.horizontal)
                        }

                        // Watch prompt (shown once, basic only)
                        if data.quality == .basic && !userState.profile.hasSeenWatchPrompt {
                            WatchUpgradePrompt()
                                .padding(.horizontal)
                                .onAppear {
                                    userState.profile.hasSeenWatchPrompt = true
                                    userState.saveProfile()
                                }
                        }

                        // Metadata row
                        HStack(spacing: 16) {
                            Label(formatHours(data.hoursSlept), systemImage: "bed.double")
                            if data.quality == .full {
                                Label("\(data.awakeCount) \(lm.t(en: "awakenings", sv: "uppvaknanden"))", systemImage: "arrow.up.arrow.down")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.lvTextSec)

                        // Bedtime pill
                        if let rec = bedtimeRec {
                            HStack {
                                Image(systemName: "moon.zzz")
                                    .foregroundColor(.lvPurple)
                                Text(lm.t(en: "Tonight: ", sv: "Ikväll: ") + rec)
                                    .foregroundColor(.lvTextPri)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding()
                            .background(Color.lvSurface)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .task { await loadInsights() }
    }

    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 64))
                .foregroundColor(.lvTextTert)
            Text(lm.t(en: "No sleep data for last night", sv: "Ingen sömndata för igår natt"))
                .font(.headline)
                .foregroundColor(.lvTextPri)
            Text(lm.t(en: "Wear Apple Watch while sleeping and open the app tomorrow.",
                       sv: "Bär Apple Watch när du sover och öppna appen imorgon."))
                .multilineTextAlignment(.center)
                .foregroundColor(.lvTextSec)
                .padding(.horizontal)
        }
        .padding(.top, 60)
    }

    private var dateHeader: String {
        let f = DateFormatter()
        f.dateFormat = lm.isSv ? "EEEE d MMMM" : "EEEE, MMMM d"
        f.locale = Locale(identifier: lm.isSv ? "sv_SE" : "en_US")
        return f.string(from: Date()).capitalized
    }

    private func formatHours(_ h: Double) -> String {
        let hrs = Int(h)
        let mins = Int((h - Double(hrs)) * 60)
        return "\(hrs)h \(mins)m"
    }

    private func loadInsights() async {
        // Check cache
        if let cached = storage.loadCachedInsight(for: Date()) {
            insight = cached.morningInsight
            bedtimeRec = cached.bedtimeRecommendation
            return
        }
        // Generate if premium
        if userState.isPremium {
            let checkin = storage.loadCheckin(for: Calendar.current.startOfDay(for: Date()))
            async let morningTask = ai.generateMorningInsight(
                sleepData: hkManager.lastNight,
                history: hkManager.history,
                checkin: checkin,
                language: lm.resolvedLanguage
            )
            async let bedtimeTask = ai.generateBedtimeRecommendation(
                history: hkManager.history,
                targetWakeTime: userState.profile.targetWakeTime,
                language: lm.resolvedLanguage
            )
            let (m, b) = await (morningTask, bedtimeTask)
            insight = m
            bedtimeRec = b

            // Cache
            let si = SleepInsight(
                id: UUID(),
                date: Calendar.current.startOfDay(for: Date()),
                morningInsight: m,
                bedtimeRecommendation: b,
                recommendedBedtime: ai.parseBedtime(from: b),
                sleepScore: hkManager.lastNight.score,
                language: lm.resolvedLanguage,
                dataQuality: hkManager.lastNight.quality,
                generatedAt: Date()
            )
            storage.cacheInsight(si)
        } else {
            // Free: show formatted bedtime target
            let f = DateFormatter(); f.dateFormat = "HH:mm"
            bedtimeRec = f.string(from: userState.profile.targetBedtime)
        }
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Views/Main/MorningView.swift
git commit -m "feat: add MorningView with AI insight loading and score display"
```

---

### Task 21: EveningView

**Files:**
- Create: `Lumvra/Views/Main/EveningView.swift`

- [ ] Write `Lumvra/Views/Main/EveningView.swift`:
```swift
import SwiftUI

struct EveningView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var storage: LocalStorageManager
    @State private var hadAlcohol = false
    @State private var hadCoffee = false
    @State private var exercised = false
    @State private var saved = false
    @State private var showPaywall = false
    private let ai = AIManager()

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text(lm.t(en: "Evening check-in", sv: "Kvällskoll"))
                        .font(.title2.bold())
                        .foregroundColor(.lvTextPri)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Bedtime recommendation
                    VStack(spacing: 4) {
                        Text(lm.t(en: "Tonight's bedtime", sv: "Läggdags ikväll"))
                            .font(.subheadline)
                            .foregroundColor(.lvTextSec)
                        Text(formattedBedtime)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.lvTextPri)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.lvSurface)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    if userState.isPremium {
                        // Check-in section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lm.t(en: "Log your day (optional)", sv: "Logga din dag (valfritt)"))
                                .font(.subheadline.bold())
                                .foregroundColor(.lvTextSec)
                                .padding(.horizontal)

                            CheckInButton(icon: "🍷", en: "Had alcohol today?", sv: "Drack alkohol idag?", isOn: $hadAlcohol)
                                .padding(.horizontal)
                            CheckInButton(icon: "☕", en: "Coffee after 2 PM?", sv: "Kaffe efter 14:00?", isOn: $hadCoffee)
                                .padding(.horizontal)
                            CheckInButton(icon: "🏃", en: "Exercised today?", sv: "Tränade idag?", isOn: $exercised)
                                .padding(.horizontal)
                        }

                        Button {
                            let checkin = EveningCheckin(
                                date: Calendar.current.startOfDay(for: Date()),
                                hadAlcohol: hadAlcohol,
                                hadCoffeeAfter2pm: hadCoffee,
                                exercised: exercised
                            )
                            storage.saveCheckin(checkin)
                            withAnimation { saved = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                        } label: {
                            Text(saved
                                 ? lm.t(en: "Saved ✓", sv: "Sparat ✓")
                                 : lm.t(en: "Save", sv: "Spara"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(saved ? Color.lvTeal : Color.lvPurple)
                                .cornerRadius(16)
                                .animation(.easeInOut, value: saved)
                        }
                        .padding(.horizontal)
                    } else {
                        // Upsell
                        Button { showPaywall = true } label: {
                            HStack {
                                Image(systemName: "lock.fill")
                                Text(lm.t(en: "Unlock evening coaching", sv: "Lås upp kvällscoaching"))
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.lvPurple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lvSurface)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { loadCheckin() }
    }

    private var formattedBedtime: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: userState.profile.targetBedtime)
    }

    private func loadCheckin() {
        guard let c = storage.loadCheckin(for: Date()) else { return }
        hadAlcohol = c.hadAlcohol
        hadCoffee = c.hadCoffeeAfter2pm
        exercised = c.exercised
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Views/Main/EveningView.swift
git commit -m "feat: add EveningView with check-in and premium gating"
```

---

### Task 22: TrendsView

**Files:**
- Create: `Lumvra/Views/Main/TrendsView.swift`

- [ ] Write `Lumvra/Views/Main/TrendsView.swift`:
```swift
import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var hkManager: HealthKitManager

    var body: some View {
        if userState.isPremium {
            TrendsContentView()
        } else {
            PaywallView()
        }
    }
}

private struct TrendsContentView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager

    private var last7: [SleepData] { Array(hkManager.history.prefix(7)) }
    private var avgScore: Int { last7.map(\.score).reduce(0,+) / max(1, last7.count) }
    private var avgDeep: Int { last7.map(\.deepMinutes).reduce(0,+) / max(1, last7.count) }
    private var avgCore: Int { last7.map(\.coreMinutes).reduce(0,+) / max(1, last7.count) }
    private var avgREM: Int { last7.map(\.remMinutes).reduce(0,+) / max(1, last7.count) }

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(lm.t(en: "Trends", sv: "Trender"))
                        .font(.title2.bold())
                        .foregroundColor(.lvTextPri)
                        .padding(.horizontal)

                    // 7-night score chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lm.t(en: "Last 7 nights", sv: "Senaste 7 nätterna"))
                            .font(.subheadline.bold())
                            .foregroundColor(.lvTextSec)
                            .padding(.horizontal)

                        if #available(iOS 17.0, *) {
                            Chart(last7.reversed(), id: \.date) { data in
                                BarMark(
                                    x: .value("Date", data.date, unit: .day),
                                    y: .value("Score", data.score)
                                )
                                .foregroundStyle(Color.forScore(data.score))
                            }
                            .frame(height: 120)
                            .padding(.horizontal)
                        }

                        Text(lm.t(en: "Average: \(avgScore)", sv: "Snitt: \(avgScore)"))
                            .font(.caption)
                            .foregroundColor(.lvTextSec)
                            .padding(.horizontal)
                    }

                    // Stage averages
                    if avgDeep + avgCore + avgREM > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lm.t(en: "Sleep stages (avg)", sv: "Sömnsteg (snitt)"))
                                .font(.subheadline.bold())
                                .foregroundColor(.lvTextSec)
                                .padding(.horizontal)
                            StageAvgRow(label: lm.t(en: "Deep", sv: "Djup"), minutes: avgDeep, color: .lvPurple, total: avgDeep + avgCore + avgREM)
                            StageAvgRow(label: lm.t(en: "Core", sv: "Kärn"), minutes: avgCore, color: .lvTeal, total: avgDeep + avgCore + avgREM)
                            StageAvgRow(label: "REM", minutes: avgREM, color: .lvAmber, total: avgDeep + avgCore + avgREM)
                        }
                    }

                    // Correlations (require ≥14 days)
                    if hkManager.history.count >= 14 {
                        CorrelationSection()
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

private struct StageAvgRow: View {
    let label: String
    let minutes: Int
    let color: Color
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.lvTextPri)
                .frame(width: 48, alignment: .leading)
            Text("\(minutes)m")
                .font(.subheadline.bold())
                .foregroundColor(color)
                .frame(width: 48)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.lvSurface2)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * CGFloat(minutes) / CGFloat(max(1, total)))
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
}

private struct CorrelationSection: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var hkManager: HealthKitManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lm.t(en: "Correlations", sv: "Korrelationer"))
                .font(.subheadline.bold())
                .foregroundColor(.lvTextSec)
                .padding(.horizontal)
            Text(lm.t(en: "Log evening check-ins for at least 14 nights to see correlations.",
                       sv: "Logga kvällscheck-ins i minst 14 nätter för att se korrelationer."))
                .font(.caption)
                .foregroundColor(.lvTextTert)
                .padding(.horizontal)
        }
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Views/Main/TrendsView.swift
git commit -m "feat: add TrendsView with 7-night chart and premium gate"
```

---

### Task 23: SettingsView

**Files:**
- Create: `Lumvra/Views/Settings/SettingsView.swift`

- [ ] Write `Lumvra/Views/Settings/SettingsView.swift`:
```swift
import SwiftUI
import RevenueCat

struct SettingsView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var storage: LocalStorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showDeleteAlert = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            List {
                // General
                Section(lm.t(en: "General", sv: "Allmänt")) {
                    Picker(lm.t(en: "Language", sv: "Språk"), selection: $lm.selectedLanguage) {
                        Text(lm.t(en: "System", sv: "System")).tag("system")
                        Text("English").tag("en")
                        Text("Svenska").tag("sv")
                    }
                    .onChange(of: lm.selectedLanguage) {
                        notificationManager.reschedule(profile: userState.profile, language: lm.resolvedLanguage)
                    }
                }
                .listRowBackground(Color.lvSurface)

                // Sleep goals
                Section(lm.t(en: "Sleep goals", sv: "Sömnmål")) {
                    DatePicker(lm.t(en: "Bedtime target", sv: "Läggdags-mål"),
                               selection: Binding(
                                get: { userState.profile.targetBedtime },
                                set: { userState.profile.targetBedtime = $0; save() }
                               ), displayedComponents: .hourAndMinute)
                    DatePicker(lm.t(en: "Wake time target", sv: "Uppvakningsmål"),
                               selection: Binding(
                                get: { userState.profile.targetWakeTime },
                                set: { userState.profile.targetWakeTime = $0; save() }
                               ), displayedComponents: .hourAndMinute)
                    Stepper(
                        lm.t(en: "Sleep goal: \(String(format: "%.1f", userState.profile.targetSleepHours))h",
                             sv: "Sömnmål: \(String(format: "%.1f", userState.profile.targetSleepHours))h"),
                        value: Binding(
                            get: { userState.profile.targetSleepHours },
                            set: { userState.profile.targetSleepHours = $0; save() }
                        ), in: 5.0...10.0, step: 0.5
                    )
                    .foregroundColor(.lvTextPri)
                }
                .listRowBackground(Color.lvSurface)

                // Notifications
                Section(lm.t(en: "Notifications", sv: "Notifikationer")) {
                    Toggle(lm.t(en: "Morning reminder", sv: "Morgonpåminnelse"),
                           isOn: Binding(
                            get: { userState.profile.morningNotificationsEnabled },
                            set: { userState.profile.morningNotificationsEnabled = $0; save(); reschedule() }
                           ))
                    Toggle(lm.t(en: "Evening reminder", sv: "Kvällspåminnelse"),
                           isOn: Binding(
                            get: { userState.profile.eveningNotificationsEnabled },
                            set: { userState.profile.eveningNotificationsEnabled = $0; save(); reschedule() }
                           ))
                }
                .listRowBackground(Color.lvSurface)

                // Tracking
                Section(lm.t(en: "Track", sv: "Spåra")) {
                    Toggle(lm.t(en: "Alcohol", sv: "Alkohol"),
                           isOn: Binding(get: { userState.profile.alcoholTracking },
                                         set: { userState.profile.alcoholTracking = $0; save() }))
                    Toggle(lm.t(en: "Coffee", sv: "Kaffe"),
                           isOn: Binding(get: { userState.profile.coffeeTracking },
                                         set: { userState.profile.coffeeTracking = $0; save() }))
                    Toggle(lm.t(en: "Exercise", sv: "Träning"),
                           isOn: Binding(get: { userState.profile.exerciseTracking },
                                         set: { userState.profile.exerciseTracking = $0; save() }))
                }
                .listRowBackground(Color.lvSurface)

                // Account
                Section(lm.t(en: "Account", sv: "Konto")) {
                    if userState.isPremium {
                        HStack {
                            Text(lm.t(en: "Subscription", sv: "Prenumeration"))
                                .foregroundColor(.lvTextPri)
                            Spacer()
                            Text(lm.t(en: "Active", sv: "Aktiv"))
                                .foregroundColor(.lvTeal)
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            Text(lm.t(en: "Upgrade to Premium", sv: "Uppgradera till Premium"))
                                .foregroundColor(.lvPurple)
                        }
                    }
                    Button {
                        Task {
                            _ = try? await Purchases.shared.restorePurchases()
                            await userState.refreshPremiumStatus()
                        }
                    } label: {
                        Text(lm.t(en: "Restore purchases", sv: "Återställ köp"))
                            .foregroundColor(.lvTextSec)
                    }
                }
                .listRowBackground(Color.lvSurface)

                // Data & Privacy
                Section(lm.t(en: "Data & Privacy", sv: "Data och integritet")) {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Text(lm.t(en: "Delete my data", sv: "Radera mina data"))
                    }
                }
                .listRowBackground(Color.lvSurface)

                // About
                Section(lm.t(en: "About", sv: "Om appen")) {
                    HStack {
                        Text(lm.t(en: "Version", sv: "Version"))
                            .foregroundColor(.lvTextPri)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.lvTextSec)
                    }
                }
                .listRowBackground(Color.lvSurface)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(lm.t(en: "Settings", sv: "Inställningar"))
        }
        .alert(lm.t(en: "Delete all data?", sv: "Radera all data?"),
               isPresented: $showDeleteAlert) {
            Button(lm.t(en: "Delete", sv: "Radera"), role: .destructive) {
                storage.clearAll()
            }
            Button(lm.t(en: "Cancel", sv: "Avbryt"), role: .cancel) {}
        } message: {
            Text(lm.t(en: "This cannot be undone.", sv: "Detta kan inte ångras."))
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func save() { userState.saveProfile() }
    private func reschedule() {
        notificationManager.reschedule(profile: userState.profile, language: lm.resolvedLanguage)
    }
}
```

- [ ] Commit:
```bash
git add Lumvra/Views/Settings/SettingsView.swift
git commit -m "feat: add SettingsView with all settings sections"
```

---

### Task 24: MainTabView

**Files:**
- Create: `Lumvra/Views/Main/MainTabView.swift`

- [ ] Write `Lumvra/Views/Main/MainTabView.swift`:
```swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var lm: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MorningView()
                .tabItem { Label(lm.t(en: "Today", sv: "Idag"), systemImage: "moon.stars") }
                .tag(0)

            EveningView()
                .tabItem { Label(lm.t(en: "Evening", sv: "Kväll"), systemImage: "sunset") }
                .tag(1)

            TrendsView()
                .tabItem { Label(lm.t(en: "Trends", sv: "Trender"), systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(lm.t(en: "Settings", sv: "Inställningar"), systemImage: "gearshape") }
            .tag(3)
        }
        .tint(.lvPurple)
    }
}
```

- [ ] Build to verify compilation:
```bash
cd "/Users/tedsvard/Library/Mobile Documents/com~apple~CloudDocs/Lumvra"
xcodebuild build -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -20
```
Expected: `** BUILD SUCCEEDED **`. Fix any errors before committing.

- [ ] Run all tests:
```bash
xcodebuild test -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -20
```

- [ ] Commit:
```bash
git add Lumvra/Views/Main/MainTabView.swift
git commit -m "feat: add MainTabView — complete UI phase"
```

---

## Phase 8 — App Store Readiness

### Task 25: App icon

**Files:**
- Create: `Lumvra/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] Generate a 1024×1024 app icon. Create a purple gradient moon icon as SVG, then export at all required sizes. At minimum, add a placeholder `Contents.json` and a 1024pt PNG:

- [ ] Write `Lumvra/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images": [
    { "idiom": "universal", "platform": "ios", "size": "1024x1024", "filename": "AppIcon-1024.png", "scale": "1x" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

- [ ] Create a simple programmatic icon — run this Swift snippet to generate a 1024×1024 PNG:
```bash
swift - << 'EOF'
import Cocoa
let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
// Background gradient
let colors = [CGColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1),
              CGColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1)]
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                      colors: colors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: 1024), options: [])
// Moon
ctx.setFillColor(CGColor(red: 0.498, green: 0.467, blue: 0.867, alpha: 1))
ctx.fillEllipse(in: CGRect(x: 312, y: 280, width: 464, height: 464))
ctx.setFillColor(CGColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 1))
ctx.fillEllipse(in: CGRect(x: 380, y: 248, width: 416, height: 416))
image.unlockFocus()
guard let cgImg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { exit(1) }
let rep = NSBitmapImageRep(cgImage: cgImg)
let data = rep.representation(using: .png, properties: [:])!
let url = URL(fileURLWithPath: "Lumvra/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
try! data.write(to: url)
print("Icon written.")
EOF
```

- [ ] Commit:
```bash
git add "Lumvra/Assets.xcassets/AppIcon.appiconset/"
git commit -m "feat: add app icon"
```

---

### Task 26: Localizable.xcstrings

**Files:**
- Create: `Lumvra/Resources/Localizable.xcstrings`

Note: The app primarily uses `lm.t(en:sv:)` inline — this file satisfies App Store requirements and provides fallback for system strings.

- [ ] Write `Lumvra/Resources/Localizable.xcstrings`:
```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "app_name" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Lumvra" } },
        "sv" : { "stringUnit" : { "state" : "translated", "value" : "Lumvra" } }
      }
    },
    "sleep_score" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Sleep Score" } },
        "sv" : { "stringUnit" : { "state" : "translated", "value" : "Sömnpoäng" } }
      }
    },
    "good_morning" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Good morning 🌙" } },
        "sv" : { "stringUnit" : { "state" : "translated", "value" : "God morgon 🌙" } }
      }
    },
    "evening_checkin" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Evening check-in 🌙" } },
        "sv" : { "stringUnit" : { "state" : "translated", "value" : "Kvällskoll 🌙" } }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] Commit:
```bash
git add Lumvra/Resources/Localizable.xcstrings
git commit -m "feat: add Localizable.xcstrings for en/sv"
```

---

### Task 27: Final build verification + push to GitHub

- [ ] Regenerate Xcode project (picks up any new files):
```bash
cd "/Users/tedsvard/Library/Mobile Documents/com~apple~CloudDocs/Lumvra"
xcodegen generate
```

- [ ] Full build:
```bash
xcodebuild build -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | grep -E "error:|warning:|BUILD"
```
Expected: `** BUILD SUCCEEDED **` with zero errors.

- [ ] Full test suite:
```bash
xcodebuild test -scheme Lumvra -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -10
```
Expected: `** TEST SUCCEEDED **`

- [ ] Push all to GitHub:
```bash
cd "/Users/tedsvard/Library/Mobile Documents/com~apple~CloudDocs/Lumvra"
git add -A
git status  # verify Config.plist is NOT listed
git commit -m "chore: regenerate Xcode project and final cleanup"
git push origin main
```

- [ ] Verify repo:
```bash
gh repo view Terrorbyte90/Lumvra --web
```

---

## Post-Launch Checklist (manual, before TestFlight)

- [ ] Fill in real API keys in `Lumvra/Config/Config.plist`
- [ ] Set `DEVELOPMENT_TEAM` in `project.yml` to your Apple Developer team ID, then run `xcodegen generate`
- [ ] Configure HealthKit capability in Xcode → Signing & Capabilities (or add entitlements file)
- [ ] Create products in App Store Connect matching StoreKit IDs in PaywallView
- [ ] Configure RevenueCat dashboard with matching product IDs and entitlements `premium` + `lifetime`
- [ ] Set 7-day free trial on `premium.yearly` in App Store Connect
- [ ] Archive and upload via Xcode → Product → Archive
- [ ] Add Privacy Policy URL and Support URL in App Store Connect
- [ ] Create screenshots for iPhone 16 Pro Max (6.9") and iPhone SE
