import Foundation
import FoundationExtensions
import TestHelpers
import Testing

@MainActor
final class DefaultsStoredTests {
    let defaults: Defaults

    init() throws {
        defaults = try .nonPersistent()
    }

    @Test(arguments: [0, 1234, 456])
    func init_fallsBackToDefaultIfNoStoredValue(defaultValue: Int) {
        @DefaultsStored(defaults: defaults, defaultsKey: .init("test1"), defaultValue: defaultValue)
        var coolNumber: Int

        #expect(coolNumber == defaultValue)
    }

    @Test(arguments: [4567, 0, 99999])
    func init_fetchesInitialValueStoredInDefaults(initialValue: Int) throws {
        try defaults.set(initialValue, for: .init("test2"))

        @DefaultsStored(defaults: defaults, defaultsKey: .init("test2"), defaultValue: 1234)
        var coolNumber: Int

        #expect(coolNumber == initialValue)
    }

    @Test
    func wrappedValue_setsValueInDefaults() throws {
        let key: Key<Int> = .init("test3")
        let coolNumberInitial = 4567
        try defaults.set(coolNumberInitial, for: key)

        @DefaultsStored(defaults: defaults, defaultsKey: key, defaultValue: 1234)
        var coolNumber: Int

        coolNumber = 9876

        #expect(coolNumber == 9876)

        let defaultsValue = try #require(defaults.get(for: key))
        #expect(defaultsValue == 9876)
    }
}
