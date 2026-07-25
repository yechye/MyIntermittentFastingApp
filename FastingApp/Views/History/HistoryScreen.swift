import Charts
import SwiftData
import SwiftUI

struct HistoryScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingSession.startedAt, order: .reverse) private var sessions: [FastingSession]
    @Query(sort: \UserSettings.createdAt) private var settingsRows: [UserSettings]
    @State private var selectedRange: FastingHistoryRange = .thirtyDays
    @State private var selectedSession: FastingSession?
    @State private var editingSession: FastingSession?
    @State private var isAddingMissedFast = false

    private let calculator = FastingHistoryCalculator()

    private var dateRange: FastingHistoryDateRange {
        calculator.dateRange(for: selectedRange, endingAt: Date())
    }

    private var rangeSessions: [FastingSession] {
        calculator.sessions(in: dateRange, from: sessions)
    }

    private var allHistorySessions: [FastingSession] {
        calculator.historySessions(from: sessions)
    }

    private var summary: FastingHistorySummary {
        calculator.summary(for: sessions, in: dateRange)
    }

    private var buckets: [FastingHistoryChartBucket] {
        calculator.chartBuckets(for: sessions, in: dateRange)
    }

    private var export: FastingHistoryExport {
        FastingHistoryExport(csvText: FastingHistoryExporter().csv(for: allHistorySessions, timeFormat: settingsRows.first?.timeFormat ?? .system))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                rangePicker
                chartCard
                totalsGrid
                rangeList
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color.timerBackground)
        .navigationTitle(AppStrings.localized("history_title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isAddingMissedFast = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(AppStrings.localized("history_add_fast_title"))
                .accessibilityIdentifier("history.addMissedFastButton")

                NavigationLink {
                    AllFastsScreen(sessions: sessions)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel(AppStrings.localized("history_all_fasts_title"))

                ShareLink(item: export, preview: SharePreview(AppStrings.localized("history_export_title"))) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(AppStrings.localized("history_export_title"))
            }
        }
        .sheet(item: $selectedSession) { session in
            FastDetailScreen(
                session: session,
                phases: calculator.phases(for: session),
                onEdit: editAfterDetail,
                onDelete: deleteAfterDetail
            )
        }
        .sheet(item: $editingSession) { session in
            EditFastSheet(session: session, sessions: sessions)
        }
        .sheet(isPresented: $isAddingMissedFast) {
            AddMissedFastSheet(sessions: sessions)
        }
    }

    private var rangePicker: some View {
        Picker(AppStrings.localized("history_range_picker_label"), selection: $selectedRange) {
            ForEach(FastingHistoryRange.allCases) { range in
                Text(range.localizedTitle).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppStrings.localized("history_chart_title"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.lumePrimary)

            if buckets.allSatisfy({ $0.fastingMinutes == 0 }) {
                HistoryEmptyState(text: AppStrings.localized("history_empty_chart"))
                    .frame(height: 190)
            } else {
                Chart(buckets) { bucket in
                    BarMark(
                        x: .value(AppStrings.localized("history_date_axis"), bucket.date, unit: .day),
                        y: .value(AppStrings.localized("history_hours_axis"), Double(bucket.fastingMinutes) / 60.0)
                    )
                    .foregroundStyle(Color.lumeSage.gradient)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 190)
            }
        }
        .padding(16)
        .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lumeStroke.opacity(0.7), lineWidth: 0.5)
        }
    }

    private var totalsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            HistoryMetricCard(title: AppStrings.localized("history_fasting_total"), value: durationText(summary.fastingMinutes), icon: "timer")
            HistoryMetricCard(title: AppStrings.localized("history_eating_total"), value: durationText(summary.eatingMinutes), icon: "fork.knife")
            HistoryMetricCard(title: AppStrings.localized("history_fast_count"), value: "\(summary.fastCount)", icon: "number")
            HistoryMetricCard(title: AppStrings.localized("history_selected_range"), value: selectedRange.localizedTitle, icon: "calendar")
        }
    }

    private var rangeList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AppStrings.localized("history_recent_fasts_title"))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.lumePrimary)
                Spacer()
                NavigationLink(AppStrings.localized("history_view_all_button")) {
                    AllFastsScreen(sessions: sessions)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.lumeSage)
            }

            if rangeSessions.isEmpty {
                HistoryEmptyState(text: AppStrings.localized("history_empty_list"))
                    .padding(.vertical, 22)
            } else {
                VStack(spacing: 0) {
                    ForEach(rangeSessions) { session in
                        Button {
                            selectedSession = session
                        } label: {
                            FastRow(session: session, showsDetailIndicator: true)
                        }
                        .accessibilityIdentifier("history.fastRow.\(session.id.uuidString)")
                        .buttonStyle(.plain)

                        if session.id != rangeSessions.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.lumeStroke.opacity(0.7), lineWidth: 0.5)
                }
            }
        }
    }

    private func durationText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 {
            return AppStrings.scheduleDurationMinutes(remainder)
        }
        if remainder == 0 {
            return AppStrings.scheduleDurationHours(hours)
        }
        return AppStrings.scheduleDurationHoursMinutes(hours: hours, minutes: remainder)
    }

    private func delete(_ session: FastingSession) {
        do {
            try FastingSessionService(
                context: modelContext,
                notificationService: NotificationService()
            )
            .softDelete(session: session)
            AppLogger.info("Deleted history fast \(session.id)", category: "History")
        } catch {
            AppLogger.error("Failed to delete history fast \(session.id): \(error)", category: "History")
        }
    }

    private func editAfterDetail(_ session: FastingSession) {
        selectedSession = nil
        DispatchQueue.main.async {
            editingSession = session
        }
    }

    private func deleteAfterDetail(_ session: FastingSession) {
        delete(session)
        selectedSession = nil
    }
}

