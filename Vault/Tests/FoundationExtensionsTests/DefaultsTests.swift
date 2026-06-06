//
//  DefaultsTests.swift
//
//  Copyright (c) 2017 - 2018 Nuno Manuel Dias
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Combine
import Foundation
import TestHelpers
import Testing
@testable import FoundationExtensions

@MainActor
final class DefaultTests {
    let defaults: Defaults

    init() throws {
        defaults = try .nonPersistent()
    }

    @Test(arguments: [0, 123, 456])
    func integer(value: Int) throws {
        try defaults.set(value, for: .integerKey)

        let hasKey = defaults.has(.integerKey)
        try #require(hasKey)

        let savedValue = defaults.get(for: .integerKey)
        #expect(savedValue == value)
    }

    @Test(arguments: [123.1, 0.0, 100.345])
    func float(value: Float) throws {
        try defaults.set(value, for: .floatKey)

        let hasKey = defaults.has(.floatKey)
        try #require(hasKey)

        let savedValue = defaults.get(for: .floatKey)
        #expect(savedValue == value)
    }

    @Test(arguments: [123.1, 0.0, 100.345])
    func double(value: Double) throws {
        try defaults.set(value, for: .doubleKey)

        let hasKey = defaults.has(.doubleKey)
        try #require(hasKey)

        let savedValue = defaults.get(for: .doubleKey)
        #expect(savedValue == value)
    }

    @Test(arguments: ["", "a string", "longer string with data"])
    func string(value: String) throws {
        try defaults.set(value, for: .stringKey)

        let hasKey = defaults.has(.stringKey)
        try #require(hasKey)

        let savedValue = defaults.get(for: .stringKey)
        #expect(savedValue == value)
    }

    @Test(arguments: [true, false])
    func bool(value: Bool) throws {
        try defaults.set(value, for: .boolKey)

        let hasKey = defaults.has(.boolKey)
        try #require(hasKey)

        let savedValue = defaults.get(for: .boolKey)
        #expect(savedValue == value)
    }

    @Test(arguments: [Date(), Date(timeIntervalSince1970: 100)])
    func date(value: Date) throws {
        try defaults.set(value, for: .dateKey)

        let hasKey = defaults.has(.dateKey)
        try #require(hasKey)

        let savedValue = defaults.get(for: .dateKey)
        #expect(savedValue == value)
    }

    @Test(arguments: [EnumMock.one, .two, .three])
    private func customEnum(value: EnumMock) throws {
        try defaults.set(value, for: .enumKey)

        let hasKey = defaults.has(.enumKey)
        try #require(hasKey)

        let savedValue = defaults.get(for: .enumKey)
        #expect(savedValue == value)
    }

    @Test(arguments: [OptionSetMock.option1, .option2, .option3])
    private func optionSet(value: OptionSetMock) throws {
        try defaults.set(value, for: .optionSetKey)

        let hasKey = defaults.has(.optionSetKey)
        try #require(hasKey)

        let savedValue = defaults.get(for: .optionSetKey)
        #expect(savedValue == value)
    }

    @Test(arguments: [[1, 2, 3, 4], [], [1, 1, 1]])
    func set(values: [Int]) throws {
        try defaults.set(values, for: .arrayOfIntegersKey)

        let hasKey = defaults.has(.arrayOfIntegersKey)
        try #require(hasKey)

        let savedValues = defaults.get(for: .arrayOfIntegersKey)
        #expect(savedValues != nil)
        savedValues?.forEach { value in
            #expect(savedValues?.contains(value) ?? false)
        }
    }

    @Test
    func clear() throws {
        let values = [1, 2, 3, 4]

        try defaults.set(values, for: .arrayOfIntegersKey)
        defaults.clear(.arrayOfIntegersKey)

        let hasKey = defaults.has(.arrayOfIntegersKey)
        #expect(!hasKey)

        let savedValues = defaults.get(for: .arrayOfIntegersKey)
        #expect(savedValues == nil)
    }

    @Test
    func setObject() throws {
        let child = PersonMock(name: "Anne Greenwell", age: 30, children: [])
        let person = PersonMock(name: "Bonnie Greenwell", age: 80, children: [child])

        try defaults.set(person, for: .personMockKey)

        let hasKey = defaults.has(.personMockKey)
        #expect(hasKey)

        let savedPerson = defaults.get(for: .personMockKey)
        #expect(savedPerson?.name == "Bonnie Greenwell")
        #expect(savedPerson?.age == 80)
        #expect(savedPerson?.children.first?.name == "Anne Greenwell")
        #expect(savedPerson?.children.first?.age == 30)
    }

    @Test
    func clear_didChangeDefaults() async throws {
        try await defaults
            .defaultsDidChangePublisher()
            .expect(valueCount: 3) {
                defaults.clear(Key<String>("test1"))
                defaults.clear(Key<String>("test2"))
                defaults.clear(Key<String>("test3"))
            }
    }

    @Test
    func removeAll_didChangeDefaults() async throws {
        try await defaults
            .defaultsDidChangePublisher()
            .expect(valueCount: 3) {
                defaults.removeAll()
                defaults.removeAll()
                defaults.removeAll()
            }
    }

    @Test
    func set_didChangeDefaults() async throws {
        try await defaults
            .defaultsDidChangePublisher()
            .expect(valueCount: 4) {
                try defaults.set("test1", for: Key<String>("test1"))
                try defaults.set("test1", for: Key<String>("test1"))
                try defaults.set("test1", for: Key<String>("test1"))
                try defaults.set("test1", for: Key<String>("test1"))
            }
    }
}

// MARK: - Helpers

extension DefaultsKey {
    fileprivate static var integerKey: Key<Int> {
        .init("integerKey")
    }

    fileprivate static var floatKey: Key<Float> {
        .init("floatKey")
    }

    fileprivate static var doubleKey: Key<Double> {
        .init("doubleKey")
    }

    fileprivate static var stringKey: Key<String> {
        .init("stringKey")
    }

    fileprivate static var boolKey: Key<Bool> {
        .init("boolKey")
    }

    fileprivate static var dateKey: Key<Date> {
        .init("dateKey")
    }

    fileprivate static var enumKey: Key<EnumMock> {
        .init("enumKey")
    }

    fileprivate static var optionSetKey: Key<OptionSetMock> {
        .init("optionSetKey")
    }

    fileprivate static var arrayOfIntegersKey: Key<[Int]> {
        .init("arrayOfIntegersKey")
    }

    fileprivate static var personMockKey: Key<PersonMock> {
        .init("personMockKey")
    }
}

struct PersonMock: Codable {
    let name: String
    let age: Int
    let children: [PersonMock]
}

private enum EnumMock: Int, Codable {
    case one, two, three
}

private struct OptionSetMock: OptionSet, Codable {
    let rawValue: Int
    static let option1 = OptionSetMock(rawValue: 1)
    static let option2 = OptionSetMock(rawValue: 2)
    static let option3 = OptionSetMock(rawValue: 3)
}
