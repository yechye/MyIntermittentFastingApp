import Foundation

@MainActor
protocol FastingSessionServiceProtocol {
    func startFast(plan: FastingPlan?, source: FastingSource, date: Date) throws -> FastingSession
    func endFast(session: FastingSession, at endDate: Date) throws
    func discardFast(session: FastingSession) throws
    func restoreActiveSession() throws -> FastingSession?
    func editSession(_ session: FastingSession, startedAt: Date, endedAt: Date?, notes: String?) throws
    func softDelete(session: FastingSession) throws
}
