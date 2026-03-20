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
