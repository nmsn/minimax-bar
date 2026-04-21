import AppKit
import SwiftUI

@MainActor
class StatusBarController {
    private static let minimumItemWidth: CGFloat = 40

    private var statusItem: NSStatusItem
    private var statusBarView: RightClickStatusBarView
    private let viewModel: UsageViewModel
    private var popover: NSPopover?
    private var clickMonitor: Any?

    init(viewModel: UsageViewModel) {
        self.viewModel = viewModel

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let statusBarContentView = StatusBarView(usageData: viewModel.usageData)
        statusBarView = RightClickStatusBarView(rootView: statusBarContentView)

        guard let button = statusItem.button else {
            return
        }

        button.frame.size.height = NSStatusBar.system.thickness
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(statusBarView)
        NSLayoutConstraint.activate([
            statusBarView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            statusBarView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            statusBarView.topAnchor.constraint(equalTo: button.topAnchor),
            statusBarView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        statusBarView.onLeftClick = { [weak self] in
            self?.statusItemClicked()
        }

        statusBarView.onRightClick = { [weak self] in
            self?.showDisplaySettingsSubmenu()
        }

        statusBarView.layoutSubtreeIfNeeded()
        let fittedWidth = max(
            StatusBarController.minimumItemWidth,
            ceil(statusBarView.fittingSize.width)
        )
        statusItem.length = fittedWidth
    }

    private func setupClickMonitor() {
        removeClickMonitor()
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closePopoverIfNeeded()
            }
        }
    }

    private func removeClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    private func closePopoverIfNeeded() {
        guard let popover = popover, popover.isShown else { return }
        popover.performClose(nil)
        self.popover = nil
        removeClickMonitor()
    }

    private func statusItemClicked() {
        guard let button = statusItem.button else { return }

        if let existingPopover = popover, existingPopover.isShown {
            existingPopover.performClose(nil)
            popover = nil
            removeClickMonitor()
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
        setupClickMonitor()
    }

    private func showDisplaySettingsSubmenu() {
        closePopoverIfNeeded()

        // --- 显示设置子菜单 ---
        let displayMenu = NSMenu()

        let usedItem = NSMenuItem(title: I18nService.shared.translate("menu.showUsed"), action: #selector(setDisplayModeUsed), keyEquivalent: "")
        usedItem.target = self
        usedItem.state = ConfigService.shared.displayMode == .used ? .on : .off
        displayMenu.addItem(usedItem)

        let remainingItem = NSMenuItem(title: I18nService.shared.translate("menu.showRemaining"), action: #selector(setDisplayModeRemaining), keyEquivalent: "")
        remainingItem.target = self
        remainingItem.state = ConfigService.shared.displayMode == .remaining ? .on : .off
        displayMenu.addItem(remainingItem)

        let displaySettingsItem = NSMenuItem(title: I18nService.shared.translate("menu.displaySettings"), action: nil, keyEquivalent: "")
        displaySettingsItem.submenu = displayMenu

        // --- 语言子菜单 ---
        let languageMenu = NSMenu()
        let isEnglish = I18nService.shared.currentLocale == "en"

        let englishItem = NSMenuItem(title: I18nService.shared.translate("menu.lang.en"), action: #selector(setLanguageEnglish), keyEquivalent: "")
        englishItem.target = self
        englishItem.state = isEnglish ? .on : .off
        languageMenu.addItem(englishItem)

        let chineseItem = NSMenuItem(title: I18nService.shared.translate("menu.lang.zh"), action: #selector(setLanguageChinese), keyEquivalent: "")
        chineseItem.target = self
        chineseItem.state = !isEnglish ? .on : .off
        languageMenu.addItem(chineseItem)

        let languageItem = NSMenuItem(title: I18nService.shared.translate("menu.language"), action: nil, keyEquivalent: "")
        languageItem.submenu = languageMenu

        // --- 根菜单 ---
        let rootMenu = NSMenu()
        rootMenu.addItem(displaySettingsItem)
        rootMenu.addItem(languageItem)
        rootMenu.addItem(NSMenuItem.separator())

        let checkUpdateItem = NSMenuItem(title: I18nService.shared.translate("menu.checkUpdate"), action: #selector(checkUpdateAction), keyEquivalent: "")
        checkUpdateItem.target = self
        rootMenu.addItem(checkUpdateItem)

        rootMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: I18nService.shared.translate("menu.quit"), action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        rootMenu.addItem(quitItem)

        statusItem.menu = rootMenu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func setDisplayModeUsed() {
        ConfigService.shared.displayMode = .used
        updateStatusBarView()
    }

    @objc private func setDisplayModeRemaining() {
        ConfigService.shared.displayMode = .remaining
        updateStatusBarView()
    }

    @objc private func setLanguageEnglish() {
        I18nService.shared.setLocale("en")
        updateStatusBarView()
    }

    @objc private func setLanguageChinese() {
        I18nService.shared.setLocale("zh-Hans")
        updateStatusBarView()
    }

    private func updateStatusBarView() {
        statusBarView.update(rootView: StatusBarView(
            usageData: viewModel.usageData,
            displayMode: ConfigService.shared.displayMode
        ))
        statusBarView.layoutSubtreeIfNeeded()
    }

    private func showContextMenu() {
        closePopoverIfNeeded()

        let menu = NSMenu()

        let checkUpdateItem = NSMenuItem(title: I18nService.shared.translate("menu.checkUpdate"), action: #selector(checkUpdateAction), keyEquivalent: "")
        checkUpdateItem.target = self
        menu.addItem(checkUpdateItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: I18nService.shared.translate("menu.quit"), action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func checkUpdateAction() {
        UpdateService.shared.checkForUpdates()
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }

    func update(usageData: UsageData?) {
        statusBarView.update(rootView: StatusBarView(
            usageData: usageData,
            displayMode: ConfigService.shared.displayMode
        ))
        statusBarView.layoutSubtreeIfNeeded()
        statusItem.length = max(
            StatusBarController.minimumItemWidth,
            ceil(statusBarView.fittingSize.width)
        )
    }
}
