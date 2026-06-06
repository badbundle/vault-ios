import Foundation
import FoundationExtensions
import SwiftUI
import TestHelpers
import Testing
import VaultCore
import VaultFeed
@testable import VaultiOS

@MainActor
final class HOTPPreviewViewGeneratorTests {
    @Test
    func init_hasNoSideEffects() {
        let repository = HOTPPreviewViewRepositoryMock()
        let timer = IntervalTimerMock()
        let (_, factory) = makeSUT(repository: repository, timer: timer)

        #expect(factory.makeHOTPViewCallCount == 0)
        #expect(timer.waitArgValues == [])
        #expect(repository.expireAllCallCount == 0)
        #expect(repository.previewViewModelCallCount == 0)
        #expect(repository.obfuscateForPrivacyCallCount == 0)
        #expect(repository.unobfuscateForPrivacyCallCount == 0)
        #expect(repository.incrementerViewModelCallCount == 0)
        #expect(repository.textToCopyForVaultItemCallCount == 0)
    }

    @Test
    func makeOTPView_generatesViews() {
        let repository = HOTPPreviewViewRepositoryMock()
        repository.previewViewModelHandler = { _, _ in
            MainActor.assumeIsolated {
                OTPCodePreviewViewModel(
                    accountName: "any",
                    issuer: "any",
                    color: .black,
                    isLocked: false,
                    fixedCodeState: .visible("123456"),
                )
            }
        }
        repository.incrementerViewModelHandler = { _, _ in
            MainActor.assumeIsolated {
                OTPCodeIncrementerViewModel(
                    id: .new(),
                    codePublisher: .init(hotpGenerator: .init(secret: .random(count: 123))),
                    timer: IntervalTimerMock(),
                    initialCounter: 0,
                    incrementerStore: VaultStoreHOTPIncrementerMock(),
                )
            }
        }
        let (sut, _) = makeSUT(repository: repository)

        let view = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(), behaviour: .normal)

        assertSnapshot(of: view.frame(width: 100, height: 100), as: .image)
    }

    @Test
    func scenePhaseDidChange_backgroundExpiresAll() {
        let repository = HOTPPreviewViewRepositoryMock()
        let (sut, _) = makeSUT(repository: repository)

        sut.scenePhaseDidChange(to: .background)

        #expect(repository.expireAllCallCount == 1)
        #expect(repository.unobfuscateForPrivacyCallCount == 0)
        #expect(repository.obfuscateForPrivacyCallCount == 0)
    }

    @Test
    func scenePhaseDidChange_inactiveObfuscatesAll() {
        let repository = HOTPPreviewViewRepositoryMock()
        let (sut, _) = makeSUT(repository: repository)

        sut.scenePhaseDidChange(to: .inactive)

        #expect(repository.expireAllCallCount == 0)
        #expect(repository.unobfuscateForPrivacyCallCount == 0)
        #expect(repository.obfuscateForPrivacyCallCount == 1)
    }

    @Test
    func scenePhaseDidChange_activeUnobfuscatesAll() {
        let repository = HOTPPreviewViewRepositoryMock()
        let (sut, _) = makeSUT(repository: repository)

        sut.scenePhaseDidChange(to: .active)

        #expect(repository.expireAllCallCount == 0)
        #expect(repository.unobfuscateForPrivacyCallCount == 1)
        #expect(repository.obfuscateForPrivacyCallCount == 0)
    }

    @Test
    func clearViewCache_clearsRepositoryCache() async {
        let repository = HOTPPreviewViewRepositoryMock()
        let (sut, _) = makeSUT(repository: repository)

        await sut.clearViewCache()

        #expect(repository.vaultItemCacheClearAllCallCount == 1)
    }
}

extension HOTPPreviewViewGeneratorTests {
    private typealias SUT = HOTPPreviewViewGenerator<HOTPPreviewViewFactoryMock>

    private func makeSUT(
        repository: HOTPPreviewViewRepositoryMock = HOTPPreviewViewRepositoryMock(),
        timer _: IntervalTimerMock = IntervalTimerMock(),
    ) -> (SUT, HOTPPreviewViewFactoryMock) {
        let factory = HOTPPreviewViewFactoryMock()
        factory.makeHOTPViewHandler = { _, _, _ in AnyView(Color.green) }
        let sut = HOTPPreviewViewGenerator(viewFactory: factory, repository: repository)
        return (sut, factory)
    }

    private func anyHOTPCode() -> HOTPAuthCode {
        let codeData = OTPAuthCodeData(secret: .empty(), accountName: "Test")
        return .init(data: codeData)
    }

    @MainActor
    private func collectCodePreviewViewModels(
        sut: SUT,
        factory: HOTPPreviewViewFactoryMock,
        ids: [Identifier<VaultItem>],
        sourceLocation: SourceLocation = #_sourceLocation,
    ) -> [OTPCodePreviewViewModel] {
        var viewModels = [OTPCodePreviewViewModel]()

        let group = DispatchGroup()
        factory.makeHOTPViewHandler = { viewModel, _, _ in
            viewModels.append(viewModel)
            group.leave()
            return AnyView(Text("Hello, HOTP!"))
        }

        for id in ids {
            group.enter()
            _ = sut.makeVaultPreviewView(item: anyHOTPCode(), metadata: uniqueMetadata(id: id), behaviour: .normal)
        }

        _ = group.wait(timeout: .now() + .seconds(1))

        #expect(
            viewModels.count == ids.count,
            "Invariant failed, expected number of view models to match the number of IDs we requested",
            sourceLocation: sourceLocation,
        )
        return viewModels
    }
}
