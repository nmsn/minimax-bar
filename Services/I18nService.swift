import Foundation

final class I18nService {
    static let shared = I18nService()

    private let userDefaultsLocaleKey = "app.locale"
    private let defaultLocale = "en"

    private(set) var translations: [String: [String: String]] = [:]
    private(set) var currentLocale: String = "en"

    private init() {}

    func loadTranslations() {
        currentLocale = UserDefaults.standard.string(forKey: userDefaultsLocaleKey) ?? defaultLocale

        if let enURL = Bundle.main.url(forResource: "en", withExtension: "json"),
           let enData = try? Data(contentsOf: enURL),
           let enJson = try? JSONSerialization.jsonObject(with: enData) as? [String: String] {
            translations["en"] = enJson
        }

        if let zhHansURL = Bundle.main.url(forResource: "zh-Hans", withExtension: "json"),
           let zhHansData = try? Data(contentsOf: zhHansURL),
           let zhHansJson = try? JSONSerialization.jsonObject(with: zhHansData) as? [String: String] {
            translations["zh-Hans"] = zhHansJson
        }
    }

    func translate(_ key: String) -> String {
        return translations[currentLocale]?[key] ?? key
    }

    func setLocale(_ locale: String) {
        currentLocale = locale
        UserDefaults.standard.set(locale, forKey: userDefaultsLocaleKey)
    }
}
