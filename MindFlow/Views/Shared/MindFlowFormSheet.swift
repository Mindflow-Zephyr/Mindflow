import SwiftUI
import UIKit

enum MindFlowFormSheetStyle {
    static let accent = Color(hex: "#2B5748")
    static let accentAction = Color(hex: "#2d6a4f")
    static let accentFill = Color(hex: "#d8f3dc")
    static let fieldBorder = Color(hex: "#C8D5CC")
    static let fieldFont = Font.body
    static let fieldUIFont = UIFont.preferredFont(forTextStyle: .body)
    static let fieldHorizontalPadding: CGFloat = 14
    static let fieldVerticalPadding: CGFloat = 12
    static let fieldContentMinHeight: CGFloat = 22
}

func applyMindFlowFormPlaceholder(_ textField: UITextField, text: String) {
    textField.attributedPlaceholder = NSAttributedString(
        string: text,
        attributes: [
            .foregroundColor: UIColor.placeholderText,
            .font: MindFlowFormSheetStyle.fieldUIFont
        ]
    )
}

/// 表单标题输入；`wantsKeyboard == true` 时在已入窗的视图上立刻要第一响应者，与外层面板位移动画并行。
struct MindFlowFormTitleTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var wantsKeyboard: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        applyMindFlowFormPlaceholder(textField, text: placeholder)
        textField.font = MindFlowFormSheetStyle.fieldUIFont
        textField.textColor = UIColor.label
        textField.returnKeyType = .default
        textField.delegate = context.coordinator
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        uiView.font = MindFlowFormSheetStyle.fieldUIFont
        applyMindFlowFormPlaceholder(uiView, text: placeholder)
        if !wantsKeyboard {
            context.coordinator.didApplyInitialFocus = false
            uiView.resignFirstResponder()
            if uiView.text != text { uiView.text = text }
            return
        }
        if uiView.text != text {
            uiView.text = text
        }
        guard uiView.window != nil else { return }
        if !context.coordinator.didApplyInitialFocus {
            if uiView.becomeFirstResponder() {
                context.coordinator.didApplyInitialFocus = true
            }
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: MindFlowFormTitleTextField
        var didApplyInitialFocus = false

        init(_ parent: MindFlowFormTitleTextField) {
            self.parent = parent
        }

        @objc func editingChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}
