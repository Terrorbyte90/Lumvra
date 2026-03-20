import Foundation

enum AIError: Error {
    case invalidResponse
    case emptyContent
}

// final + Sendable: all stored properties are let (value types) — safe for cross-actor capture
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
            let avgDeep = avg7.map(\.deepMinutes).reduce(0, +) / max(1, avg7.count)
            let avgTotal = avg7.map(\.totalSleepMinutes).reduce(0, +) / max(1, avg7.count)
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
            let avgInBed = avg7.map(\.inBedMinutes).reduce(0, +) / max(1, avg7.count)
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
        let fallback = language == "Swedish"
            ? "Öppna appen imorgon bitti för din sömninsikt."
            : "Open the app tomorrow morning for your sleep insight."
        return await callHaiku(system: systemPrompt, user: userMessage, maxTokens: 80) ?? fallback
    }

    func generateBedtimeRecommendation(history: [SleepData],
                                        targetWakeTime: Date,
                                        language: String) async -> String {
        let recent = Array(history.prefix(7))
        let avgBedHour = recent.compactMap { d -> Double? in
            let c = Calendar.current.dateComponents([.hour, .minute], from: d.bedtime)
            return Double(c.hour ?? 22) + Double(c.minute ?? 0) / 60.0
        }.reduce(0, +) / Double(max(1, recent.count))

        let avgScore = recent.map(\.score).reduce(0, +) / max(1, recent.count)
        let wakeHour = Calendar.current.component(.hour, from: targetWakeTime)

        let systemPrompt = """
        You are a sleep coach. Respond ONLY in \(language).
        Give ONE bedtime recommendation for tonight: state the time in HH:MM format followed by one short reason.
        Max 20 words total. No markdown, plain text only.
        """
        let userMessage = "{\"wake_at\":\(wakeHour),\"avg_bedtime\":\(String(format: "%.1f", avgBedHour)),\"avg_score\":\(avgScore),\"target_hours\":8}"

        let fallback = formatTime(targetWakeTime)
        return await callHaiku(system: systemPrompt, user: userMessage, maxTokens: 60) ?? fallback
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
