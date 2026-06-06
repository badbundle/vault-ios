//
//  Defaults.swift
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

public protocol DefaultsKey: Sendable {}

/// Represents a `Key` with an associated generic value type conforming to the
/// `Codable` protocol.
///
///     static let someKey = Key<ValueType>("someKey")
public struct Key<ValueType: Codable>: DefaultsKey {
    fileprivate let storageName: String
    public init(_ storageName: String) {
        self.storageName = storageName
    }
}

/// Provides strongly typed values associated with the lifetime
/// of an application. Apropriate for user preferences.
/// - Warning
/// These should not be used to store sensitive information that could compromise
/// the application or the user's security and privacy.
@MainActor
public final class Defaults {
    private var userDefaults: UserDefaults
    private let defaultsDidChangeSubject = PassthroughSubject<Void, Never>()

    /// An instance of `Defaults` with the specified `UserDefaults` instance.
    ///
    /// - Parameter userDefaults: The UserDefaults.
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    /// Deletes the value associated with the specified key, if any.
    ///
    /// - Parameter key: The key.
    public func clear(_ key: Key<some Any>) {
        userDefaults.set(nil, forKey: key.storageName)
        userDefaults.synchronize()
        defaultsDidChangeSubject.send(())
    }

    /// Checks if there is a value associated with the specified key.
    ///
    /// - Parameter key: The key to look for.
    /// - Returns: A boolean value indicating if a value exists for the specified key.
    public func has(_ key: Key<some Any>) -> Bool {
        userDefaults.value(forKey: key.storageName) != nil
    }

    /// Returns the value associated with the specified key.
    ///
    /// - Parameter key: The key.
    /// - Returns: A `ValueType` or `nil` if the key was not found or is corrupted.
    public func get<ValueType>(for key: Key<ValueType>) -> ValueType? {
        if isSwiftCodableType(ValueType.self) || isFoundationCodableType(ValueType.self) {
            return userDefaults.value(forKey: key.storageName) as? ValueType
        }

        guard let data = userDefaults.data(forKey: key.storageName) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(ValueType.self, from: data)
    }

    /// Sets a value associated with the specified key.
    ///
    /// - Parameters:
    ///   - some: The value to set.
    ///   - key: The associated `Key<ValueType>`.
    /// - Throws: if an encoding error occurs when encoding the value.
    public func set<ValueType>(_ value: ValueType, for key: Key<ValueType>) throws {
        if isSwiftCodableType(ValueType.self) || isFoundationCodableType(ValueType.self) {
            userDefaults.set(value, forKey: key.storageName)
        } else {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(value)
            userDefaults.set(encoded, forKey: key.storageName)
            userDefaults.synchronize()
        }
        defaultsDidChangeSubject.send(())
    }

    /// Publishes when the defaults were changed.
    public func defaultsDidChangePublisher() -> AnyPublisher<Void, Never> {
        defaultsDidChangeSubject.eraseToAnyPublisher()
    }

    /// Removes given bundle's persistent domain
    ///
    /// - Parameter type: Bundle.
    public func removeAll(bundle: Bundle = Bundle.main) {
        guard let name = bundle.bundleIdentifier else { return }
        userDefaults.removePersistentDomain(forName: name)
        defaultsDidChangeSubject.send(())
    }

    /// Checks if the specified type is a Codable from the Swift standard library.
    ///
    /// - Parameter type: The type.
    /// - Returns: A boolean value.
    private func isSwiftCodableType(_ type: (some Any).Type) -> Bool {
        switch type {
        case is String.Type, is Bool.Type, is Int.Type, is Float.Type, is Double.Type:
            true
        default:
            false
        }
    }

    /// Checks if the specified type is a Codable, from the Swift's core libraries
    /// Foundation framework.
    ///
    /// - Parameter type: The type.
    /// - Returns: A boolean value.
    private func isFoundationCodableType(_ type: (some Any).Type) -> Bool {
        switch type {
        case is Date.Type:
            true
        default:
            false
        }
    }
}

// MARK: - RawRepresentable

extension Defaults {
    /// Returns the value associated with the specified key.
    ///
    /// - Parameter key: The key.
    /// - Returns: A `ValueType` or nil if the key was not found.
    public func get<ValueType: RawRepresentable>(for key: Key<ValueType>) -> ValueType?
        where ValueType.RawValue: Codable
    {
        let convertedKey = Key<ValueType.RawValue>(key.storageName)
        if let raw = get(for: convertedKey) {
            return ValueType(rawValue: raw)
        }
        return nil
    }

    /// Sets a value associated with the specified key.
    ///
    /// - Parameters:
    ///   - some: The value to set.
    ///   - key: The associated `Key<ValueType>`.
    public func set<ValueType: RawRepresentable>(_ value: ValueType, for key: Key<ValueType>) throws
        where ValueType.RawValue: Codable
    {
        let convertedKey = Key<ValueType.RawValue>(key.storageName)
        try set(value.rawValue, for: convertedKey)
    }
}
