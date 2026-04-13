import AppKit
import SwiftUI

@MainActor
class StatusBarController {
    private static let minimumItemWidth: CGFloat = 40

    private var statusItem: NSStatusItem
    private var hostingView: NSHostingView<StatusBarView>
    private let viewModel: UsageViewModel
    private var popover: NSPopover?

    init(viewModel: UsageViewModel) {
        self.viewModel = viewModel

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let statusBarView = StatusBarView(usageData: viewModel.usageData)
        hostingView = NSHostingView(rootView: statusBarView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.setContentHuggingPriority(.required, for: .horizontal)
        hostingView.setContentCompressionResistancePriority(.required, for: .horizontal)

        guard let button = statusItem.button else {
            return
        }

        button.frame.size.height = NSStatusBar.system.thickness
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: button.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            hostingView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        hostingView.layoutSubtreeIfNeeded()
        let fittedWidth = max(
            StatusBarController.minimumItemWidth,
            ceil(hostingView.fittingSize.width)
        )
        statusItem.length = fittedWidth

        button.action = #selector(statusItemClicked(_:))
        button.target = self
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if let existingPopover = popover, existingPopover.isShown {
            existingPopover.performClose(sender)
            popover = nil
            return
        }

        let popoverContentView = PopoverContentView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: popoverContentView)
        let newPopover = NSPopover()
        newPopover.contentViewController = hostingController
        newPopover.behavior = .applicationDefined
        newPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        DispatchQueue.main.async {
            hostingController.view.window?.makeFirstResponder(hostingController.view)
        }

        popover = newPopover
    }

    func update(usageData: UsageData?) {
        hostingView.rootView = StatusBarView(usageData: usageData)
        hostingView.layoutSubtreeIfNeeded()
        statusItem.length = max(
            StatusBarController.minimumItemWidth,
            ceil(hostingView.fittingSize.width)
        )
    }
}
