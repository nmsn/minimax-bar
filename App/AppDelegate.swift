import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var viewModel: UsageViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        viewModel = UsageViewModel()
        statusBarController = StatusBarController(viewModel: viewModel!)

        viewModel?.delegate = self
        viewModel?.startAutoRefresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        viewModel?.cleanup()
    }
}

extension AppDelegate: UsageViewModelDelegate {
    func usageViewModel(_ viewModel: UsageViewModel, didUpdateUsageData data: UsageData?) {
        statusBarController?.update(usageData: data)
    }
}