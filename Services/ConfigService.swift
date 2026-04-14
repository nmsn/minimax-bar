import Foundation

enum DisplayMode: String, Codable {
    case used
    case remaining
}

final class ConfigService {
    static let shared = ConfigService()

    private let configPath: URL
    private var cachedToken: String?
    private var cachedGroupId: String?
    private var cachedDisplayMode: DisplayMode = .used

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configPath = home.appendingPathComponent(".minimax-config.json")
        loadConfig()
    }

    var token: String? {
        get { cachedToken }
        set {
            cachedToken = newValue
            saveConfig()
        }
    }

    var groupId: String? {
        get { cachedGroupId }
        set {
            cachedGroupId = newValue
            saveConfig()
        }
    }

    var displayMode: DisplayMode {
        get { cachedDisplayMode }
        set {
            cachedDisplayMode = newValue
            saveConfig()
        }
    }

    var isConfigured: Bool {
        cachedToken != nil
    }

    private func loadConfig() {
        guard FileManager.default.fileExists(atPath: configPath.path) else { return }

        do {
            let data = try Data(contentsOf: configPath)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                cachedToken = json["token"] as? String
                cachedGroupId = json["groupId"] as? String
                if let modeString = json["displayMode"] as? String,
                   let mode = DisplayMode(rawValue: modeString) {
                    cachedDisplayMode = mode
                }
            }
        } catch {
            // Ignore load errors, use defaults
        }
    }

    private func saveConfig() {
        var json: [String: Any] = [:]
        if let token = cachedToken {
            json["token"] = token
        }
        if let groupId = cachedGroupId {
            json["groupId"] = groupId
        }
        json["displayMode"] = cachedDisplayMode.rawValue

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try data.write(to: configPath)
        } catch {
            // Ignore save errors
        }
    }

    func setCredentials(token: String, groupId: String?) {
        self.cachedToken = token
        self.cachedGroupId = groupId
        saveConfig()
    }
}