import Foundation

public struct VaultDateFormatter {
    private let timezone: TimeZone
    public init(timezone: TimeZone) {
        self.timezone = timezone
    }

    public func formatForFileName(date: Date) -> String {
        formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "-") // colons not supported in filenames
    }

    private var formatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withFullDate,
            .withFullTime,
            .withColonSeparatorInTime,
            .withDashSeparatorInDate,
            .withTimeZone,
            .withFractionalSeconds,
        ]
        formatter.timeZone = timezone
        return formatter
    }
}
