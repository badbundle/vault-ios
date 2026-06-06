import Foundation
import TestHelpers
import Testing
import VaultKeygen
@testable import VaultFeed

struct DerivedEncryptionKeyTests {
    @Test
    func newVaultKeyWithRandomIV_usesSameKeyEachTime() throws {
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)

        var seenKeys = Set<KeyData<32>>()
        for _ in 0 ..< 10 {
            let newKey = try key.newVaultKeyWithRandomIV()
            seenKeys.insert(newKey.key)
        }

        #expect(seenKeys.count == 1)
    }

    @Test
    func newVaultKeyWithRandomIV_usesRandomIVEachTime() throws {
        let key = DerivedEncryptionKey(key: .random(), salt: .random(count: 32), keyDervier: .testing)

        var seenIVs = Set<KeyData<32>>()
        for _ in 0 ..< 10 {
            let newKey = try key.newVaultKeyWithRandomIV()
            seenIVs.insert(newKey.iv)
        }

        #expect(seenIVs.count == 10)
    }
}
