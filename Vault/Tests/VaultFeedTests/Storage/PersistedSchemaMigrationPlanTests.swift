import Foundation
import SwiftData
import TestHelpers
import Testing
@testable import VaultFeed

struct PersistedSchemaMigrationPlanTests {
    @Test
    func stages_includesV1ToV2AndV2ToV3() {
        let stages = PersistedSchemaMigrationPlan.stages

        #expect(stages.count == 2)
        guard case let .custom(fromVersion, toVersion, willMigrate, didMigrate) = stages[0] else {
            Issue.record("Expected first stage to be custom")
            return
        }
        #expect(ObjectIdentifier(fromVersion) == ObjectIdentifier(PersistedSchemaV1.self))
        #expect(ObjectIdentifier(toVersion) == ObjectIdentifier(PersistedSchemaV2.self))
        #expect(willMigrate != nil)
        #expect(didMigrate == nil)

        guard case let .custom(fromVersion, toVersion, willMigrate, didMigrate) = stages[1] else {
            Issue.record("Expected second stage to be custom")
            return
        }
        #expect(ObjectIdentifier(fromVersion) == ObjectIdentifier(PersistedSchemaV2.self))
        #expect(ObjectIdentifier(toVersion) == ObjectIdentifier(PersistedSchemaV3.self))
        #expect(willMigrate != nil)
        #expect(didMigrate == nil)
    }

    @Test
    func schemas_includesV1V2AndV3() {
        let schemas = PersistedSchemaMigrationPlan.schemas

        // All versioned schemas must be registered so SwiftData knows
        // how to migrate forward through every step in the chain.
        #expect(schemas.count == 3)
        #expect(ObjectIdentifier(schemas[0]) == ObjectIdentifier(PersistedSchemaV1.self))
        #expect(ObjectIdentifier(schemas[1]) == ObjectIdentifier(PersistedSchemaV2.self))
        #expect(ObjectIdentifier(schemas[2]) == ObjectIdentifier(PersistedSchemaV3.self))
    }

    @Test
    func v1Models_includeAllLegacyModelTypes() {
        let models = PersistedSchemaV1.models

        #expect(models.count == 4)
        #expect(ObjectIdentifier(models[0]) == ObjectIdentifier(PersistedSchemaV1.PersistedVaultItem.self))
        #expect(ObjectIdentifier(models[1]) == ObjectIdentifier(PersistedSchemaV1.PersistedOTPDetails.self))
        #expect(ObjectIdentifier(models[2]) == ObjectIdentifier(PersistedSchemaV1.PersistedNoteDetails.self))
        #expect(ObjectIdentifier(models[3]) == ObjectIdentifier(PersistedSchemaV1.PersistedVaultTag.self))
    }

    @Test
    func v2Models_includeAllLegacyModelTypes() {
        let models = PersistedSchemaV2.models

        #expect(models.count == 4)
        #expect(ObjectIdentifier(models[0]) == ObjectIdentifier(PersistedSchemaV2.PersistedVaultItem.self))
        #expect(ObjectIdentifier(models[1]) == ObjectIdentifier(PersistedSchemaV2.PersistedOTPDetails.self))
        #expect(ObjectIdentifier(models[2]) == ObjectIdentifier(PersistedSchemaV2.PersistedNoteDetails.self))
        #expect(ObjectIdentifier(models[3]) == ObjectIdentifier(PersistedSchemaV2.PersistedVaultTag.self))
    }

    @Test
    func v1PersistedModels_storeAssignedValues() {
        let id = UUID()
        let tagID = UUID()
        let created = Date(timeIntervalSince1970: 100)
        let updated = Date(timeIntervalSince1970: 200)
        let color = PersistedColor(red: 0.1, green: 0.2, blue: 0.3)
        let tag = PersistedSchemaV1.PersistedVaultTag(
            id: tagID,
            title: "tag",
            color: color,
            iconName: "star",
            items: [],
        )
        let noteDetails = PersistedSchemaV1.PersistedNoteDetails(
            title: "note",
            contents: "contents",
            format: "markdown",
        )
        let otpDetails = PersistedSchemaV1.PersistedOTPDetails(
            accountName: "account",
            issuer: "issuer",
            algorithm: "SHA1",
            authType: "TOTP",
            counter: 123,
            digits: 6,
            period: 30,
            secretData: Data([1, 2, 3]),
            secretFormat: "BASE_32",
        )
        let encryptedDetails = PersistedSchemaV1.PersistedEncryptedItemDetails(
            version: "1",
            title: "encrypted",
            data: Data([4]),
            authentication: Data([5]),
            encryptionIV: Data([6]),
            keygenSalt: Data([7]),
            keygenSignature: "TEST",
        )

        let item = PersistedSchemaV1.PersistedVaultItem(
            id: id,
            relativeOrder: 99,
            createdDate: created,
            updatedDate: updated,
            userDescription: "description",
            visibility: "ALWAYS",
            searchableLevel: "FULL",
            searchPassphrase: "search",
            killphrase: "kill",
            lockState: "LOCKED",
            color: color,
            showInQuickType: false,
            previewMode: "HIDDEN",
            tags: [tag],
            noteDetails: noteDetails,
            otpDetails: otpDetails,
            encryptedItemDetails: encryptedDetails,
        )

        #expect(item.id == id)
        #expect(item.relativeOrder == 99)
        #expect(item.createdDate == created)
        #expect(item.updatedDate == updated)
        #expect(item.userDescription == "description")
        #expect(item.visibility == "ALWAYS")
        #expect(item.searchableLevel == "FULL")
        #expect(item.searchPassphrase == "search")
        #expect(item.killphrase == "kill")
        #expect(item.lockState == "LOCKED")
        #expect(item.color?.red == 0.1)
        #expect(item.showInQuickType == false)
        #expect(item.previewMode == "HIDDEN")
        #expect(item.tags.map(\.id) == [tagID])
        #expect(item.noteDetails?.title == "note")
        #expect(item.noteDetails?.contents == "contents")
        #expect(item.noteDetails?.format == "markdown")
        #expect(item.otpDetails?.accountName == "account")
        #expect(item.otpDetails?.issuer == "issuer")
        #expect(item.otpDetails?.algorithm == "SHA1")
        #expect(item.otpDetails?.authType == "TOTP")
        #expect(item.otpDetails?.counter == 123)
        #expect(item.otpDetails?.digits == 6)
        #expect(item.otpDetails?.period == 30)
        #expect(item.otpDetails?.secretData == Data([1, 2, 3]))
        #expect(item.otpDetails?.secretFormat == "BASE_32")
        #expect(item.encryptedItemDetails?.version == "1")
        #expect(item.encryptedItemDetails?.title == "encrypted")
        #expect(item.encryptedItemDetails?.data == Data([4]))
        #expect(item.encryptedItemDetails?.authentication == Data([5]))
        #expect(item.encryptedItemDetails?.encryptionIV == Data([6]))
        #expect(item.encryptedItemDetails?.keygenSalt == Data([7]))
        #expect(item.encryptedItemDetails?.keygenSignature == "TEST")

        var hasher = Hasher()
        tag.hash(into: &hasher)
    }

