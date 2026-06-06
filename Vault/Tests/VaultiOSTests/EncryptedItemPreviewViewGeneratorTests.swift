import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
@testable import VaultiOS

@MainActor
struct EncryptedItemPreviewViewGeneratorTests {
    @Test
    func init_hasNoSideEffects() {
        let factory = EncryptedItemPreviewViewFactoryMock()
        _ = makeSUT(factory: factory)

        #expect(factory.makeEncryptedItemViewCallCount == 0)
    }

    @Test
    func makeVaultPreviewView_generatesViews() throws {
        let factory = EncryptedItemPreviewViewFactoryMock()
        factory.makeEncryptedItemViewHandler = { _, _ in
            AnyView(Color.red.frame(width: 100, height: 100))
        }
        let sut = makeSUT(factory: factory)

        let view = sut.makeVaultPreviewView(item: anyEncryptedItem(), metadata: uniqueMetadata(), behaviour: .normal)

        try #require(factory.makeEncryptedItemViewCallCount == 1)
        assertSnapshot(of: view, as: .image)
    }

    @Test
    func makeVaultPreviewView_propagatesPreviewMode() {
        let factory = EncryptedItemPreviewViewFactoryMock()
        var capturedPreviewMode: NotePreviewMode?
        factory.makeEncryptedItemViewHandler = { viewModel, _ in
            capturedPreviewMode = viewModel.previewMode
            return AnyView(Color.red.frame(width: 100, height: 100))
        }
        let sut = makeSUT(factory: factory)
        var metadata = uniqueMetadata()
        metadata.previewMode = .hidden

        _ = sut.makeVaultPreviewView(item: anyEncryptedItem(), metadata: metadata, behaviour: .normal)

        #expect(capturedPreviewMode == .hidden)
    }
}

// MARK: - Helpers

extension EncryptedItemPreviewViewGeneratorTests {
    private typealias SUT = EncryptedItemPreviewViewGenerator<EncryptedItemPreviewViewFactoryMock>

    private func makeSUT(
        factory: EncryptedItemPreviewViewFactoryMock = EncryptedItemPreviewViewFactoryMock(),
    ) -> SUT {
        EncryptedItemPreviewViewGenerator(viewFactory: factory)
    }
}
