import Foundation
import Sparkle

@MainActor
final class UpdateService: ObservableObject {
    static let shared = UpdateService()

    private let updaterController: SPUStandardUpdaterController

    @Published var canCheckForUpdates: Bool = false
    @Published var lastUpdateCheckDate: Date?

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
