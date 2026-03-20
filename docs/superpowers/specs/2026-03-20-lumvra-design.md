# Lumvra — Sleep Coach App Design Spec
**Version:** 1.3 (post third review)
**Date:** 2026-03-20
**Platform:** iOS 17.0+ (iPhone)
**Languages:** English (default) + Swedish (system/manual)
**Bundle ID:** com.terrorbyte90.lumvra

---

## Overview

Lumvra is an AI sleep coach that reads existing sleep data from Apple Health and delivers one personalised insight each morning and a bedtime recommendation each evening. The app does not track sleep — it interprets and coaches. Apple Watch or third-party devices (Oura, Garmin, Fitbit) via HealthKit provide full stage data; iPhone-only users receive basic time-in-bed insights.

**Supabase is deferred.** All persistence during development uses `UserDefaults`/`@AppStorage`. `SupabaseManager.swift` is scaffolded as a no-op stub with the same API surface as the future live implementation.

---

## Phase Breakdown

### Phase 1 — Foundation & Data Layer
- GitHub repo `Lumvra` (public) under Terrorbyte90
- Xcode project `Lumvra`, bundle ID `com.terrorbyte90.lumvra`
- Project folder structure per spec
- `Config.plist` (gitignored) for API keys — see Config.plist key names below
- `Config.example.plist` with placeholder values, committed to repo
- `.gitignore` covering Config.plist, xcuserstate, DerivedData, .DS_Store
- Swift models: `SleepData`, `SleepInsight`, `UserProfile`, `DataQuality`, `EveningCheckin`
- `Extensions/Color+Hex.swift` — `Color(hex:)` initialiser
- `HealthKitManager` — authorization, sleep queries, stage processing, score calculation
- `LanguageManager` — resolves system/en/sv, exposes `t(en:sv:)` helper
- `NotificationManager` — morning + evening local notifications
- `LocalStorageManager` — UserDefaults-backed storage (full API below)
- `SupabaseManager` — no-op stub mirroring `LocalStorageManager` API
- `UserState` — ObservableObject holding runtime premium state

### Phase 2 — Onboarding
- `OnboardingContainerView` — step-based container driven by `@AppStorage("hasCompletedOnboarding")`
- `WelcomeView`
- `HealthKitPermissionView` — triggers HK auth; continues to next step regardless of outcome
- `NotificationPermissionView` — skippable
- `LoadingDataView` — fetches 30-night history; sets `hasCompletedOnboarding = true` then transitions to `MainTabView` regardless of HK result (zero samples → `.noData` state shown in `MorningView`)

### Phase 3 — Core UI
- `MorningView`, `EveningView`, `TrendsView`, `SettingsView`
- Components: `SleepScoreRing`, `InsightCard`, `StageBar`, `CheckInButton`, `WatchUpgradePrompt`, `DataQualityBadge`

### Phase 4 — AI & Monetisation
- `AIManager` — two async methods: `generateMorningInsight` and `generateBedtimeRecommendation`
- `PaywallView`
- RevenueCat SDK setup and entitlement gating

### Phase 5 — App Store Readiness
- App icon asset catalog
- `Localizable.xcstrings` — complete en + sv
- `Info.plist` keys
- Xcode capabilities: HealthKit, StoreKit In-App Purchase
- Stub finalised, all code pushed to GitHub

---

## Architecture

### Key Types (injected via `@EnvironmentObject`)

| Type | File | Responsibility |
|---|---|---|
| `LanguageManager` | `Managers/LanguageManager.swift` | Language resolution, `t(en:sv:)` |
| `HealthKitManager` | `Managers/HealthKitManager.swift` | HK auth, sleep queries, score |
| `AIManager` | `Managers/AIManager.swift` | Haiku REST calls |
| `NotificationManager` | `Managers/NotificationManager.swift` | Local notification scheduling |
| `LocalStorageManager` | `Managers/LocalStorageManager.swift` | UserDefaults persistence |
| `SupabaseManager` | `Managers/SupabaseManager.swift` | No-op stub |
| `UserState` | `Models/UserState.swift` | Runtime premium state + profile cache |

### UserState

`UserState` is the single source of truth for premium status at runtime. It holds a `UserProfile` in memory (loaded from `LocalStorageManager` on launch) and is updated by the RevenueCat entitlement check. It does **not** duplicate storage — `LocalStorageManager` persists the profile; `UserState` is the live in-memory copy.

