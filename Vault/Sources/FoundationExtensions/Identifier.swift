import Foundation

/// A strongly-typed unique identifier for an item.
///
/// The backing identifier is `UUID`.
public struct Identifier<T>: Identifiable, Sendable {
    public var id: UUID

    public init(id: UUID = UUID()) {
        self.id = id
    }
}

extension Identifier: RawRepresentable {
    public typealias RawValue = UUID

    public init?(rawValue: UUID) {
        self.init(id: rawValue)
    }

    public var rawValue: UUID {
        id
    }
}

extension Identifier: Equatable {}

extension Identifier: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Helpers

extension Identifier {
    public static func new() -> Self {
        .init(id: UUID())
    }

    public static func uuidString(_ string: String) -> Self? {
        let id = UUID(uuidString: string)
        return id.map { .init(id: $0) }
    }
}

extension Identifier {
    /// Convert the type of this identifier into another type.
    public func map<U>() -> Identifier<U> {
        .init(id: id)
    }
}
