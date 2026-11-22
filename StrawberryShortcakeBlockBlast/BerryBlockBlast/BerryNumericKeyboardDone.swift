import SwiftUI
import UIKit

/// A real UIKit numeric input with a native inputAccessoryView. SwiftUI's
/// .toolbar(placement: .keyboard) may render but ignore taps in nested
/// NavigationStack sheets on some physical iPhones. This accessory is attached
/// DIRECTLY to its UITextField and dismisses that field's first responder.
/// Dismissing NEVER triggers Unlock, a cheat grant, or a saved-game write.
struct BerryNumericKeyboardDone: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var secure = false
    var maximumDigits = 19
    var accessibilityLabel: String? = nil
    var accessibilityIdentifier: String? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.delegate = context.coordinator
        context.coordinator.field = field
        field.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)),
                        for: .editingChanged)
        field.placeholder = placeholder
        field.keyboardType = .numberPad
        field.keyboardAppearance = .light
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.isSecureTextEntry = secure
        field.textContentType = secure ? .oneTimeCode : nil
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 22, weight: .semibold)
        field.textColor = UIColor(red: 0.28, green: 0.17, blue: 0.20, alpha: 1)
        field.accessibilityLabel = accessibilityLabel ?? placeholder
        field.accessibilityIdentifier = accessibilityIdentifier

        // Use an actual UIKit accessory button instead of a SwiftUI toolbar.
        // The button has a full-size hit target above the system number pad.
        let accessory = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 58))
        accessory.autoresizingMask = [.flexibleWidth]
        accessory.backgroundColor = UIColor(red: 1, green: 0.91, blue: 0.93, alpha: 1)
        let done = UIButton(type: .system)
        done.translatesAutoresizingMaskIntoConstraints = false
        done.setTitle("Done", for: .normal)
        done.setTitleColor(.white, for: .normal)
        done.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        done.backgroundColor = UIColor(red: 0.88, green: 0.16, blue: 0.33, alpha: 1)
        done.layer.cornerRadius = 13
        done.accessibilityLabel = "Done"
        done.accessibilityIdentifier = "berry.numeric.keyboard.done"
        done.addTarget(context.coordinator, action: #selector(Coordinator.dismissKeyboard),
                       for: .touchUpInside)
        accessory.addSubview(done)
        NSLayoutConstraint.activate([
            done.trailingAnchor.constraint(equalTo: accessory.trailingAnchor, constant: -15),
            done.centerYAnchor.constraint(equalTo: accessory.centerYAnchor),
            done.widthAnchor.constraint(greaterThanOrEqualToConstant: 94),
            done.heightAnchor.constraint(equalToConstant: 44)
        ])
        field.inputAccessoryView = accessory
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.owner = self
        let sanitized = String(text.filter(\.isNumber).prefix(maximumDigits))
        if field.text != sanitized { field.text = sanitized }
        field.isSecureTextEntry = secure
        field.accessibilityLabel = accessibilityLabel ?? placeholder
        field.accessibilityIdentifier = accessibilityIdentifier
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var owner: BerryNumericKeyboardDone
        weak var field: UITextField?

        init(_ owner: BerryNumericKeyboardDone) { self.owner = owner }

        @objc func dismissKeyboard() {
            // Definitive real-device focus change. No SwiftUI focus-bridge or
            // navigation toolbar ambiguity, no accidental cheat submission.
            field?.resignFirstResponder()
        }

        @objc func textDidChange(_ sender: UITextField) {
            let digits = String((sender.text ?? "").filter(\.isNumber)
                                .prefix(owner.maximumDigits))
            if sender.text != digits { sender.text = digits }
            if owner.text != digits { owner.text = digits }
        }

        func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            guard let current = field.text,
                  let swiftRange = Range(range, in: current) else { return false }
            let next = current.replacingCharacters(in: swiftRange, with: string)
            return next.count <= owner.maximumDigits &&
                   next.allSatisfy(\.isNumber)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            dismissKeyboard()
            return true
        }
    }
}
