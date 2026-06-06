import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
@testable import VaultiOS

@MainActor
final class SecureNotePreviewViewSnapshotTests {
    @Test
    func layout_titleOnly() {
        let sut = makeSUT(title: "Title", description: nil)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_titleOnlyLong() {
        let sut = makeSUT(title: "Title that is a little bit long, but's that's OK", description: nil)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_titleAndDescription() {
        let sut = makeSUT(title: "Title", description: "Short description")

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_titleAndDescriptionTruncation() {
        let description = Array(repeating: "Testing description", count: 50).joined(separator: " ")
        let sut = makeSUT(title: "Title", description: description)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_titleAndDescriptionTruncatesTitleFirst() {
        let title = Array(repeating: "Title", count: 50).joined(separator: " ")
        let description = Array(repeating: "Description", count: 50).joined(separator: " ")
        let sut = makeSUT(title: title, description: description)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_emptyDescriptionRendersNothing() {
        let sut = makeSUT(title: "Title", description: "")

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func layout_lockedIcon() {
        let sut = makeSUT(isLocked: true)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func textFormat_plainText() {
        let sut = makeSUT(title: "## Hello", description: "## description", textFormat: .plain)

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func textFormat_markdown() {
        let sut = makeSUT(title: "## Hello", description: "## description", textFormat: .markdown)

        assertSnapshot(of: sut, as: .image)
    }
}

// MARK: - Helpers

extension SecureNotePreviewViewSnapshotTests {
    @MainActor
    private func makeSUT(
        title: String = "Title",
        description: String? = "Short Description",
        isLocked: Bool = false,
        textFormat: TextFormat = .plain,
        previewMode: NotePreviewMode = .titleAndFirstLine,
    ) -> some View {
        let viewModel = SecureNotePreviewViewModel(
            title: title,
            description: description,
            color: .default,
            isLocked: isLocked,
            textFormat: textFormat,
            previewMode: previewMode,
        )
        return SecureNotePreviewView(viewModel: viewModel, behaviour: .normal)
            .frame(width: 250)
    }
}
