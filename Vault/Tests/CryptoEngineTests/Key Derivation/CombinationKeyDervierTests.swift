import Foundation
import FoundationExtensions
import TestHelpers
import Testing
@testable import CryptoEngine

struct CombinationKeyDeriverTests {
    @Test
    func key_throwsErrorIfNoKeyDerivers() {
        let sut = CombinationKeyDeriver<32>(derivers: [])

        #expect(throws: (any Error).self) {
            try sut.key(password: anyData(), salt: anyData())
        }
    }

    @Test
    func key_returnsResultOfSingleKeyDeriver() throws {
        let expectedData = KeyData<32>.random()
        let deriver = KeyDeriverMock<KeyData<32>>()
        deriver.keyHandler = { _, _ in
            expectedData
        }
        let sut = CombinationKeyDeriver(derivers: [deriver])

        let result = try sut.key(password: anyData(), salt: anyData())
        #expect(result == expectedData)
        #expect(deriver.keyCallCount == 1)
    }

    @Test
    func key_returnsResultOfLastKeyDervier() throws {
        let deriver1 = mockKeyDeriver(returning: .repeating(byte: 0x00))
        let deriver2 = mockKeyDeriver(returning: .repeating(byte: 0x01))
        let deriver3 = mockKeyDeriver(returning: .repeating(byte: 0x02))
        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3])

        let result = try sut.key(password: anyData(), salt: anyData())
        #expect(result == .repeating(byte: 0x02))
        #expect(deriver1.keyCallCount == 1)
        #expect(deriver2.keyCallCount == 1)
        #expect(deriver3.keyCallCount == 1)
    }

    @Test
    func key_usesKeyFromPreviousDeriverInNextDeriver() throws {
        let deriver1 = mockKeyDeriver(returning: .repeating(byte: 0x00))
        let deriver2 = mockKeyDeriver(returning: .repeating(byte: 0x01))
        let deriver3 = mockKeyDeriver(returning: .repeating(byte: 0x02))
        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3])

        let initialPassword = Data(hex: "deadbeef")
        _ = try sut.key(password: initialPassword, salt: anyData())
        #expect(deriver1.keyArgValues.first?.0 == initialPassword)
        #expect(deriver2.keyArgValues.first?.0 == Data(repeating: 0x00, count: 32))
        #expect(deriver3.keyArgValues.first?.0 == Data(repeating: 0x01, count: 32))
    }

    @Test
    func key_usesSameSaltForAllDerivers() throws {
        let deriver1 = mockKeyDeriver(returning: .repeating(byte: 0x00))
        let deriver2 = mockKeyDeriver(returning: .repeating(byte: 0x01))
        let deriver3 = mockKeyDeriver(returning: .repeating(byte: 0x02))
        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3])

        let salt = Data(hex: "123456789aaaa")
        _ = try sut.key(password: anyData(), salt: salt)
        #expect(deriver1.keyArgValues.first?.1 == salt)
        #expect(deriver2.keyArgValues.first?.1 == salt)
        #expect(deriver3.keyArgValues.first?.1 == salt)
    }

    @Test
    func key_checksCancellationBetweenAlgs() async throws {
        // We expect 3 confirmations, from the first 3 algos, the 4th should not run.
        await confirmation(expectedCount: 3) { confirmation in
            let keyTask = SharedMutex<Task<KeyData<32>, any Error>?>(nil)
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let d1 = SignalKeyDeriver(signal: { confirmation.confirm() })
                let d2 = SignalKeyDeriver(signal: { confirmation.confirm() })
                let d3 = SignalKeyDeriver(signal: {
                    // Cancel the task during d3.
                    keyTask.modify { $0?.cancel() }
                    confirmation.confirm()
                })
                let d4 = SignalKeyDeriver(signal: { confirmation.confirm() })
                let sut = CombinationKeyDeriver(derivers: [d1, d2, d3, d4])

                keyTask.modify {
                    $0 = Task {
                        // Once the keygen task is done or cancelled, resume the continuation
                        defer { continuation.resume() }
                        return try sut.key(password: Data(), salt: Data())
                    }
                }
            }

            await #expect(throws: CancellationError.self, performing: {
                try await keyTask.value?.value
            })
        }
    }

    @Test
    func uniqueAlgorithmIdentifier_matchesParametersOfPassedAlgorithms() {
        let deriver1 = StubKeyDeriver(uniqueAlgorithmIdentifier: "alg1")
        let deriver2 = StubKeyDeriver(uniqueAlgorithmIdentifier: "alg2")
        let deriver3 = StubKeyDeriver(uniqueAlgorithmIdentifier: "alg3")

        let sut = CombinationKeyDeriver(derivers: [deriver1, deriver2, deriver3])

        #expect(sut.uniqueAlgorithmIdentifier == "COMBINATION<alg1|alg2|alg3>")
    }
}

// MARK: - Helpers

extension CombinationKeyDeriverTests {
    private func mockKeyDeriver(returning: KeyData<32>) -> KeyDeriverMock<KeyData<32>> {
        let deriver1 = KeyDeriverMock<KeyData<32>>()
        deriver1.keyHandler = { _, _ in
            returning
        }
        return deriver1
    }

    private struct StubKeyDeriver: KeyDeriver {
        var stubKey: KeyData<32>
        var uniqueAlgorithmIdentifier: String

        init(
            stubKey: KeyData<32> = .zero(),
            uniqueAlgorithmIdentifier: String = "stub",
        ) {
            self.stubKey = stubKey
            self.uniqueAlgorithmIdentifier = uniqueAlgorithmIdentifier
        }

        func key(password _: Data, salt _: Data) throws -> KeyData<32> {
            stubKey
        }
    }

    /// Calls a signal closure before returning data.
    private final class SignalKeyDeriver: KeyDeriver {
        let signal: @Sendable () -> Void

        init(signal: @Sendable @escaping () -> Void) {
            self.signal = signal
        }

        var uniqueAlgorithmIdentifier: String { "signal" }
        func key(password _: Data, salt _: Data) throws -> KeyData<32> {
            signal()
            return .zero()
        }
    }
}
