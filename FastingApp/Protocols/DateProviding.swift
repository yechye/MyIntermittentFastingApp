import Foundation

nonisolated protocol DateProviding {
    var now: Date { get }
}

nonisolated struct SystemDateProvider: DateProviding {
    var now: Date { Date() }
}
