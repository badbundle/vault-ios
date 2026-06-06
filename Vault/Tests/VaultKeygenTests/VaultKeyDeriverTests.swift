import CryptoEngine
import Foundation
import FoundationExtensions
import TestHelpers
import Testing
@testable import VaultKeygen

/// We don't actually want to run key derivation, as it may be very slow.
/// To check the algorithm's correctness, we verify the identifier.
///
/// Each respective version of each algorithm should never change, so it's always backwards compatible.
struct VaultKeyDeriverTests {
    @Test
    func Backup_Fast_v1() {
        let fast = VaultKeyDeriver.Backup.Fast.v1

        #expect(fast.signature == .backupFastV1)
        #expect(fast.signature.userVisibleDescription == "Vault Backup (Fast, v1)")
        #expect(fast.uniqueAlgorithmIdentifier == """
        COMBINATION<\
        PBKDF2<keyLength=32;iterations=2000;variant=sha384>|\
        HKDF<keyLength=32;variant=sha3_sha512>|\
        SCRYPT<keyLength=32;costFactor=64;blockSizeFactor=4;parallelizationFactor=1>\
        >
        """)
    }

    @Test
    func Backup_Secure_v1() {
        let secure = VaultKeyDeriver.Backup.Secure.v1

        #expect(secure.signature == .backupSecureV1)
        #expect(secure.signature.userVisibleDescription == "Vault Backup (Secure, v1)")
        #expect(secure.uniqueAlgorithmIdentifier == """
        COMBINATION<\
        PBKDF2<keyLength=32;iterations=5452351;variant=sha384>|\
        HKDF<keyLength=32;variant=sha3_sha512>|\
        SCRYPT<keyLength=32;costFactor=262144;blockSizeFactor=8;parallelizationFactor=1>\
        >
        """)
    }

    @Test
    func Item_Fast_v1() {
        let fast = VaultKeyDeriver.Item.Fast.v1

        #expect(fast.signature == .itemFastV1)
        #expect(fast.signature.userVisibleDescription == "Vault Item (Fast, v1)")
        #expect(fast.uniqueAlgorithmIdentifier == """
        COMBINATION<\
        SCRYPT<keyLength=32;costFactor=64;blockSizeFactor=4;parallelizationFactor=1>|\
        PBKDF2<keyLength=32;iterations=1001;variant=sha384>\
        >
        """)
    }

    @Test
    func Item_Secure_v1() {
        let secure = VaultKeyDeriver.Item.Secure.v1

        #expect(secure.signature == .itemSecureV1)
        #expect(secure.signature.userVisibleDescription == "Vault Item (Secure, v1)")
        #expect(secure.uniqueAlgorithmIdentifier == """
        COMBINATION<\
        SCRYPT<keyLength=32;costFactor=256;blockSizeFactor=4;parallelizationFactor=1>|\
        PBKDF2<keyLength=32;iterations=372002;variant=sha384>\
        >
        """)
    }

    @Test(arguments: VaultKeyDeriver.Signature.allCases)
    func lookupSignature_looksUpCorrect(signature: VaultKeyDeriver.Signature) {
        let result = VaultKeyDeriver.lookup(signature: signature)
        #expect(result.signature == signature)
    }

    @Test
    func createEncryptionKey_usesRandomSalt() throws {
        let sut = VaultKeyDeriver.testing

        var seenKeys = Set<KeyData<32>>()
        var seenSalt = Set<Data>()
        var seenKeyDeriver = Set<VaultKeyDeriver.Signature>()
        for _ in 0 ..< 100 {
            let key = try sut.createEncryptionKey(password: "password")
            seenKeys.insert(key.key)
            seenSalt.insert(key.salt)
            seenKeyDeriver.insert(key.keyDervier)
        }

        #expect(seenKeys.count == 100)
        #expect(seenSalt.count == 100)
        #expect(seenKeyDeriver.count == 1)
        #expect(seenKeyDeriver.first == .testing)
    }

    @Test
    func recreateEncryptionKey_usesTheSameSalt() throws {
        let salt = Data(hex: "aabbccddeeff")
        let sut = VaultKeyDeriver.testing

        var seenKeys = Set<KeyData<32>>()
        var seenSalt = Set<Data>()
        var seenKeyDeriver = Set<VaultKeyDeriver.Signature>()

        for _ in 0 ..< 100 {
            let key = try sut.recreateEncryptionKey(password: "password", salt: salt)
            seenKeys.insert(key.key)
            seenSalt.insert(key.salt)
            seenKeyDeriver.insert(key.keyDervier)
        }

        #expect(seenKeys.count == 1)
        #expect(seenSalt.count == 1)
        #expect(seenKeyDeriver.count == 1)
        #expect(
            seenKeys.first?.data.toHexString() ==
                "b8ab51d4c385654810dbcc8e860426143a7b61a4273805ba9596b1f9c00530c6",
        )
        #expect(seenSalt.first?.toHexString() == "aabbccddeeff")
        #expect(seenKeyDeriver.first == .testing)
    }
}
