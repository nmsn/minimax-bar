import Foundation
import SwiftUI

@MainActor
@Observable
final class UsageViewModel {
    var usageData: UsageData?
    var errorMessage: String?
    var isLoading: Bool = false
    var isConfigured: Bool = false

    private var timer: Timer?

    init() {
        isConfigured = ConfigService.shared.isConfigured
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchUsage()
            }
        }
        Task {
            await fetchUsage()
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    func fetchUsage() async {
        guard ConfigService.shared.isConfigured else {
            isConfigured = false
            errorMessage = "未配置 Token"
            return
        }

        isConfigured = true
        isLoading = true
        errorMessage = nil

        do {
            let data = try await MiniMaxAPIService.shared.fetchUsage()
            self.usageData = data
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await fetchUsage()
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}