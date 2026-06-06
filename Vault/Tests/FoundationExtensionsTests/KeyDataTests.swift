import Foundation
import Testing
@testable import FoundationExtensions

struct KeyDataTests {
    @Test(arguments: [0, 1, 21, 31, 33, 100])
    func init_invalidByteLengthThrows(byteLength: Int) {
        #expect(throws: KeyData<32>.LengthError.self) {
            try KeyData<32>(data: Data(repeating: 0x31, count: byteLength))
        }
    }

    @Test
    func init_validByteLengthCreatesKey() throws {
        let sut = try KeyData<32>(data: Data(repeating: 0x31, count: 32))

        #expect(sut.data.count == 32)
    }

    @Test(arguments: [
        Data(repeating: 0x31, count: 32),
        Data.random(count: 32),
        Data.random(count: 32),
        Data.random(count: 32),
    ])
    func equatable_sameKeysEqual(data: Data) throws {
        let sut1 = try KeyData<32>(data: data)
        let sut2 = try KeyData<32>(data: data)

        #expect(sut1 == sut2)
    }

    @Test
    func equatable_differentKeysDifferent() throws {
        let sut1 = try KeyData<32>(data: Data(repeating: 0x31, count: 32))
        let sut2 = try KeyData<32>(data: Data(repeating: 0x32, count: 32))

        #expect(sut1 != sut2)
    }

    @Test
    func random_createsRandomKey() throws {
        var seen = Set<KeyData<32>>()
        for _ in 1 ... 100 {
            let key = KeyData<32>.random()
            defer { seen.insert(key) }
            #expect(seen.contains(key) == false)
        }
    }

    @Test
    func repeating_createsRepeatingBytes() throws {
        let key = KeyData<32>.repeating(byte: 0x32)

        #expect(key.data.map(\.self) == Array(repeating: 0x32, count: 32))
    }

    @Test
    func zero_createsZeroedKey() throws {
        let zero = KeyData<32>.zero()

        #expect(zero.data.map(\.self) == Array(repeating: 0, count: 32))
    }

    struct Coding {
        @Test
        func encodesToString() throws {
            let encoder = JSONEncoder()
            let key = KeyData<8>.repeating(byte: 0x41)
            let encoded = try encoder.encode(key)
            let str = try #require(String(data: encoded, encoding: .utf8))

            #expect(str == #""QUFBQUFBQUE=""#)
        }

        @Test
        func decodesFromString() throws {
            let encoder = JSONEncoder()
            let key = KeyData<8>.repeating(byte: 0x41)
            let encoded = try encoder.encode(key)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(KeyData<8>.self, from: encoded)

            #expect(decoded == key)
        }
    }

    struct ByteLength {
        @Test
        func bytes8() throws {
            #expect(KeyData<8>.random().data.count == 8)
        }

        @Test
        func bytes32() throws {
            #expect(KeyData<32>.random().data.count == 32)
        }
    }
}
