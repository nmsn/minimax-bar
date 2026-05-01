import Foundation

final class PlatformConfigStore {
    let platformType: PlatformType
    let configPath: URL

    private(set) var apiBaseURL: String
    private(set) var authHeader: String
    private(set) var authPrefix: String
    private(set) var apiKey: String?

    var isConfigured: Bool {
        guard let key = apiKey else { return false }
        return !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(platformType: PlatformType, configPath: URL? = nil) {
        self.platformType = platformType
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.configPath = configPath ?? home.appendingPathComponent(".quotabar-\(platformType.rawValue).json")

        // Defaults from template
        self.apiBaseURL = ""
        self.authHeader = "Authorization"
        self.authPrefix = "Bearer "

        loadFromTemplateIfNeeded()
        load()
    }

    func toConfigData() -> PlatformConfigData {
        PlatformConfigData(
            platformType: platformType,
            apiBaseURL: apiBaseURL,
            authHeader: authHeader,
            authPrefix: authPrefix,
            apiKey: apiKey ?? ""
        )
    }

    func setAPIKey(_ key: String) {
        apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func resetAPIKey() {
        apiKey = nil
        save()
    }

    // MARK: - Migration

    static func migrateIfNeeded() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let oldPath = home.appendingPathComponent(".minimax-config.json")
        let newPath = home.appendingPathComponent(".quotabar-minimax.json")

        guard FileManager.default.fileExists(atPath: oldPath.path),
              !FileManager.default.fileExists(atPath: newPath.path) else { return }

        do {
            let data = try Data(contentsOf: oldPath)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            var newConfig: [String: Any] = [
                "api_base_url": "https://www.minimaxi.com/v1/api/openplatform/coding_plan/remains",
                "auth_header": "Authorization",
                "auth_prefix": "Bearer "
            ]

            if let token = json["token"] as? String {
                newConfig["api_key"] = token
            }

            let newData = try JSONSerialization.data(withJSONObject: newConfig, options: .prettyPrinted)
            try newData.write(to: newPath)

            // Rename old file to .bak
            let bakPath = home.appendingPathComponent(".minimax-config.json.bak")
            try FileManager.default.moveItem(at: oldPath, to: bakPath)
        } catch {
            // Migration failed silently
        }
    }

    // MARK: - Private

    private func loadFromTemplateIfNeeded() {
        guard !FileManager.default.fileExists(atPath: configPath.path) else { return }

        let templateName = "\(platformType.rawValue).template"
        guard let templateURL = Bundle.main.url(forResource: templateName, withExtension: "json", subdirectory: "ConfigTemplates") else { return }

        do {
            let templateData = try Data(contentsOf: templateURL)
            guard let json = try JSONSerialization.jsonObject(with: templateData) as? [String: Any] else { return }

            if let baseURL = json["api_base_url"] as? String {
                self.apiBaseURL = baseURL
            }
            if let header = json["auth_header"] as? String {
                self.authHeader = header
            }
            if let prefix = json["auth_prefix"] as? String {
                self.authPrefix = prefix
            }

            // Write template to config path
            try templateData.write(to: configPath)
        } catch {
            // Failed to copy template
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: configPath.path) else { return }

        do {
            let data = try Data(contentsOf: configPath)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            if let baseURL = json["api_base_url"] as? String {
                self.apiBaseURL = baseURL
            }
            if let header = json["auth_header"] as? String {
                self.authHeader = header
            }
            if let prefix = json["auth_prefix"] as? String {
                self.authPrefix = prefix
            }
            self.apiKey = json["api_key"] as? String
        } catch {
            // Load failed silently
        }
    }

    private func save() {
        var json: [String: Any] = [
            "api_base_url": apiBaseURL,
            "auth_header": authHeader,
            "auth_prefix": authPrefix
        ]

        if let key = apiKey {
            json["api_key"] = key
        } else {
            json["api_key"] = ""
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try data.write(to: configPath)
        } catch {
            // Save failed silently
        }
    }
}
