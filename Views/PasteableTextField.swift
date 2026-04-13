import SwiftUI
import AppKit

struct PasteableTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.delegate = context.coordinator
        textField.bezelStyle = .roundedBezel
        textField.focusRingType = .default
        textField.font = .systemFont(ofSize: 13)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.isSelectable = true
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PasteableTextField

        init(_ parent: PasteableTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            return false
        }
    }
}
