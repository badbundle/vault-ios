import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

@MainActor
struct DeviceAuthenticationServiceTests {
    @Test
    func canAuthenticateWithNeither() {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: false,
        )
        let sut = makeSUT(policy: policy)

        #expect(!sut.canAuthenticate)
    }

    @Test
    func canAuthenticateWithBiometrics() {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: true,
        )
        let sut = makeSUT(policy: policy)

        #expect(sut.canAuthenticate)
    }

    @Test
    func canAuthenticateWithPasscode() {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: false,
        )
        let sut = makeSUT(policy: policy)

        #expect(sut.canAuthenticate)
    }

    @Test
    func canAuthenticateWithBoth() {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: true,
        )
        let sut = makeSUT(policy: policy)

        #expect(sut.canAuthenticate)
    }

    @Test
    func authenticateNoneEnabledFails() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: false,
        )
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        #expect(result == .failure(.noAuthenticationSetup))
        #expect(policy.authenticateWithBiometricsCallCount == 0)
        #expect(policy.authenticateWithPasscodeCallCount == 0)
    }

    @Test
    func authenticateBiometricsEnabledSuccess() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: true,
        )
        policy.authenticateWithBiometricsHandler = { reason in
            #expect(reason == "reason")
            return true
        }
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        #expect(result == .success(.authenticated))
        #expect(policy.authenticateWithBiometricsCallCount == 1)
        #expect(policy.authenticateWithPasscodeCallCount == 0)
    }

    @Test
    func authenticateBiometricsEnabledFailure() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: true,
        )
        policy.authenticateWithBiometricsHandler = { reason in
            #expect(reason == "reason")
            return false
        }
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        #expect(result == .failure(.authenticationFailure))
        #expect(policy.authenticateWithBiometricsCallCount == 1)
        #expect(policy.authenticateWithPasscodeCallCount == 0)
    }

    @Test
    func authenticateBiometricsInternalError() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: false,
            canAuthenticateWithBiometrics: true,
        )
        policy.authenticateWithBiometricsHandler = { reason in
            #expect(reason == "reason")
            throw TestError()
        }
        let sut = makeSUT(policy: policy)

        await #expect(throws: (any Error).self) {
            try await sut.authenticate(reason: "reason")
        }
        #expect(policy.authenticateWithBiometricsCallCount == 1)
        #expect(policy.authenticateWithPasscodeCallCount == 0)
    }

    @Test
    func authenticatePasscodeEnabledSuccess() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: false,
        )
        policy.authenticateWithPasscodeHandler = { reason in
            #expect(reason == "reason")
            return true
        }
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        #expect(result == .success(.authenticated))
        #expect(policy.authenticateWithBiometricsCallCount == 0)
        #expect(policy.authenticateWithPasscodeCallCount == 1)
    }

    @Test
    func authenticatePasscodeEnabledFailure() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: false,
        )
        policy.authenticateWithPasscodeHandler = { reason in
            #expect(reason == "reason")
            return false
        }
        let sut = makeSUT(policy: policy)

        let result = try await sut.authenticate(reason: "reason")
        #expect(result == .failure(.authenticationFailure))
        #expect(policy.authenticateWithBiometricsCallCount == 0)
        #expect(policy.authenticateWithPasscodeCallCount == 1)
    }

    @Test
    func authenticatePasscodeInternalError() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: false,
        )
        policy.authenticateWithPasscodeHandler = { reason in
            #expect(reason == "reason")
            throw TestError()
        }
        let sut = makeSUT(policy: policy)

        await #expect(throws: (any Error).self) {
            try await sut.authenticate(reason: "reason")
        }
        #expect(policy.authenticateWithBiometricsCallCount == 0)
        #expect(policy.authenticateWithPasscodeCallCount == 1)
    }

    @Test
    func authenticateBothEnabledAuthenticatesWithBiometrics() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: true,
        )
        policy.authenticateWithBiometricsHandler = { reason in
            #expect(reason == "reason")
            return true
        }
        let sut = makeSUT(policy: policy)

        _ = try await sut.authenticate(reason: "reason")
        #expect(policy.authenticateWithBiometricsCallCount == 1)
        #expect(policy.authenticateWithPasscodeCallCount == 0)
    }

    @Test
    func validateAuthenticationDoesNotThrowIfValid() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: true,
        )
        policy.authenticateWithBiometricsHandler = { reason in
            #expect(reason == "reason")
            return true
        }
        let sut = makeSUT(policy: policy)

        await #expect(throws: Never.self) {
            try await sut.validateAuthentication(reason: "reason")
        }
        #expect(policy.authenticateWithBiometricsCallCount == 1)
        #expect(policy.authenticateWithPasscodeCallCount == 0)
    }

    @Test
    func validateAuthenticationThrowsForNotAuthenticated() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: true,
        )
        policy.authenticateWithBiometricsHandler = { reason in
            #expect(reason == "reason")
            return false
        }
        let sut = makeSUT(policy: policy)

        await #expect(throws: (any Error).self) {
            try await sut.validateAuthentication(reason: "reason")
        }
    }

    @Test
    func validateAuthenticationThrowsForInternalError() async throws {
        let policy = DeviceAuthenticationPolicyMock(
            canAuthenicateWithPasscode: true,
            canAuthenticateWithBiometrics: true,
        )
        policy.authenticateWithBiometricsHandler = { reason in
            #expect(reason == "reason")
            throw TestError()
        }
        let sut = makeSUT(policy: policy)

        await #expect(throws: (any Error).self) {
            try await sut.validateAuthentication(reason: "reason")
        }
    }
}

// MARK: - Helpers

extension DeviceAuthenticationServiceTests {
    private func makeSUT(
        policy: DeviceAuthenticationPolicyMock = DeviceAuthenticationPolicyMock(),
    ) -> DeviceAuthenticationService {
        DeviceAuthenticationService(policy: policy)
    }
}
