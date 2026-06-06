import Foundation
import SwiftUI
import TestHelpers
import Testing
import VaultFeed
@testable import VaultiOS

@MainActor
struct BackupViewSnapshotTests {
    @Test
    func backupCreate_passwordNotFetched() {
        let sut = makeBackupCreateSUT(dataModel: anyVaultDataModel())
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupCreate_passwordError() async {
        let backupPasswordStore = BackupPasswordStoreMock()
        backupPasswordStore.fetchPasswordHandler = { throw TestError() }
        let dataModel = anyVaultDataModel(backupPasswordStore: backupPasswordStore)
        await dataModel.loadBackupPassword()
        await dataModel.reloadData()

        let sut = makeBackupCreateSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupCreate_passwordNotCreated() async {
        let backupPasswordStore = BackupPasswordStoreMock()
        backupPasswordStore.fetchPasswordHandler = { nil }
        let dataModel = anyVaultDataModel(backupPasswordStore: backupPasswordStore)
        await dataModel.loadBackupPassword()
        await dataModel.reloadData()

        let sut = makeBackupCreateSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupCreate_passwordFetched() async {
        let backupPasswordStore = BackupPasswordStoreMock()
        backupPasswordStore.fetchPasswordHandler = { .init(
            key: .random(),
            salt: .random(count: 32),
            keyDervier: .testing,
        ) }
        let dataModel = anyVaultDataModel(backupPasswordStore: backupPasswordStore)
        await dataModel.loadBackupPassword()
        await dataModel.reloadData()

        let sut = makeBackupCreateSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupRestore_noItems() async {
        let vaultStore = VaultStoreStub()
        vaultStore.hasAnyItemsHandler = { false }
        let dataModel = anyVaultDataModel(vaultStore: vaultStore)
        await dataModel.reloadData()

        let sut = makeBackupRestoreSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }

    @Test
    func backupRestore_hasItems() async {
        let vaultStore = VaultStoreStub()
        vaultStore.hasAnyItemsHandler = { true }
        let dataModel = anyVaultDataModel(vaultStore: vaultStore)
        await dataModel.reloadData()

        let sut = makeBackupRestoreSUT(dataModel: dataModel)
            .framedForTest()

        assertSnapshot(of: sut, as: .image)
    }
}

extension BackupViewSnapshotTests {
    private func makeBackupCreateSUT(
        dataModel: VaultDataModel,
    ) -> some View {
        let injector = anyVaultInjector()
        return BackupCreateView()
            .environment(dataModel)
            .environment(DeviceAuthenticationService(policy: .alwaysAllow))
            .environment(injector)
    }

    private func makeBackupRestoreSUT(
        dataModel: VaultDataModel,
    ) -> some View {
        let injector = anyVaultInjector()
        return BackupRestoreView()
            .environment(dataModel)
            .environment(injector)
    }
}
