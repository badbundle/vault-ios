import Foundation
import TestHelpers
import Testing
@testable import VaultFeed

struct VaultDateFormatterTests {
    @Test
    func formatForFileName_usesDashesInTime() {
        let sut = VaultDateFormatter(timezone: .gmt)

        let date = Date(timeIntervalSince1970: 1_724_486_168)
        let name = sut.formatForFileName(date: date)

        #expect(name == "2024-08-24T07-56-08.000Z")
    }

    @Test
    func formatForFileName_repectsTimezone() throws {
        func string(timezone: TimeZone) -> String {
            let sut = VaultDateFormatter(timezone: timezone)

            let date = Date(timeIntervalSince1970: 1_724_486_168)
            return sut.formatForFileName(date: date)
        }

        #expect(string(timezone: .gmt) == "2024-08-24T07-56-08.000Z")
        let zone1 = try #require(TimeZone(identifier: "America/Mazatlan"))
        #expect(string(timezone: zone1) == "2024-08-24T00-56-08.000-07-00")
        let zone2 = try #require(TimeZone(identifier: "America/Toronto"))
        #expect(string(timezone: zone2) == "2024-08-24T03-56-08.000-04-00")
        let zone3 = try #require(TimeZone(identifier: "Europe/Warsaw"))
        #expect(string(timezone: zone3) == "2024-08-24T09-56-08.000+02-00")
    }
}
