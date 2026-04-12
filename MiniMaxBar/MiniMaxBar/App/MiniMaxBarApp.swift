import SwiftUI

@main
struct MiniMaxBarApp: App {
    @State private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(viewModel: viewModel)
                .onAppear {
                    viewModel.startAutoRefresh()
                }
        } label: {
            StatusBarView(usageData: viewModel.usageData)
        }
        .menuBarExtraStyle(.window)
    }
}