```swift
@MainActor
class UserState: ObservableObject {
    @Published var profile: UserProfile
    @Published var isPremium: Bool = false

    init(storage: LocalStorageManager) {
        self.profile = storage.loadProfile() ?? UserProfile.default
    }

    func refreshPremiumStatus() async {
        let info = try? await Purchases.shared.customerInfo()
        isPremium = info?.entitlements["premium"]?.isActive == true
                 || info?.entitlements["lifetime"]?.isActive == true
        profile.isPremium = isPremium
    }
}
```

`UserProfile.isPremium` is synced from `UserState.isPremium` for caching purposes, but all in-app gating checks `UserState.isPremium` (not `UserProfile.isPremium`).

### Navigation

`ContentView` checks `@AppStorage("hasCompletedOnboarding")`:
- `false` → `OnboardingContainerView`
- `true` → `MainTabView`

`LoadingDataView` sets `hasCompletedOnboarding = true` (via `@AppStorage`) and replaces root content by writing the flag — `ContentView` re-evaluates automatically.

```swift
enum AppTab: Int { case morning, evening, trends, settings }
```

Tab bar tint: `Color.lvPurple`. Default colour scheme: `.dark`.

**HealthKit denial recovery:** `MorningView` checks `HealthKitManager.authorizationStatus`. If denied, a banner prompts the user to open Settings. Tapping it calls `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`.

### TrendsView Premium Gate
Free users: the Trends tab shows `PaywallView` in full (entire tab body replaced). No partial content reveal.

---

## Swift Models

