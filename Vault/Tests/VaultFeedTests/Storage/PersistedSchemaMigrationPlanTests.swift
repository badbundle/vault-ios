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