private struct EditFastSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let session: FastingSession
    let sessions: [FastingSession]

    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var errorMessage: String?

    init(session: FastingSession, sessions: [FastingSession]) {
        self.session = session
        self.sessions = sessions
        _startedAt = State(initialValue: session.startedAt)
        _endedAt = State(initialValue: session.endedAt ?? session.startedAt.addingTimeInterval(60 * 60))
    }

    private var validationMessage: String? {
        if startedAt >= endedAt {
            return AppStrings.localized("history_add_fast_invalid_range")
        }
        if endedAt > Date() {
            return AppStrings.localized("history_add_fast_future_end")
        }
        if overlappingSession != nil {
            return AppStrings.localized("history_add_fast_overlap")
        }
        return nil
    }

    private var overlappingSession: FastingSession? {
        sessions.first { candidate in
            guard candidate.id != session.id else { return false }
            guard candidate.deletedAt == nil, candidate.status != .discarded else { return false }
            let existingEnd = candidate.endedAt ?? Date()
            return candidate.startedAt < endedAt && existingEnd > startedAt
        }
    }

    private var canSave: Bool {
        validationMessage == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        AppStrings.localized("history_add_fast_start_label"),
                        selection: $startedAt,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    DatePicker(
                        AppStrings.localized("history_add_fast_end_label"),
                        selection: $endedAt,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } footer: {
                    Text(AppStrings.localized("history_edit_fast_help"))
                }

                Section(AppStrings.localized("history_add_fast_preview_title")) {
                    HStack {
                        Text(AppStrings.localized("history_add_fast_duration_label"))
                        Spacer()
                        Text(durationText)
                            .foregroundStyle(Color.lumePrimary)
                            .monospacedDigit()
                    }
                    if let overlappingSession {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppStrings.localized("history_add_fast_conflict_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.timerDestructive)
                            FastRow(session: overlappingSession)
                                .padding(.vertical, 4)
                        }
                    }
                }

                if let message = validationMessage ?? errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(Color.timerDestructive)
                    }
                }
            }
            .navigationTitle(AppStrings.localized("history_edit_fast_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.save) {
                        save()
                    }
                    .accessibilityIdentifier("history.saveEditedFastButton")
                    .disabled(!canSave)
                }
            }
        }
    }

    private var durationText: String {
        let minutes = max(0, Int(endedAt.timeIntervalSince(startedAt) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 {
            return AppStrings.scheduleDurationMinutes(remainder)
        }
        if remainder == 0 {
            return AppStrings.scheduleDurationHours(hours)
        }
        return AppStrings.scheduleDurationHoursMinutes(hours: hours, minutes: remainder)
    }

    private func save() {
        errorMessage = nil
        do {
            try FastingSessionService(
                context: modelContext,
                notificationService: NotificationService()
            )
            .editSession(session, startedAt: startedAt, endedAt: endedAt, notes: session.notes)
            AppLogger.info("Edited history fast \(session.id)", category: "History")
            dismiss()
        } catch FastingError.overlappingSession {
            errorMessage = AppStrings.localized("history_add_fast_overlap")
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("Failed to edit history fast \(session.id): \(error)", category: "History")
        }
    }
}

private struct AddMissedFastSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let sessions: [FastingSession]

    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var notes = ""
    @State private var errorMessage: String?

    init(sessions: [FastingSession]) {
        self.sessions = sessions
        let now = Date()
        let end = Calendar.current.date(byAdding: .hour, value: -1, to: now) ?? now
        let start = Calendar.current.date(byAdding: .hour, value: -16, to: end) ?? end
        _startedAt = State(initialValue: start)
        _endedAt = State(initialValue: end)
    }

    private var validationMessage: String? {
        if startedAt >= endedAt {
            return AppStrings.localized("history_add_fast_invalid_range")
        }
        if endedAt > Date() {
            return AppStrings.localized("history_add_fast_future_end")
        }
        if overlappingSession != nil {
            return AppStrings.localized("history_add_fast_overlap")
        }
        return nil
    }

    private var overlappingSession: FastingSession? {
        sessions.first { session in
            guard session.deletedAt == nil, session.status != .discarded else { return false }
            let existingEnd = session.endedAt ?? Date()
            return session.startedAt < endedAt && existingEnd > startedAt
        }
    }

    private var canSave: Bool {
        validationMessage == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        AppStrings.localized("history_add_fast_start_label"),
                        selection: $startedAt,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    DatePicker(
                        AppStrings.localized("history_add_fast_end_label"),
                        selection: $endedAt,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } footer: {
                    Text(AppStrings.localized("history_add_fast_help"))
                }

                Section(AppStrings.localized("history_add_fast_preview_title")) {
                    HStack {
                        Text(AppStrings.localized("history_add_fast_duration_label"))
                        Spacer()
                        Text(durationText)
                            .foregroundStyle(Color.lumePrimary)
                            .monospacedDigit()
                    }
                    if let overlappingSession {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(AppStrings.localized("history_add_fast_conflict_label"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.timerDestructive)
                            FastRow(session: overlappingSession)
                                .padding(.vertical, 4)
                        }
                    }
                }

                Section(AppStrings.localized("history_add_fast_notes_label")) {
                    TextField(AppStrings.localized("history_add_fast_notes_placeholder"), text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let message = validationMessage ?? errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(Color.timerDestructive)
                    }
                }
            }
            .navigationTitle(AppStrings.localized("history_add_fast_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.save) {
                        save()
                    }
                    .accessibilityIdentifier("history.saveMissedFastButton")
                    .disabled(!canSave)
                }
            }
        }
    }

    private var durationText: String {
        let minutes = max(0, Int(endedAt.timeIntervalSince(startedAt) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 {
            return AppStrings.scheduleDurationMinutes(remainder)
        }
        if remainder == 0 {
            return AppStrings.scheduleDurationHours(hours)
        }
        return AppStrings.scheduleDurationHoursMinutes(hours: hours, minutes: remainder)
    }

    private func save() {
        errorMessage = nil
        do {
            let session = try FastingSessionService(
                context: modelContext,
                notificationService: NotificationService()
            )
            .addHistoricalFast(
                plan: nil,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
            )
            AppLogger.info("Added missed fast \(session.id)", category: "History")
            dismiss()
        } catch FastingError.overlappingSession {
            errorMessage = AppStrings.localized("history_add_fast_overlap")
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("Failed to add missed fast: \(error)", category: "History")
        }
    }
}

private struct AllFastsScreen: View {
    @Environment(\.modelContext) private var modelContext
    let sessions: [FastingSession]
    @State private var selectedSession: FastingSession?
    @State private var editingSession: FastingSession?

    private let calculator = FastingHistoryCalculator()

    private var groups: [(year: Int, sessions: [FastingSession])] {
        calculator.sessionsGroupedByYear(sessions)
    }

    var body: some View {
        List {
            if groups.isEmpty {
                HistoryEmptyState(text: AppStrings.localized("history_empty_list"))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(groups, id: \.year) { group in
                    Section(String(group.year)) {
                        ForEach(group.sessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                FastRow(session: session, showsDetailIndicator: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.timerBackground)
        .navigationTitle(AppStrings.localized("history_all_fasts_title"))
        .sheet(item: $selectedSession) { session in
            FastDetailScreen(
                session: session,
                phases: calculator.phases(for: session),
                onEdit: editAfterDetail,
                onDelete: deleteAfterDetail
            )
        }
        .sheet(item: $editingSession) { session in
            EditFastSheet(session: session, sessions: sessions)
        }
    }

    private func delete(_ session: FastingSession) {
        do {
            try FastingSessionService(
                context: modelContext,
                notificationService: NotificationService()
            )
            .softDelete(session: session)
            AppLogger.info("Deleted history fast \(session.id)", category: "History")
        } catch {
            AppLogger.error("Failed to delete history fast \(session.id): \(error)", category: "History")
        }
    }

    private func editAfterDetail(_ session: FastingSession) {
        selectedSession = nil
        DispatchQueue.main.async {
            editingSession = session
        }
    }

    private func deleteAfterDetail(_ session: FastingSession) {
        delete(session)
        selectedSession = nil
    }
}

private struct FastDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    let session: FastingSession
    let phases: [FastingPhase]
    let onEdit: (FastingSession) -> Void
    let onDelete: (FastingSession) -> Void
    @State private var isConfirmingDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FastRow(session: session)
                        .padding(16)
                        .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 16))

                    HStack(spacing: 12) {
                        Button {
                            onEdit(session)
                        } label: {
                            Label(AppStrings.localized("history_edit_fast_button"), systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.lumeSage)
                        .accessibilityIdentifier("history.detailEditFastButton")

                        Button {
                            isConfirmingDelete = true
                        } label: {
                            Label(AppStrings.localized("history_delete_fast_button"), systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("history.detailDeleteFastButton")
                    }

                    Text(AppStrings.localized("history_phases_title"))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.lumePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 10) {
                        ForEach(phases) { phase in
                            FastPhaseRow(phase: phase)
                        }
                    }

                    Text(AppStrings.localized("history_phases_note"))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.lumeMuted)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            .background(Color.timerBackground)
            .navigationTitle(AppStrings.localized("history_fast_detail_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppStrings.done) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                AppStrings.localized("history_delete_fast_title"),
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button(AppStrings.localized("history_delete_fast_button"), role: .destructive) {
                    onDelete(session)
                }
                .accessibilityIdentifier("history.confirmDeleteFastButton")
                Button(AppStrings.cancel, role: .cancel) {}
            } message: {
                Text(AppStrings.localized("history_delete_fast_message"))
            }
        }
    }
}

private struct FastPhaseRow: View {
    let phase: FastingPhase

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: phase.isReached ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(phase.isReached ? Color.lumeSage : Color.lumeMuted)
                .font(.system(size: 19, weight: .semibold))
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(phase.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.lumePrimary)
                    .multilineTextAlignment(.leading)
                Text(phase.timeRange)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.lumeSage)
                    .multilineTextAlignment(.leading)
                Text(phase.summary)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.lumeMuted)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct FastRow: View {
    @Query(sort: \UserSettings.createdAt) private var settingsRows: [UserSettings]
    let session: FastingSession
    var showsDetailIndicator = false

    private var timeFormat: TimeFormat {
        settingsRows.first?.timeFormat ?? .system
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.status == .completed ? "checkmark.seal.fill" : "leaf")
                .foregroundStyle(session.status == .completed ? Color.lumeSage : Color.lumeGold)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.lumePrimary)
                        .multilineTextAlignment(.leading)
                    if session.status == .skipped {
                        Text(AppStrings.localized("history_skipped_status"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.lumePrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.lumeGold.opacity(0.18), in: Capsule())
                    }
                }
                Text(timeRangeText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.lumeMuted)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Text(durationText)
                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.lumePrimary)
            if showsDetailIndicator {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.lumeMuted)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }

    private var timeRangeText: String {
        let start = AppTimeFormatter.timeString(from: session.startedAt, timeFormat: timeFormat)
        let end = session.endedAt.map { AppTimeFormatter.timeString(from: $0, timeFormat: timeFormat) } ?? AppStrings.notStarted
        return "\(start) - \(end)"
    }

    private var durationText: String {
        let minutes = max(0, session.actualFastingMinutes ?? 0)
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 {
            return AppStrings.scheduleDurationMinutes(remainder)
        }
        if remainder == 0 {
            return AppStrings.scheduleDurationHours(hours)
        }
        return AppStrings.scheduleDurationHoursMinutes(hours: hours, minutes: remainder)
    }
}

private struct HistoryMetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.lumeSage)
                .frame(width: 30, height: 30)
                .background(Color.lumeSage.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            Text(value)
                .font(.system(size: 20, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.lumePrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.lumeMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lumeStroke.opacity(0.7), lineWidth: 0.5)
        }
    }
}

private struct HistoryEmptyState: View {
    let text: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color.lumeSage)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.lumeMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        HistoryScreen()
    }
    .modelContainer(for: [FastingPlan.self, FastingSession.self, WeeklySchedule.self, CheatDay.self, UserSettings.self], inMemory: true)
}
