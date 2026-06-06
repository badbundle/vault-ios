import Foundation

/// An error occurred at the presentation layer, we should inform the user with a message.
public struct PresentationError: Error, Equatable, Hashable {
    public var userTitle: String
    public var userDescription: String?
    public var debugDescription: String

    public init(userTitle: String, userDescription: String? = nil, debugDescription: String) {
        self.userTitle = userTitle
        self.userDescription = userDescription
        self.debugDescription = debugDescription
    }

    public init(localizedError: any LocalizedError) {
        userTitle = localizedError.errorDescription ?? "Error"
        userDescription = localizedError.failureReason
        debugDescription = localizedError.localizedDescription
    }
}

extension PresentationError: LocalizedError {
    public var errorDescription: String? {
        userTitle
    }

    public var failureReason: String? {
        userDescription
    }
}
