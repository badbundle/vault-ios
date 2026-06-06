import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultSettings
@testable import VaultFeed
@testable import VaultiOS

@MainActor
final class BackupKeyChangeViewSnapshotTests {
    @Test
    func layout() {
        let viewModel = BackupKeyChangeViewModel(
            dataModel: anyVaultDataModel(),
            authenticationService: DeviceAuthenticationService(policy: DeviceAuthenticationPolicyAlwaysAllow()),
            deriverFactory: VaultKeyDeriverFactoryImpl(),
        )
        let sut = BackupKeyChangeView(viewModel: viewModel)

        snapshotScenarios(view: sut)
    }

    @Test
    func layoutAuthenticated() {
        let viewModel = BackupKeyChangeViewModel(
            dataModel: anyVaultDataModel(),
            authenticationService: DeviceAuthenticationService(policy: DeviceAuthenticationPolicyAlwaysAllow()),
            deriverFactory: VaultKeyDeriverFactoryImpl(),
        )
        viewModel.permissionState = .allowed
        let sut = BackupKeyChangeView(viewModel: viewModel)

        snapshotScenarios(view: sut)
    }
}

// MARK: - Helpers

extension BackupKeyChangeViewSnapshotTests {
    private func snapshotScenarios(
        view: some View,
        deviceAuthenticationPolicy: some DeviceAuthenticationPolicy = DeviceAuthenticationPolicyAlwaysAllow(),
        testName: String = #function,
    ) {
        let colorSchemes: [ColorScheme] = [.light, .dark]
        let dynamicTypeSizes: [DynamicTypeSize] = [.xSmall, .medium, .xxLarge]
        for colorScheme in colorSchemes {
            for dynamicTypeSize in dynamicTypeSizes {
                let snapshottingView = view
                    .dynamicTypeSize(dynamicTypeSize)
                    .preferredColorScheme(colorScheme)
                    .framedForTest()
                    .environment(makePasteboard())
                    .environment(DeviceAuthenticationService(policy: deviceAuthenticationPolicy))
                let named = "\(colorScheme)_\(dynamicTypeSize)"

                assertSnapshot(
                    of: snapshottingView,
                    as: .image,
                    named: named,
                    testName: testName,
                )
            }
        }
    }

    private func makePasteboard() -> Pasteboard {
        Pasteboard(SystemPasteboardMock(), localSettings: LocalSettings(defaults: .init(userDefaults: .standard)))
    }
}
