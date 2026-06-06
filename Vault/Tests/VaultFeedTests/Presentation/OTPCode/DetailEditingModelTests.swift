import Foundation
import Testing
@testable import VaultFeed

struct DetailEditingModelTests {
    @Test
    func isDirtyInitiallyFalse() {
        let sut = makeSUT(detail: .init(value: "hello"))

        #expect(!sut.isDirty)
    }

    @Test
    func isDirtyResetsOncePersisted() {
        var sut = makeSUT(detail: .init(value: "hello"))

        sut.detail.value = "next"
        #expect(sut.isDirty)
        sut.didPersist()
        #expect(!sut.isDirty)
    }

    @Test
    func isDirtyIsInitiallyDirtyAlwaysMakesDirty() {
        var sut = makeSUT(detail: .init(value: "hello"), isInitiallyDirty: true)

        #expect(sut.isDirty)
        sut.detail.value = "next"
        #expect(sut.isDirty)
        sut.restoreInitialState()
        #expect(sut.isDirty)
        sut.detail.value = "next"
        #expect(sut.isDirty)
    }

    @Test
    func isDirtyIsInitiallyDirtyPersistEnablesNormalDirtyState() {
        var sut = makeSUT(detail: .init(value: "hello"), isInitiallyDirty: true)

        #expect(sut.isDirty)
        sut.detail.value = "next"
        #expect(sut.isDirty)
        sut.didPersist()
        #expect(!sut.isDirty)
        sut.detail.value = "hello"
        #expect(sut.isDirty)
        sut.detail.value = "next"
        #expect(!sut.isDirty)
    }
}

extension DetailEditingModelTests {
    typealias SUT = DetailEditingModel<EditableStateMock>

    private func makeSUT(detail: EditableStateMock, isInitiallyDirty: Bool = false) -> SUT {
        SUT(detail: detail, isInitiallyDirty: isInitiallyDirty)
    }

    struct EditableStateMock: EditableState {
        var value: String
        var isValid: Bool {
            true
        }
    }
}
