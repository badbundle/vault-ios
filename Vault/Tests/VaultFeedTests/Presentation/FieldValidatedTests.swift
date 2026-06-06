import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

struct FieldValidatedTests {
    @Test
    func wrappedValue_setsBasedOnValue() {
        @FieldValidated(validationLogic: .alwaysValid) var sut = "Hello"
        #expect(sut == "Hello")

        sut = "Hello, world"
        #expect(sut == "Hello, world")
    }

    @Test
    func projectedValue_getsCorrectValidationState() {
        let validOnFoo = FieldValidationLogic<String>(validate: { $0 == "foo" ? .valid : .invalid })
        @FieldValidated(validationLogic: validOnFoo) var sut = "Hello"
        #expect($sut.isValid == false)

        sut = "foo"
        #expect($sut.isValid)

        sut = "bar"
        #expect($sut.isValid == false)
    }

    @Test
    func isEqual_ifContentIsEqual() {
        @FieldValidated(validationLogic: .alwaysValid) var sut1 = "Hello"
        @FieldValidated(validationLogic: .alwaysInvalid) var sut2 = "Hello"

        #expect(sut1 == sut2)

        @FieldValidated(validationLogic: .alwaysValid) var sut3 = "Hello"
        @FieldValidated(validationLogic: .alwaysInvalid) var sut4 = "World"

        #expect(sut3 != sut4)
    }

    @Test
    func alwaysValid_isValid() {
        @FieldValidated(validationLogic: .alwaysValid) var sut = "Hello"

        #expect($sut.isValid)
        #expect($sut.isError == false)
    }

    @Test
    func alwaysInvalid_isInvalid() {
        @FieldValidated(validationLogic: .alwaysInvalid) var sut = "Hello"

        #expect($sut.isValid == false)
        #expect($sut.isError == false)
    }

    @Test
    func alwaysError_isError() {
        @FieldValidated(validationLogic: .alwaysError) var sut = "Hello"

        #expect($sut.isValid == false)
        #expect($sut.isError)
    }

    @Test
    func stringRequiringContent_invalidForEmpty() {
        @FieldValidated(validationLogic: .stringRequiringContent) var sut = ""
        #expect($sut.isValid == false)
    }

    @Test
    func stringRequiringContent_invalidForBlank() {
        @FieldValidated(validationLogic: .stringRequiringContent) var sut = "  \n\n\t"
        #expect($sut.isValid == false)
    }

    @Test
    func stringRequiringContent_validForSomeContent() {
        @FieldValidated(validationLogic: .stringRequiringContent) var sut = "  Hello  "
        #expect($sut.isValid)
        sut = "nice"
        #expect($sut.isValid)
    }
}
