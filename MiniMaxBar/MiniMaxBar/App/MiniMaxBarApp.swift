import SwiftUI

@main
struct MiniMaxBarApp: App {
    @State private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(viewModel: viewModel)
        } label: {
            StatusBarView(usageData: viewModel.usageData)
        }
        .menuBarExtraStyle(.window)
        .onAppear {
            viewModel.startAutoRefresh()
        }
    }
}