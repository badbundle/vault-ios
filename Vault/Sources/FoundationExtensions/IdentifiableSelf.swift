public protocol IdentifiableSelf: Identifiable where Self: Hashable, ID: Hashable {
    var id: ID { get }
}

extension IdentifiableSelf {
    public var id: Self {
        self
    }
}
