import XCTest
@testable import FastingApp

final class FastingHistoryExporterTests: XCTestCase {
    func test_csvEscapesCommasAndQuotes() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let session = FastingSession(
            plan: nil,
            status: .completed,
            startedAt: start,
            endedAt: start.addingTimeInterval(60 * 60),
            targetFastingMinutes: 960,
            source: .manual,
            notes: "felt calm, \"steady\"",
            createdAt: start,
            updatedAt: start
        )

        let csv = FastingHistoryExporter().csv(for: [session])

        XCTAssertTrue(csv.contains("Date,Status,Plan,Start Time,End Time,Duration Minutes,Source,Notes"))
        XCTAssertTrue(csv.contains("\"felt calm, \"\"steady\"\"\""))
    }
}
