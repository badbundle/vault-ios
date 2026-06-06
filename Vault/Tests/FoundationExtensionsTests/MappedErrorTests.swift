import Foundation
import FoundationExtensions
import Testing

@Test
func withMappedError_noErrorReturnsValue() throws {
    var callCount = 0
    let result = try withMappedError {
        100
    } error: {
        callCount += 1
        return $0
    }

    #expect(result == 100)
    #expect(callCount == 0)
}

@Test
func withMappedError_throwCallsErrorMap() {
    var callCount = 0
    #expect(throws: TestError.self, performing: {
        try withMappedError {
            throw TestError()
        } error: {
            callCount += 1
            return $0
        }
    })
    #expect(callCount == 1)
}

@Test
func withCatchingError_returnsNilIfNoError() {
    let result = withCatchingError {
        100
    }

    #expect(result == nil)
}

@Test
func withCatchingError_returnsErrorIfError() {
    let result = withCatchingError {
        throw TestError()
    }

    #expect(result is TestError)
}

struct TestError: Error, Equatable {}
