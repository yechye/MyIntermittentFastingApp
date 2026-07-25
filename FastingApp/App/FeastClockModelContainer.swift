import SwiftData

enum FeastClockModelContainer {
    static var schema: Schema {
        Schema([
            FastingPlan.self,
            FastingSession.self,
            WeeklySchedule.self,
            CheatDay.self,
            UserSettings.self
        ])
    }

    static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Self.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
