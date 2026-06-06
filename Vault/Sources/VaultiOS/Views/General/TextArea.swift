import Foundation
import SwiftUI
import UIKit

struct TextArea: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.isScrollEnabled = true
        textView.isEditable = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context _: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    /// Coordinator to handle UITextViewDelegate events
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                let text = textView.text
                self.text = text ?? ""
            }
        }
    }
}
