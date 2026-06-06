import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
import VaultSettings
@testable import VaultiOS

@MainActor
final class OTPCodeDetailViewSnapshotTests {
    @Test
    func emptyState() {
        let sut = OTPCodeDetailView(
            editingExistingCode: .init(type: .totp(period: 30), data: .init(secret: .empty(), accountName: "")),
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: nil,
                killphrase: nil,
                lockState: .notLocked,
                color: nil,
                showInQuickType: true,
                previewMode: .titleAndFirstLine,
            ),
            editor: OTPCodeDetailEditorMock(),
            previewGenerator: VaultItemPreviewViewGeneratorMock.defaultMock(),
            copyActionHandler: VaultItemCopyActionHandlerMock(),
            openInEditMode: false,
            presentationMode: .none,
        )

        snapshotScenarios(view: sut)
    }

    @Test
    func lockedState() {
        let sut = OTPCodeDetailView(
            editingExistingCode: .init(type: .totp(period: 30), data: .init(secret: .empty(), accountName: "")),
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: nil,
                killphrase: nil,
                lockState: .lockedWithNativeSecurity,
                color: nil,
                showInQuickType: true,
                previewMode: .titleAndFirstLine,
            ),
            editor: OTPCodeDetailEditorMock(),
            previewGenerator: VaultItemPreviewViewGeneratorMock.defaultMock(),
            copyActionHandler: VaultItemCopyActionHandlerMock(),
            openInEditMode: false,
            presentationMode: .none,
        )

        snapshotScenarios(view: sut)
    }

    @Test
    func lockedStateNoAuthentication() {
        let sut = OTPCodeDetailView(
            editingExistingCode: .init(type: .totp(period: 30), data: .init(secret: .empty(), accountName: "")),
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: nil,
                killphrase: nil,
                lockState: .lockedWithNativeSecurity,
                color: nil,
                showInQuickType: true,
                previewMode: .titleAndFirstLine,
            ),
            editor: OTPCodeDetailEditorMock(),
            previewGenerator: VaultItemPreviewViewGeneratorMock.defaultMock(),
            copyActionHandler: VaultItemCopyActionHandlerMock(),
            openInEditMode: false,
            presentationMode: .none,
        )

        snapshotScenarios(view: sut, deviceAuthenticationPolicy: .cannotAuthenticate)
    }

    @Test
    func withUserDescription() {
        let sut = OTPCodeDetailView(
            editingExistingCode: .init(type: .totp(period: 30), data: .init(secret: .empty(), accountName: "")),
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "This is my description",
                tags: [],
                visibility: .onlySearch,
                searchableLevel: .onlyTitle,
                searchPassphrase: nil,
                killphrase: nil,
                lockState: .notLocked,
                color: nil,
                showInQuickType: true,
                previewMode: .titleAndFirstLine,
            ),
            editor: OTPCodeDetailEditorMock(),
            previewGenerator: VaultItemPreviewViewGeneratorMock.defaultMock(),
            copyActionHandler: VaultItemCopyActionHandlerMock(),
            openInEditMode: false,
            presentationMode: .none,
        )

        snapshotScenarios(view: sut)
    }

    @Test
    func editMode_emptyState() {
        let sut = OTPCodeDetailView(
            editingExistingCode: .init(type: .totp(period: 30), data: .init(secret: .empty(), accountName: "")),
            navigationPath: .constant(NavigationPath()),
            dataModel: anyVaultDataModel(),
            storedMetadata: .init(
                id: .new(),
                created: fixedTestDate(),
                updated: fixedTestDate(),
                relativeOrder: .min,
                userDescription: "",
                tags: [],
                visibility: .always,
                searchableLevel: .full,
                searchPassphrase: nil,
                killphrase: nil,
                lockState: .notLocked,
                color: nil,
                showInQuickType: true,
                previewMode: .titleAndFirstLine,
            ),
            editor: OTPCodeDetailEditorMock(),
            previewGenerator: VaultItemPreviewViewGeneratorMock.defaultMock(),
            copyActionHandler: VaultItemCopyActionHandlerMock(),
            openInEditMode: true,
            presentationMode: .none,
        )

        snapshotScenarios(view: sut)
    }
}

// MARK: - Helpers

extension OTPCodeDetailViewSnapshotTests {
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

    private func fixedTestDate() -> Date {
        Date(timeIntervalSince1970: 40000)
    }
}
