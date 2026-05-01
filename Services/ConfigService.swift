import Foundation

enum DisplayMode: String, Codable {
    case used
    case remaining
}

final class ConfigService {
    static let shared = ConfigService()

    private var cachedDisplayMode: DisplayMode = .used
    private var cachedActivePlatform: PlatformType = .minimax
    private var platformStores: [PlatformType: PlatformConfigStore] = [:]

    // Legacy support
    private let legacyConfigPath: URL
    private var cachedToken: String?
    private var cachedGroupId: String?

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        legacyConfigPath = home.appendingPathComponent(".minimax-config.json")

        loadLegacyConfig()
        loadGlobalConfig()

        // Migrate legacy config
        PlatformConfigStore.migrateIfNeeded()
    }

    // MARK: - Global Config

    var displayMode: DisplayMode {
        get { cachedDisplayMode }
        set {
            cachedDisplayMode = newValue
            saveGlobalConfig()
        }
    }

    var activePlatform: PlatformType {
        get { cachedActivePlatform }
        set {
            cachedActivePlatform = newValue
            saveGlobalConfig()
        }
    }

    // MARK: - Platform Stores

    func store(for platform: PlatformType) -> PlatformConfigStore {
        if let existing = platformStores[platform] {
            return existing
        }
        let store = PlatformConfigStore(platformType: platform)
        platformStores[platform] = store
        return store
    }

    func configuredPlatforms() -> [PlatformType] {
        PlatformType.allCases.filter { store(for: $0).isConfigured }
    }

    // MARK: - Legacy Support (backward compatibility)

    var token: String? {
        get { cachedToken }
        set {
            cachedToken = newValue
            saveLegacyConfig()
        }
    }

    var groupId: String? {
        get { cachedGroupId }
        set {
            cachedGroupId = newValue
            saveLegacyConfig()
        }
    }

    var isConfigured: Bool {
        cachedToken != nil
    }

    func setCredentials(token: String, groupId: String?) {
        self.cachedToken = token
        self.cachedGroupId = groupId
        saveLegacyConfig()
    }

    // MARK: - Private

    private func loadGlobalConfig() {
        if let raw = UserDefaults.standard.string(forKey: "quotabar.displayMode"),
           let mode = DisplayMode(rawValue: raw) {
            cachedDisplayMode = mode
        }
        if let raw = UserDefaults.standard.string(forKey: "quotabar.activePlatform"),
           let platform = PlatformType(rawValue: raw) {
            cachedActivePlatform = platform
        }
    }

    private func saveGlobalConfig() {
        UserDefaults.standard.set(cachedDisplayMode.rawValue, forKey: "quotabar.displayMode")
        UserDefaults.standard.set(cachedActivePlatform.rawValue, forKey: "quotabar.activePlatform")
    }

    private func loadLegacyConfig() {
        guard FileManager.default.fileExists(atPath: legacyConfigPath.path) else { return }

        do {
            let data = try Data(contentsOf: legacyConfigPath)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                cachedToken = json["token"] as? String
                cachedGroupId = json["groupId"] as? String
            }
        } catch {
            // Ignore load errors
        }
    }

    private func saveLegacyConfig() {
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
            try data.write(to: legacyConfigPath)
        } catch {
            // Ignore save errors
        }
    }
}
