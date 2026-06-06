import Foundation
import SwiftUI
import UIKit

final class SelectableTextView: UITextView {
    /// change the cursor to have zero size
    override func caretRect(for _: UITextPosition) -> CGRect {
        .zero
    }

    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var intrinsicContentSize: CGSize {
        frame.height > 0 ? contentSize : super.intrinsicContentSize
    }
}

extension SelectableTextView: UITextViewDelegate {}
