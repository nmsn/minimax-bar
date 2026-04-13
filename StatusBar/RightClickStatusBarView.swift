import AppKit
import SwiftUI

class RightClickStatusBarView: NSView {
    private let hostingView: NSHostingView<StatusBarView>
    var onLeftClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    init(rootView: StatusBarView) {
        hostingView = NSHostingView(rootView: rootView)
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func update(rootView: StatusBarView) {
        hostingView.rootView = rootView
    }

    override func mouseDown(with event: NSEvent) {
        if event.type == .rightMouseDown || (event.type == .leftMouseDown && event.modifierFlags.contains(.control)) {
            onRightClick?()
        } else {
            onLeftClick?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
}