### DataQuality
```swift
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

### SleepData
```swift
struct SleepData: Codable {
    let date: Date
    let quality: DataQuality
    let inBedMinutes: Int
    let totalSleepMinutes: Int   // deep + core + REM (0 if basic/partial)
    let bedtime: Date
    let wakeTime: Date
    let score: Int               // 0–100 (capped at 75 for .basic; see algorithm)
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

### SleepInsight
```swift
struct SleepInsight: Codable {
    let id: UUID
    let date: Date
    let morningInsight: String
    let bedtimeRecommendation: String  // AI text (premium) or formatted HH:MM string (free)
    let recommendedBedtime: Date       // Parsed from AI "HH:MM" output; falls back to UserProfile.targetBedtime
    let sleepScore: Int
    let language: String
    let dataQuality: DataQuality
    let generatedAt: Date
}
```

**Parsing `recommendedBedtime`:** After receiving the AI bedtime text (e.g., `"22:15 — your body responds well to consistent timing"`), extract the first `HH:MM` token using a regex (`\d{2}:\d{2}`), then parse with `DateFormatter(dateFormat: "HH:mm")` applied to today's date. If parsing fails, fall back to `UserProfile.targetBedtime`. Free users: skip the AI call entirely; set `bedtimeRecommendation` to the formatted `targetBedtime` string and `recommendedBedtime` to `UserProfile.targetBedtime`.

### EveningCheckin
```swift
struct EveningCheckin: Codable {
    let date: Date               // Always Calendar.current.startOfDay(for: Date())
    var hadAlcohol: Bool
    var hadCoffeeAfter2pm: Bool
    var exercised: Bool
}
```

All callers that create or look up a checkin must normalise the date using `Calendar.current.startOfDay(for: Date())` before encoding to the `"yyyy-MM-dd"` UserDefaults key. This ensures consistent key matching across call sites.

### UserProfile
```swift
struct UserProfile: Codable {
    let id: UUID
    var targetBedtime: Date
    var targetWakeTime: Date
    var targetSleepHours: Double  // 5.0–10.0
    var alcoholTracking: Bool
    var coffeeTracking: Bool
    var exerciseTracking: Bool
    var isPremium: Bool           // Cache; authoritative value is UserState.isPremium
    var hasSeenWatchPrompt: Bool
    var language: String          // "system" | "en" | "sv"
    var morningNotificationsEnabled: Bool  // default true
    var eveningNotificationsEnabled: Bool  // default true

    static var `default`: UserProfile {
        UserProfile(id: UUID(), targetBedtime: Calendar.current.date(from: DateComponents(hour: 22, minute: 30))!,
                    targetWakeTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!,
                    targetSleepHours: 8.0, alcoholTracking: true, coffeeTracking: true,
                    exerciseTracking: true, isPremium: false, hasSeenWatchPrompt: false, language: "system",
                    morningNotificationsEnabled: true, eveningNotificationsEnabled: true)
    }
}
```

---

## HealthKit Integration

**Sample type:** `HKObjectType.categoryType(forIdentifier: .sleepAnalysis)`

**"Last night" query window:** previous day 6 PM → current day noon. Captures late sleepers and early risers.

**Multi-source deduplication:**
1. Collect all samples in window.
2. If any samples have stage values (`.asleepDeep`, `.asleepCore`, `.asleepREM`), discard samples from other sources that have only `.inBed` or `.awake` for the same time ranges.
3. If multiple sources provide stage data, prefer the source with the highest total sample count.

**DataQuality detection heuristic:**
```
if any sample has .asleepDeep OR .asleepCore OR .asleepREM:
    quality = .full

else if any sample has .awake AND source bundleIdentifier starts with "com.apple.health"
         AND device model contains "Watch":
    quality = .partial

else if any sample has .inBed:
    quality = .basic

else:
    quality = .noData
```

**Authorization:** read `[HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]`, write `[]`.

### Sleep Score Algorithm

```
// .basic (iPhone only)
if quality == .basic:
    score = min(75, Int(Double(inBedMinutes) / 60.0 / 8.0 * 75))

// .partial (awake data only, no stages)
else if quality == .partial:
    // Use duration from inBedMinutes; deep/REM terms score 0 (intentional)
    // Not capped — partial data can score up to 100 via duration + awake count
    score = 0
    score += min(40, Int(Double(inBedMinutes) / 60.0 / 8.0 * 40))
    score += max(0, 10 - awakeCount * 2)
    score = min(100, score)

// .full (all stages available)
else:
    score = 0
    score += min(40, Int(Double(totalSleepMinutes) / 60.0 / 8.0 * 40))
    score += min(30, Int(Double(deepMinutes) / Double(totalSleepMinutes) / 0.20 * 30))
    score += min(20, Int(Double(remMinutes) / Double(totalSleepMinutes) / 0.25 * 20))
    score += max(0, 10 - awakeCount * 2)
    score = min(100, score)
```

---

## AI Integration (Claude Haiku)

**Model ID:** `claude-haiku-4-5-20251001`
*(Verify against https://docs.anthropic.com/en/docs/about-claude/models before shipping)*

**Base URL:** `https://api.anthropic.com/v1/messages`

**Headers (both calls):**
```
Content-Type: application/json
x-api-key: <Config.plist ANTHROPIC_API_KEY>
anthropic-version: 2023-06-01
```

**Timeout:** 15 seconds for both calls.

### Morning Insight

**System prompt (full data):**
```
You are a concise sleep coach. Respond ONLY in {language}.
Full sleep stage data available (deep, core, REM, awakenings).
Generate ONE specific, personalised insight about last night's sleep. Max 28 words.
Be specific — use the exact numbers. Never say "it seems" or "it appears". Be direct.
No markdown, no lists, plain sentence only.
```

**System prompt (basic/partial data):**
```
You are a concise sleep coach. Respond ONLY in {language}.
Only time-in-bed data available — no sleep stages. Mention this limitation naturally.
Generate ONE personalised insight about last night's sleep. Max 28 words.
No markdown, no lists, plain sentence only.
```

**Request body (morning):**
```json
{
  "model": "claude-haiku-4-5-20251001",
  "max_tokens": 80,
  "system": "<system prompt above with {language} filled in>",
  "messages": [{
    "role": "user",
    "content": "{\"score\":72,\"inBed\":460,\"deep\":58,\"core\":212,\"rem\":94,\"wake\":2,\"avg7deep\":52,\"avg7total\":438}"
  }]
}
```

Field key reference:
- Always included: `score` (Int), `inBed` (Int, minutes)
- `.full` only: `deep`, `core`, `rem` (Int, minutes), `wake` (Int, count), `avg7deep`, `avg7total` (Int, minutes)
- `.basic` only: `avg7inBed` (Int, minutes) replaces `avg7total`; omit stage fields entirely
- Optional (if tracked and truthy): `alcohol` (Bool), `lateCoffee` (Bool), `exercised` (Bool)

**Fallback (any error):**
- EN: `"Open the app tomorrow morning for your sleep insight."`
- SV: `"Öppna appen imorgon bitti för din sömninsikt."`

### Bedtime Recommendation

**System prompt:**
```
You are a sleep coach. Respond ONLY in {language}.
Give ONE bedtime recommendation for tonight: state the time in HH:MM format followed by one short reason.
Max 20 words total. No markdown, plain text only.
```

**Request body (bedtime):**
```json
{
  "model": "claude-haiku-4-5-20251001",
  "max_tokens": 60,
  "system": "<system prompt above with {language} filled in>",
  "messages": [{
    "role": "user",
    "content": "{\"wake_at\":<hour int>,\"avg_bedtime\":<float>,\"avg_score\":<int>,\"target_hours\":8}"
  }]
}
```

**Fallback:** format `targetBedtime` from `UserProfile` as `HH:MM` and return it directly.

### Cache Behaviour
Before every API call, check `LocalStorageManager.loadCachedInsight(for: today)`. If non-nil, return cached value. Cache is keyed by `"yyyy-MM-dd"` (local timezone). Write to cache after every successful call.

**Data never sent:** dates, names, Apple ID, exact timestamps, location.

---

## NotificationManager

**Scheduling trigger:** called from `LoadingDataView` (initial schedule on onboarding completion) and from `SettingsView` on any notification setting change.

**On reschedule:** cancel all pending notifications first (`center.removeAllPendingNotificationRequests()`), then add new ones.

**Morning notification:**
- Schedule time: `UserProfile.targetWakeTime` + 15 minutes (give the user time to look at their phone)
- Trigger: `UNCalendarNotificationTrigger(dateMatching: components, repeats: true)`
- Title (EN): `"Good morning 🌙"` / (SV): `"God morgon 🌙"`
- Body (EN): `"Your sleep insight from last night is ready."` / (SV): `"Din sömninsikt för igår natt är redo."`
- Identifier: `"lumvra.morning"`

**Evening notification:**
- Schedule time: `UserProfile.targetBedtime` − 60 minutes
- Title (EN): `"Evening check-in 🌙"` / (SV): `"Kvällskoll 🌙"`
- Body (EN): `"Log your day for better sleep insights."` / (SV): `"Logga din dag för bättre sömninsikter."`
- Identifier: `"lumvra.evening"`

Both notifications require `morningNotificationsEnabled` and `eveningNotificationsEnabled` to be `true`. These are fields on `UserProfile` (not standalone `@AppStorage`) with defaults `true`. When either toggle changes in `SettingsView`, call `NotificationManager.reschedule(profile:language:)` in the toggle's `.onChange` handler.

---

## LocalStorageManager API

All `LocalStorageManager` methods are `@MainActor`. `SupabaseManager` must implement identical signatures (as no-ops initially).

```swift
protocol SleepStorage {
    func loadProfile() -> UserProfile?
    func saveProfile(_ profile: UserProfile)
    func loadCheckin(for date: Date) -> EveningCheckin?
    func saveCheckin(_ checkin: EveningCheckin)
    func loadCachedInsight(for date: Date) -> SleepInsight?
    func cacheInsight(_ insight: SleepInsight)
    func clearAll()                              // GDPR delete
    func loadDeviceId() -> UUID                  // Creates + stores in Keychain on first call
}
```

`LocalStorageManager` implements `SleepStorage` using `UserDefaults.standard` + JSON encoding.
`SupabaseManager` implements `SleepStorage` as no-ops (returning `nil`/no-op saves) until Supabase is activated.

**UserDefaults keys:**
| Key | Type |
|---|---|
| `"userProfile"` | `UserProfile` (JSON) |
| `"eveningCheckins"` | `[String: EveningCheckin]` (JSON), keyed `"yyyy-MM-dd"` |
| `"insightCache"` | `[String: SleepInsight]` (JSON), keyed `"yyyy-MM-dd"` |
| `"hasCompletedOnboarding"` | `Bool` |

Device UUID: Keychain, service `"com.terrorbyte90.lumvra"`, account key `"deviceId"`.

---

## Premium Gating — Concrete Enforcement Points

All gates check `userState.isPremium` from the injected `@EnvironmentObject UserState`.

| Feature | Free experience | Gate location |
|---|---|---|
| **AI morning insight** | `InsightCard` shows a blurred placeholder text + lock icon + "Upgrade to see your insight" + CTA button to PaywallView | `MorningView` body |
| **Evening coaching / check-in** | `EveningView` shows bedtime recommendation (non-AI, formatted from `UserProfile.targetBedtime`) but the check-in toggles and save button are hidden; replaced by a "Unlock evening coaching" card → PaywallView | `EveningView` body |
| **90-day history** | Free users see last 7 days only in any history-based views | `LocalStorageManager` query clamped in `HealthKitManager.fetchSleepHistory` |
| **Trends tab** | Entire `TrendsView` body replaced by `PaywallView` | `TrendsView` body: `if userState.isPremium { content } else { PaywallView() }` |
| **Sleep debt tracker** | Hidden (not shown at all in free tier) | `MorningView` conditional |
| **Weekly summary** | Not shown | `SettingsView` or notification — not triggered if not premium |

---

## EveningView Behaviour

1. On appear: load today's checkin from `LocalStorageManager.loadCheckin(for: today)`. Pre-populate toggles if a saved checkin exists.
2. Toggles update local `@State` only (not persisted until save).
3. "Save" button calls `LocalStorageManager.saveCheckin(EveningCheckin(date: today, ...))`, then shows a brief "Saved ✓" inline confirmation (no navigation change).
4. The checkin date is `Calendar.current.startOfDay(for: Date())`.
5. Free users: save button is hidden entirely (gate enforced as described above).

---

## Colour Palette

File: `Extensions/Color+Hex.swift`

```swift
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

    // lv prefix = Lumvra internal palette (6-digit hex only, no alpha)
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
}
```

### Score Colour

File: `Extensions/Color+Hex.swift` (same file, static method on `Color` extension):

```swift
extension Color {
    static func forScore(_ score: Int) -> Color {
        score >= 70 ? .lvTeal : score >= 40 ? .lvAmber : .lvRed
    }
}
```

Call site: `Color.forScore(sleepData.score)`

---

## RevenueCat Setup

**Config.plist reading:** All four keys are read at runtime via a `ConfigManager` helper that loads `Config.plist` from the app bundle:
```swift
enum ConfigManager {
    static func value(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else { return "" }
        return dict[key] as? String ?? ""
    }
}
```

**Configure in** `LumvraApp.init()`:
```swift
Purchases.configure(withAPIKey: ConfigManager.value(for: "REVENUECAT_API_KEY"))
```

**Entitlement identifiers:**
- `"premium"` — monthly + yearly plans
- `"lifetime"` — one-time purchase

**StoreKit product identifiers:**
- `com.terrorbyte90.lumvra.premium.monthly`
- `com.terrorbyte90.lumvra.premium.yearly` (7-day free trial configured in App Store Connect)
- `com.terrorbyte90.lumvra.lifetime`

**Entitlement propagation:** `UserState.refreshPremiumStatus()` called on `LumvraApp.body` appear and after any purchase or restore.

---

## Config.plist Key Names

```
ANTHROPIC_API_KEY     → AIManager
SUPABASE_URL          → SupabaseManager (stub, unused at launch)
SUPABASE_ANON_KEY     → SupabaseManager (stub, unused at launch)
REVENUECAT_API_KEY    → LumvraApp.init()
```

`Config.example.plist` committed to repo with placeholder strings.

---

## Language Manager

```swift
// Signature — two labelled parameters
func t(en: String, sv: String) -> String { isSv ? sv : en }

// Call site
Text(lm.t(en: "Good morning", sv: "God morgon"))
```

`@AppStorage("selectedLanguage")` values: `"system"` | `"en"` | `"sv"`.

---

## Info.plist Requirements

```xml
<key>NSHealthShareUsageDescription</key>
<string>Lumvra reads your sleep data from Apple Health to generate personalised insights. Your data never leaves your device.</string>
```

No notification usage string required — `UNUserNotificationCenter.requestAuthorization()` handles the runtime prompt for local notifications on iOS 17.

**Xcode Capabilities at launch:** HealthKit, StoreKit In-App Purchase.
*(Push Notifications capability added in a future phase.)*

---

## Privacy

- Raw HealthKit data never leaves the device
- Claude API receives aggregated integers only — no PII, no dates, no exact times
- **At launch (Supabase deferred):** all data stored locally on-device only. No server-side collection.
  - Privacy Nutrition Label: Data Not Linked to You — Identifiers (device UUID, Keychain only)
- When Supabase is activated: anonymous device UUID + boolean checkins + cached AI text stored server-side. Update Privacy Label at that time.
- GDPR delete-all: Settings → Data & Privacy → Delete my data → `LocalStorageManager.clearAll()` + Keychain entry removal

---

## What Is Explicitly Out of Scope for MVP

- Supabase live integration (stub only)
- Push Notifications capability / APNs / remote push
- watchOS companion app
- macOS menu bar app
- Sleep data export
- A/B pricing experiments
- Lock screen widget
