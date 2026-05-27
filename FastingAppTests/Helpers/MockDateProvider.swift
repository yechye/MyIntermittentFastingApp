import Foundation
@testable import FastingApp

final class MockDateProvider: DateProviding {
    var now: Date

    init(_ date: Date) {
        self.now = date
    }
}
