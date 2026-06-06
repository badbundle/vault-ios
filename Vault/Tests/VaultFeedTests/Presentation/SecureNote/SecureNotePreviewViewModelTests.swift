import Foundation
import TestHelpers
import Testing
import VaultFeed

struct SecureNotePreviewViewModelTests {
    @Test
    func visibleTitle_isPlaceholderEmptyTitleIfTitleEmpty() {
        let sut = SecureNotePreviewViewModel(
            title: "",
            description: "description",
            color: .default,
            isLocked: false,
            textFormat: .plain,
            previewMode: .titleAndFirstLine,
        )

        #expect(sut.visibleTitle == "Untitled Note")
    }

    @Test
    func visibleTitle_isUserDefinedTitleIfTitleNotEmpty() {
        let sut = SecureNotePreviewViewModel(
            title: "title",
            description: "description",
            color: .default,
            isLocked: false,
            textFormat: .plain,
            previewMode: .titleAndFirstLine,
        )

        #expect(sut.visibleTitle == "title")
    }

    @Test
    func visibleTitle_isPlaceholderWhenPreviewModeIsHidden() {
        let sut = SecureNotePreviewViewModel(
            title: "secret",
            description: "should not show",
            color: .default,
            isLocked: false,
            textFormat: .plain,
            previewMode: .hidden,
        )

        #expect(sut.visibleTitle == "Note")
        #expect(!sut.showsDescription)
    }

    @Test
    func showsDescription_isFalseWhenPreviewModeIsTitleOnly() {
        let sut = SecureNotePreviewViewModel(
            title: "title",
            description: "description",
            color: .default,
            isLocked: false,
            textFormat: .plain,
            previewMode: .titleOnly,
        )

        #expect(sut.visibleTitle == "title")
        #expect(!sut.showsDescription)
    }

    @Test
    func showsDescription_isTrueWhenPreviewModeIsTitleAndFirstLine() {
        let sut = SecureNotePreviewViewModel(
            title: "title",
            description: "description",
            color: .default,
            isLocked: false,
            textFormat: .plain,
            previewMode: .titleAndFirstLine,
        )

        #expect(sut.showsDescription)
    }
}
