import CryptoEngine
import Foundation
import FoundationExtensions
import TestHelpers
import Testing
import VaultKeygen
@testable import VaultBackup

struct VaultEncryptorTests {
    @Test
    func encrypt_emptyDataGivesEmptyEncryption() throws {
        let sut = makeSUT(key: anyVaultKey())
        let encodedVault = IntermediateEncodedVault(data: Data())

        let result = try sut.encrypt(encodedVault: encodedVault)

        #expect(result.data == Data())
    }

    /// Reference test case: https://gchq.github.io/CyberChef/#recipe=AES_Encrypt(%7B'option':'Hex','string':'3131313131313131313131313131313131313131313131313131313131313131'%7D,%7B'option':'Hex','string':'3232323232323232323232323232323232323232323232323232323232323232'%7D,'GCM','Hex','Hex',%7B'option':'Hex','string':''%7D)&input=NDE0MTQxNDE0MTQxNDE
    @Test
    func encrypt_expectedDataReturnedUsingAESGCM() throws {
        let knownKey = VaultKey(
            key: .repeating(byte: 0x31),
            iv: .repeating(byte: 0x32),
        )
        let sut = makeSUT(key: knownKey)
        let plainData = Data(hex: "0x41414141414141")
        let encodedVault = IntermediateEncodedVault(data: plainData)

        let result = try sut.encrypt(encodedVault: encodedVault)

        #expect(result.data == Data(hex: "0x4126987aceb598"))
        #expect(result.authentication == Data(hex: "0x4343890cb716dfb9915f8f7c050829ca"))
    }

    @Test
    func encrypt_placesKeygenSaltIntoPayloadUnchanged() throws {
        let plainData = Data(hex: "0x41414141414141")
        let encodedVault = IntermediateEncodedVault(data: plainData)
        let keygenSalt = Data.random(count: 30)
        let sut = makeSUT(key: anyVaultKey(), keygenSalt: keygenSalt)

        let result = try sut.encrypt(encodedVault: encodedVault)

        #expect(result.keygenSalt == keygenSalt)
    }

    @Test
    func encrypt_placesKeygenSignatureIntoPayloadUnchanged() throws {
        let plainData = Data(hex: "0x41414141414141")
        let encodedVault = IntermediateEncodedVault(data: plainData)
        let sut = makeSUT(key: anyVaultKey(), keygenSignature: "my-signature")

        let result = try sut.encrypt(encodedVault: encodedVault)

        #expect(result.keygenSignature == "my-signature")
    }
}

// MARK: - Helpers

extension VaultEncryptorTests {
    private func makeSUT(
        key: VaultKey,
        keygenSalt: Data = Data(),
        keygenSignature: String = "my-signature",
    ) -> VaultEncryptor {
        VaultEncryptor(key: key, keygenSalt: keygenSalt, keygenSignature: keygenSignature)
    }

    private func anyVaultKey() -> VaultKey {
        VaultKey(key: .repeating(byte: 0x41), iv: .repeating(byte: 0x42))
    }
}
