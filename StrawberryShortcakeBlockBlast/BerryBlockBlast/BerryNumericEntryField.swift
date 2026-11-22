import SwiftUI
import UIKit

/// Real UIKit text entry, with the Done key attached directly to the active
/// number pad. Unlike a NavigationStack keyboard ToolbarItem, this accessory
/// retains the correct first responder even inside nested SwiftUI sheets.
struct BerryNumericEntryField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let accessibilityName: String
    var isSecret = false
    var maxDigits = 19

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.delegate = context.coordinator
        context.coordinator.field = field
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.font = .monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        field.textColor = UIColor(red: 0.26, green: 0.15, blue: 0.19, alpha: 1)
        field.backgroundColor = .clear
        field.placeholder = placeholder
        field.isSecureTextEntry = isSecret
        field.textContentType = isSecret ? .oneTimeCode : nil
        field.accessibilityLabel = accessibilityName
        field.accessibilityIdentifier = isSecret
            ? "berry.developer.pin.entry"
            : "berry.developer.cheat.amount"

        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        toolbar.barStyle = .default
        toolbar.isTranslucent = false
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                     target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done,
                                   target: context.coordinator,
                                   action: #selector(Coordinator.dismissKeyboard))
        done.tintColor = UIColor(red: 0.91, green: 0.19, blue: 0.40, alpha: 1)
        done.accessibilityIdentifier = "berry.numeric.keyboard.done"
        toolbar.items = [spacer, done]
        field.inputAccessoryView = toolbar
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text {
            field.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BerryNumericEntryField
        weak var field: UITextField?

        init(_ parent: BerryNumericEntryField) {
            self.parent = parent
        }

        @objc func dismissKeyboard() {
            // Dismiss exactly this UITextField, not an unrelated parent sheet.
            // No submit, data write, or action is triggered.
            field?.resignFirstResponder()
        }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString newString: String) -> Bool {
            let old = textField.text ?? ""
            guard let swiftRange = Range(range, in: old) else { return false }
            let proposed = old.replacingCharacters(in: swiftRange, with: newString)
            let digits = String(proposed.filter { $0.isNumber }.prefix(parent.maxDigits))
            textField.text = digits
            parent.text = digits
            return false
        }
    }
}
