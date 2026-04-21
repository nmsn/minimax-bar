import Foundation
import SwiftUI
import Combine

@MainActor
protocol UsageViewModelDelegate: AnyObject {
    func usageViewModel(_ viewModel: UsageViewModel, didUpdateUsageData data: UsageData?)
}

@MainActor
final class UsageViewModel: ObservableObject {
    var usageData: UsageData?
    var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isConfigured: Bool = false
    @Published var showingTokenInput: Bool = false
    @Published var showingTokenReset: Bool = false
    @Published var tokenInput: String = ""

    weak var delegate: UsageViewModelDelegate?

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
            errorMessage = I18nService.shared.translate("error.tokenRequired")
            return
        }

        isConfigured = true
        isLoading = true
        errorMessage = nil

        do {
            let data = try await MiniMaxAPIService.shared.fetchUsage()
            self.usageData = data
            self.errorMessage = nil
            delegate?.usageViewModel(self, didUpdateUsageData: data)
        } catch {
            self.errorMessage = error.localizedDescription
            delegate?.usageViewModel(self, didUpdateUsageData: nil)
        }

        isLoading = false
    }

    func refresh() async {
        await fetchUsage()
    }

    func toggleTokenInput() {
        withAnimation {
            if isConfigured {
                showingTokenReset = true
                showingTokenInput = false
            } else {
                showingTokenInput = true
                showingTokenReset = false
            }
        }
    }

    func showTokenReset() {
        withAnimation {
            showingTokenInput = true
            showingTokenReset = false
            tokenInput = ""
        }
    }

    func saveToken() {
        let trimmedToken = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else { return }

        ConfigService.shared.token = trimmedToken
        isConfigured = true
        showingTokenInput = false
        showingTokenReset = false
        tokenInput = ""

        Task {
            await fetchUsage()
        }
    }

    func cancelTokenInput() {
        withAnimation {
            showingTokenInput = false
            showingTokenReset = false
            tokenInput = ""
        }
    }

    func resetToUsageView() {
        showingTokenInput = false
        showingTokenReset = false
        tokenInput = ""
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}