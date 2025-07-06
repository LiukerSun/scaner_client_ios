import SwiftUI
import UIKit

struct SelectAllCurrencyTextField: UIViewRepresentable {
    @Binding var value: Double
    var placeholder: String
    var currencyCode: String = "CNY"

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = .decimalPad
        textField.borderStyle = .roundedRect
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)

        // 为键盘添加“完成”按钮，方便关闭键盘
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "完成", style: .done, target: textField, action: #selector(UIResponder.resignFirstResponder))
        toolbar.items = [space, done]
        textField.inputAccessoryView = toolbar

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        let formatted = context.coordinator.formatter.string(for: value) ?? ""
        if !uiView.isEditing {
            uiView.text = formatted
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: SelectAllCurrencyTextField
        let formatter: NumberFormatter

        init(_ parent: SelectAllCurrencyTextField) {
            self.parent = parent
            formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = parent.currencyCode
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
        }

        @objc func editingChanged(_ sender: UITextField) {
            guard let text = sender.text else { return }
            let cleaned = text.replacingOccurrences(of: formatter.currencySymbol, with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let doubleValue = Double(cleaned) {
                parent.value = doubleValue
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            // 延迟一个事件循环以保证 selectAll 生效，但仅当仍为第一响应者
            DispatchQueue.main.async { [weak textField] in
                if let tf = textField, tf.isFirstResponder {
                    tf.selectAll(nil)
                }
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            textField.text = formatter.string(for: parent.value)
        }
    }
} 