    @Test
    func v2PersistedModels_storeAssignedValues() {
        let id = UUID()
        let tagID = UUID()
        let created = Date(timeIntervalSince1970: 300)
        let updated = Date(timeIntervalSince1970: 400)
        let color = PersistedColor(red: 0.4, green: 0.5, blue: 0.6)
        let tag = PersistedSchemaV2.PersistedVaultTag(
            id: tagID,
            title: "tag",
            color: color,
            iconName: "tag",
            items: [],
        )
        let noteDetails = PersistedSchemaV2.PersistedNoteDetails(
            title: "note",
            contents: "contents",
            format: "plain",
        )
        let otpDetails = PersistedSchemaV2.PersistedOTPDetails(
            accountName: "account",
            issuer: "issuer",
            algorithm: "SHA256",
            authType: "HOTP",
            counter: 456,
            digits: 8,
            period: 60,
            secretData: Data([8, 9]),
            secretFormat: "BASE_32",
        )
        let encryptedDetails = PersistedSchemaV2.PersistedEncryptedItemDetails(
            version: "2",
            title: "encrypted",
            data: Data([10]),
            authentication: Data([11]),
            encryptionIV: Data([12]),
            keygenSalt: Data([13]),
            keygenSignature: "TEST",
        )

        let item = PersistedSchemaV2.PersistedVaultItem(
            id: id,
            relativeOrder: 100,
            createdDate: created,
            updatedDate: updated,
            userDescription: "description",
            visibility: "ONLY_SEARCH",
            searchableLevel: "ONLY_TITLE",
            searchPassphrase: "search",
            killphraseSalt: Data([14]),
            killphraseDigest: Data([15]),
            lockState: "LOCKED",
            color: color,
            showInQuickType: false,
            previewMode: "TITLE_ONLY",
            tags: [tag],
            noteDetails: noteDetails,
            otpDetails: otpDetails,
            encryptedItemDetails: encryptedDetails,
        )

        #expect(item.id == id)
        #expect(item.relativeOrder == 100)
        #expect(item.createdDate == created)
        #expect(item.updatedDate == updated)
        #expect(item.userDescription == "description")
        #expect(item.visibility == "ONLY_SEARCH")
        #expect(item.searchableLevel == "ONLY_TITLE")
        #expect(item.searchPassphrase == "search")
        #expect(item.killphraseSalt == Data([14]))
        #expect(item.killphraseDigest == Data([15]))
        #expect(item.lockState == "LOCKED")
        #expect(item.color?.green == 0.5)
        #expect(item.showInQuickType == false)
        #expect(item.previewMode == "TITLE_ONLY")
        #expect(item.tags.map(\.id) == [tagID])
        #expect(item.noteDetails?.format == "plain")
        #expect(item.otpDetails?.accountName == "account")
        #expect(item.otpDetails?.algorithm == "SHA256")
        #expect(item.otpDetails?.authType == "HOTP")
        #expect(item.otpDetails?.counter == 456)
        #expect(item.otpDetails?.digits == 8)
        #expect(item.otpDetails?.period == 60)
        #expect(item.otpDetails?.secretData == Data([8, 9]))
        #expect(item.encryptedItemDetails?.version == "2")
        #expect(item.encryptedItemDetails?.title == "encrypted")
        #expect(item.encryptedItemDetails?.keygenSignature == "TEST")

        var hasher = Hasher()
        tag.hash(into: &hasher)
    }

    // NOTE: An end-to-end migration test that seeds an earlier store and
    // then opens it through the latest schema would be the ideal
    // coverage, but it is not feasible in this test target: every
    // `PersistedSchemaVN.PersistedVaultItem` is a `@Model` class
    // generated under the same CoreData entity name (`PersistedVaultItem`),
    // and SwiftData refuses to host more than one representation in the
    // same process. The migrations are instead exercised by:
    //
    //   * `KillphraseRehashServiceTests` (V1 → V2 Phase B — digest writes + clear)
    //   * `PendingKillphraseRehashStoreTests` (V1 → V2 on-disk handoff format)
    //   * `SearchPassphraseRehashServiceTests` (V2 → V3 Phase B)
    //   * `PendingSearchPassphraseRehashStoreTests` (V2 → V3 on-disk handoff format)
    //
    // Real end-to-end migration behaviour is covered by manual upgrade
    // testing in CI against checked-in fixture stores.
}
