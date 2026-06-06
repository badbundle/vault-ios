import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

struct BackupPasswordDecoderTests {
    @Test
    func decode_throwsErrorIfVersionIncompatible() {
        let sut = makeSUT()

        let str = """
        {
          "KEY" : "aGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGg=",
          "KEY_DERIVER" : "vault.keygen.testing",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "0.0.0"
        }
        """
        let data = Data(str.utf8)

        #expect(throws: (any Error).self) {
            try sut.decode(data: data)
        }
        #expect(throws: (any Error).self) {
            try sut.decode(qrCode: str)
        }
    }

    @Test
    func decode_throwsErrorIfKeyByteLengthIncorrect() {
        let sut = makeSUT()

        let str = """
        {
          "KEY" : "aGhoaGhoaGhoaA==",
          "KEY_DERIVER" : "vault.keygen.testing",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """
        let data = Data(str.utf8)

        #expect(throws: (any Error).self) {
            try sut.decode(data: data)
        }
        #expect(throws: (any Error).self) {
            try sut.decode(qrCode: str)
        }
    }

    @Test
    func decode_decodesCorrectly() throws {
        let sut = makeSUT()

        let str = """
        {
          "KEY" : "aGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGg=",
          "KEY_DERIVER" : "vault.keygen.testing",
          "SALT" : "aWlpaWlpaWlpaWlpaWlpaWlpaWk=",
          "VERSION" : "1.0.0"
        }
        """
        let data = Data(str.utf8)
        let resultData = try sut.decode(data: data)
        let resultQR = try sut.decode(qrCode: str)

        #expect(resultData.key == .repeating(byte: 0x68))
        #expect(resultData.salt == Data(repeating: 0x69, count: 20))
        #expect(resultQR.key == .repeating(byte: 0x68))
        #expect(resultQR.salt == Data(repeating: 0x69, count: 20))
    }
}

// MARK: - Helpers

extension BackupPasswordDecoderTests {
    private func makeSUT() -> BackupPasswordDecoder {
        BackupPasswordDecoder()
    }
}
