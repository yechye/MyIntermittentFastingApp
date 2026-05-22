import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingPlan.name) private var plans: [FastingPlan]
    @Query(sort: \FastingSession.startedAt) private var sessions: [FastingSession]

    private var activeSessions: [FastingSession] {
        sessions.filter { $0.status == .active && $0.deletedAt == nil }
    }

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 24) {
                    activeFastCard
                    planList
                }
                .padding()
                .navigationTitle("Fasting")
            }
            .tabItem {
                Label("Timer", systemImage: "timer")
            }

            NavigationStack {
                Text("Insights")
                    .font(.title2)
                    .navigationTitle("Insights")
            }
            .tabItem {
                Label("Insights", systemImage: "chart.xyaxis.line")
            }

            NavigationStack {
                Text("Settings")
                    .font(.title2)
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }

    private var activeFastCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Fast")
                .font(.headline)
            if let session = activeSessions.first {
                Text(session.planName ?? "Custom")
                    .font(.largeTitle.weight(.semibold))
                Text("Started \(session.startedAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(.secondary)
            } else {
                Text("No active fast")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
                Button {
                    startFast()
                } label: {
                    Label("Start 16:8", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planList: some View {
        List(plans) { plan in
            HStack {
                Text(plan.name)
                Spacer()
                Text("\(plan.fastingMinutes / 60):\(plan.eatingMinutes / 60)")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
    }

    private func startFast() {
        let notificationService = NotificationService()
        let service = FastingSessionService(
            context: modelContext,
            notificationService: notificationService
        )
        _ = try? service.startFast(plan: plans.first(where: { $0.name == "16:8" }), source: .manual, date: Date())
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FastingPlan.self, FastingSession.self, WeeklySchedule.self, CheatDay.self, UserSettings.self], inMemory: true)
}
