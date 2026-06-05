import SwiftData
import SwiftUI

struct ScheduleScreen: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingPlan.name) private var plans: [FastingPlan]
    @Query(sort: \WeeklySchedule.weekday) private var schedules: [WeeklySchedule]
    @State private var selectedDay: ScheduleDayDraft?
    @State private var showingTemplates = false
    @State private var pendingTemplate: ScheduleTemplate?
    @State private var pendingStartTimePropagation: PendingStartTimePropagation?

    private var rows: [ScheduleDayDraft] {
        orderedWeekdays.map { weekday in
            if let schedule = schedules.first(where: { $0.weekday == weekday }) {
                return ScheduleDayDraft(schedule: schedule)
            }
            return ScheduleDayDraft.defaultDay(weekday: weekday, plan: defaultPlan)
        }
    }

    private var orderedWeekdays: [Int] {
        let first = calendar.firstWeekday
        return (0..<7).map { (($0 + first - 1) % 7) + 1 }
    }

    private var defaultPlan: FastingPlan? {
        plans.first { $0.name == "16:8" } ?? plans.first
    }

    private var nextFastingDay: ScheduleDayDraft? {
        rows.first { $0.state == .fasting && $0.startTimeMinutes != nil }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                headerCard

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(AppStrings.scheduleWeeklyOverview)
                            .font(.system(size: 12, weight: .semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(Color.lumeSage)
                        Spacer()
                        Button {
                            showingTemplates = true
                        } label: {
                            Label(AppStrings.scheduleTemplates, systemImage: "square.grid.2x2")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .accessibilityIdentifier("schedule.templatesButton")
                    }
                    .padding(.horizontal, 4)

                    LazyVStack(spacing: 10) {
                        ForEach(rows) { row in
                            Button {
                                selectedDay = row
                                AppLogger.info("Opened schedule editor for weekday \(row.weekday)", category: "Interaction")
                            } label: {
                                ScheduleDayRow(
                                    draft: row,
                                    dayName: weekdayName(row.weekday),
                                    isToday: calendar.component(.weekday, from: Date()) == row.weekday,
                                    timeText: timeText
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("schedule.day.\(row.weekday)")
                        }
                    }
                }

                Text(AppStrings.scheduleMedicalNote)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.lumeMuted)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(Color.timerBackground)
        .navigationTitle(AppStrings.scheduleTitle)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingTemplates) {
            ScheduleTemplatePicker(
                templates: ScheduleTemplate.allCases,
                applyTemplate: { template in
                    pendingTemplate = template
                    showingTemplates = false
                }
            )
            .presentationDetents([.large])
        }
        .sheet(item: $selectedDay) { day in
            ScheduleDayEditor(
                draft: day,
                plans: planOptions,
                dayName: weekdayName(day.weekday),
                timeText: timeText,
                save: save
            )
            .presentationDetents([.large])
        }
        .sheet(item: $pendingStartTimePropagation) { propagation in
            StartTimePropagationSheet(
                startTimeText: timeText(propagation.startTimeMinutes),
                apply: {
                    applyStartTimeToOtherFastingDays(propagation)
                    pendingStartTimePropagation = nil
                },
                keepSingleDay: {
                    pendingStartTimePropagation = nil
                }
            )
            .presentationDetents([.height(300)])
        }
        .confirmationDialog(
            AppStrings.scheduleApplyTemplateTitle,
            isPresented: Binding(
                get: { pendingTemplate != nil },
                set: { if !$0 { pendingTemplate = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pendingTemplate {
                Button(AppStrings.scheduleApplyTemplateButton(pendingTemplate.title)) {
                    applyTemplate(pendingTemplate)
                    self.pendingTemplate = nil
                }
                .accessibilityIdentifier("schedule.applyTemplateButton")
            }
            Button(AppStrings.cancel, role: .cancel) {
                pendingTemplate = nil
            }
        } message: {
            Text(AppStrings.scheduleTemplateMessage)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.lumeSage)
                    .frame(width: 8, height: 8)
                Text(AppStrings.scheduleCurrentPlan)
                    .font(.system(size: 12, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.lumeSage)
            }

            Text(nextFastingDay?.planName.map { AppStrings.scheduleIntermittentPlan($0) } ?? AppStrings.scheduleBuildRhythm)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.lumePrimary)

            Text(nextFastingSummary)
                .font(.system(size: 15))
                .foregroundStyle(Color.lumeMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.lumeStroke.opacity(0.54), lineWidth: 0.5)
        }
        .shadow(color: Color.lumeSage.opacity(0.12), radius: 16, x: 0, y: 8)
        .accessibilityIdentifier("schedule.headerCard")
    }

    private var nextFastingSummary: String {
        guard let day = nextFastingDay, let start = day.startTimeMinutes else {
            return AppStrings.scheduleChooseTemplate
        }
        return AppStrings.scheduleNextStart(day: weekdayName(day.weekday), time: timeText(start))
    }

    private var planOptions: [FastingPlan] {
        let names = ["14:10", "16:8", "18:6", "20:4"]
        return names.compactMap { name in plans.first { $0.name == name } }
    }

    private func weekdayName(_ weekday: Int) -> String {
        calendar.weekdaySymbols[weekday - 1].capitalized(with: locale)
    }

    private func timeText(_ minutes: Int) -> String {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let date = calendar.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func save(_ draft: ScheduleDayDraft) {
        let existing = schedules.first { $0.weekday == draft.weekday }
        let previousStartTime = existing?.startTimeMinutesFromMidnight
        let row = existing ?? WeeklySchedule(
            weekday: draft.weekday,
            plan: nil,
            isFastingDay: false,
            isCheatDay: false,
            startTimeMinutesFromMidnight: nil,
            reminderEnabled: false,
            updatedAt: Date()
        )
        if existing == nil {
            modelContext.insert(row)
        }
        apply(draft, to: row)
        persist("Saved schedule day \(draft.weekday)")
        if shouldAskToApplyStartTimeToOtherDays(draft: draft, previousStartTime: previousStartTime) {
            pendingStartTimePropagation = PendingStartTimePropagation(
                sourceWeekday: draft.weekday,
                startTimeMinutes: draft.startTimeMinutes ?? 20 * 60
            )
        }
        selectedDay = nil
    }

    private func shouldAskToApplyStartTimeToOtherDays(draft: ScheduleDayDraft, previousStartTime: Int?) -> Bool {
        guard draft.state == .fasting, let startTime = draft.startTimeMinutes else { return false }
        guard previousStartTime != startTime else { return false }
        return schedules.contains { schedule in
            schedule.weekday != draft.weekday && schedule.isFastingDay
        }
    }

    private func applyStartTimeToOtherFastingDays(_ propagation: PendingStartTimePropagation) {
        for schedule in schedules where schedule.weekday != propagation.sourceWeekday && schedule.isFastingDay {
            schedule.startTimeMinutesFromMidnight = propagation.startTimeMinutes
            schedule.updatedAt = Date()
        }
        persist("Applied fasting start time to other fasting days")
    }

    private func applyTemplate(_ template: ScheduleTemplate) {
        for weekday in orderedWeekdays {
            let existing = schedules.first { $0.weekday == weekday }
            let row = existing ?? WeeklySchedule(
                weekday: weekday,
                plan: nil,
                isFastingDay: false,
                isCheatDay: false,
                startTimeMinutesFromMidnight: nil,
                reminderEnabled: false,
                updatedAt: Date()
            )
            if existing == nil {
                modelContext.insert(row)
            }
            apply(template.draft(for: weekday, plan: plan(named: template.planName) ?? defaultPlan), to: row)
        }
        persist("Applied schedule template \(template.id)")
    }

    private func apply(_ draft: ScheduleDayDraft, to row: WeeklySchedule) {
        row.plan = draft.state == .fasting ? draft.plan : nil
        row.isFastingDay = draft.state == .fasting
        row.isCheatDay = draft.state == .cheat
        row.startTimeMinutesFromMidnight = draft.state == .fasting ? draft.startTimeMinutes : nil
        row.reminderEnabled = draft.state == .fasting && draft.reminderEnabled
        row.restrictedCalorieGuidance = draft.state == .restricted ? draft.restrictedCalorieGuidance : nil
        row.cheatReason = draft.state == .cheat ? draft.cheatReason : nil
        row.excludesCheatDayFromStreak = draft.excludesCheatDayFromStreak
        row.templateIdentifier = draft.templateIdentifier
        row.updatedAt = Date()
    }

    private func persist(_ message: String) {
        do {
            try modelContext.save()
            AppLogger.info(message, category: "Schedule")
        } catch {
            AppLogger.error("Failed to save schedule: \(error)", category: "Schedule")
        }
    }

    private func plan(named name: String?) -> FastingPlan? {
        guard let name else { return nil }
        return plans.first { $0.name == name }
    }
}

private struct PendingStartTimePropagation: Identifiable {
    let sourceWeekday: Int
    let startTimeMinutes: Int

    var id: String {
        "\(sourceWeekday)-\(startTimeMinutes)"
    }
}

private struct StartTimePropagationSheet: View {
    let startTimeText: String
    let apply: () -> Void
    let keepSingleDay: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.lumeSage)
                .frame(width: 44, height: 44)
                .background(Color.lumeSage.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.scheduleApplyStartTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.lumePrimary)
                    .multilineTextAlignment(.leading)

                Text(AppStrings.scheduleUseStartTime(startTimeText))
                    .font(.system(size: 15))
                    .foregroundStyle(Color.lumeMuted)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button(action: apply) {
                    Text(AppStrings.scheduleApplyStartButton)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.lumeSage)
                .accessibilityIdentifier("schedule.applyStartTimeToOtherDaysButton")

                Button(action: keepSingleDay) {
                    Text(AppStrings.scheduleKeepSingleDayButton)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Color.lumeMuted)
                .accessibilityIdentifier("schedule.keepSingleDayStartTimeButton")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(Color.timerBackground)
    }
}

private enum ScheduleDayState: String, CaseIterable, Identifiable {
    case fasting
    case restricted
    case normal
    case cheat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fasting: return AppStrings.localized("schedule_state_fasting")
        case .restricted: return AppStrings.localized("schedule_state_restricted")
        case .normal: return AppStrings.localized("schedule_state_normal")
        case .cheat: return AppStrings.localized("schedule_state_cheat")
        }
    }
}

private struct ScheduleDayDraft: Identifiable {
    var id: Int { weekday }
    var weekday: Int
    var state: ScheduleDayState
    var plan: FastingPlan?
    var startTimeMinutes: Int?
    var reminderEnabled: Bool
    var restrictedCalorieGuidance: Int?
    var cheatReason: String
    var excludesCheatDayFromStreak: Bool
    var templateIdentifier: String?

    var planName: String? { plan?.name }

    init(
        weekday: Int,
        state: ScheduleDayState,
        plan: FastingPlan?,
        startTimeMinutes: Int?,
        reminderEnabled: Bool,
        restrictedCalorieGuidance: Int?,
        cheatReason: String = "",
        excludesCheatDayFromStreak: Bool = true,
        templateIdentifier: String? = nil
    ) {
        self.weekday = weekday
        self.state = state
        self.plan = plan
        self.startTimeMinutes = startTimeMinutes
        self.reminderEnabled = reminderEnabled
        self.restrictedCalorieGuidance = restrictedCalorieGuidance
        self.cheatReason = cheatReason
        self.excludesCheatDayFromStreak = excludesCheatDayFromStreak
        self.templateIdentifier = templateIdentifier
    }

    init(schedule: WeeklySchedule) {
        let state: ScheduleDayState
        if schedule.isCheatDay {
            state = .cheat
        } else if schedule.isFastingDay {
            state = .fasting
        } else if schedule.restrictedCalorieGuidance != nil {
            state = .restricted
        } else {
            state = .normal
        }
        self.init(
            weekday: schedule.weekday,
            state: state,
            plan: schedule.plan,
            startTimeMinutes: schedule.startTimeMinutesFromMidnight,
            reminderEnabled: schedule.reminderEnabled,
            restrictedCalorieGuidance: schedule.restrictedCalorieGuidance,
            cheatReason: schedule.cheatReason ?? "",
            excludesCheatDayFromStreak: schedule.excludesCheatDayFromStreak,
            templateIdentifier: schedule.templateIdentifier
        )
    }

    static func defaultDay(weekday: Int, plan: FastingPlan?) -> ScheduleDayDraft {
        ScheduleDayDraft(
            weekday: weekday,
            state: .normal,
            plan: plan,
            startTimeMinutes: 20 * 60,
            reminderEnabled: true,
            restrictedCalorieGuidance: nil
        )
    }
}

private enum ScheduleTemplate: String, CaseIterable, Identifiable {
    case beginner16_8
    case gentle14_10
    case advanced18_6
    case intensive20_4
    case weekly5_2
    case alternateDay
    case custom

    var id: String { rawValue }

    var title: String {
        AppStrings.scheduleTemplateTitle(id)
    }

    var subtitle: String {
        AppStrings.scheduleTemplateSubtitle(id)
    }

    var planName: String? {
        switch self {
        case .beginner16_8: return "16:8"
        case .gentle14_10: return "14:10"
        case .advanced18_6: return "18:6"
        case .intensive20_4: return "20:4"
        default: return nil
        }
    }

    var isAdvanced: Bool {
        self == .weekly5_2 || self == .alternateDay || self == .intensive20_4
    }

    var isRecommended: Bool {
        self == .beginner16_8
    }

    func draft(for weekday: Int, plan: FastingPlan?) -> ScheduleDayDraft {
        switch self {
        case .beginner16_8, .gentle14_10, .advanced18_6, .intensive20_4:
            return ScheduleDayDraft(
                weekday: weekday,
                state: .fasting,
                plan: plan,
                startTimeMinutes: 20 * 60,
                reminderEnabled: true,
                restrictedCalorieGuidance: nil,
                templateIdentifier: id
            )
        case .weekly5_2:
            let restricted = weekday == 2 || weekday == 5
            return ScheduleDayDraft(
                weekday: weekday,
                state: restricted ? .restricted : .normal,
                plan: nil,
                startTimeMinutes: nil,
                reminderEnabled: false,
                restrictedCalorieGuidance: restricted ? 550 : nil,
                templateIdentifier: id
            )
        case .alternateDay:
            let restricted = [2, 4, 6].contains(weekday)
            return ScheduleDayDraft(
                weekday: weekday,
                state: restricted ? .restricted : .normal,
                plan: nil,
                startTimeMinutes: nil,
                reminderEnabled: false,
                restrictedCalorieGuidance: restricted ? 550 : nil,
                templateIdentifier: id
            )
        case .custom:
            return ScheduleDayDraft.defaultDay(weekday: weekday, plan: plan)
        }
    }
}

private struct ScheduleDayRow: View {
    let draft: ScheduleDayDraft
    let dayName: String
    let isToday: Bool
    let timeText: (Int) -> String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(dayName.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isToday ? Color.lumePrimary : Color.lumeMuted)
                    Text(draft.state.title.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(badgeForeground)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(badgeBackground, in: Capsule())
                    if isToday {
                        Text(AppStrings.scheduleToday)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.lumeSage, in: Capsule())
                    }
                }

                Text(primaryText)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.lumePrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(detailText)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.lumeMuted)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: draft.reminderEnabled ? "bell.badge.fill" : trailingIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(trailingColor)
                Text(trailingText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(trailingColor)
            }
        }
        .padding(16)
        .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.lumeSage.opacity(0.55) : Color.lumeStroke.opacity(0.54), lineWidth: isToday ? 1.5 : 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dayName), \(draft.state.title), \(primaryText), \(detailText)")
    }

    private var primaryText: String {
        switch draft.state {
        case .fasting: return AppStrings.scheduleFastingWindow(draft.planName ?? AppStrings.scheduleTemplateTitle("custom"))
        case .restricted: return AppStrings.scheduleRestrictedDay
        case .normal: return AppStrings.scheduleNormalDay
        case .cheat: return AppStrings.scheduleCheatDay
        }
    }

    private var detailText: String {
        switch draft.state {
        case .fasting:
            guard let plan = draft.plan, let start = draft.startTimeMinutes else { return AppStrings.scheduleStartTimeNeeded }
            return AppStrings.scheduleEatingWindow(
                start: timeText((start + plan.fastingMinutes) % 1440),
                end: timeText((start + plan.fastingMinutes + plan.eatingMinutes) % 1440)
            )
        case .restricted:
            return AppStrings.scheduleCalorieGuidance(draft.restrictedCalorieGuidance ?? 550)
        case .normal:
            return AppStrings.scheduleNoFastingRequirement
        case .cheat:
            return draft.cheatReason.isEmpty ? AppStrings.scheduleRemindersPaused : draft.cheatReason
        }
    }

    private var trailingText: String {
        guard draft.state == .fasting, let start = draft.startTimeMinutes else { return AppStrings.scheduleOpen }
        return timeText(start)
    }

    private var trailingIcon: String {
        switch draft.state {
        case .fasting: return "clock"
        case .restricted: return "leaf"
        case .normal: return "sun.max"
        case .cheat: return "sparkles"
        }
    }

    private var trailingColor: Color {
        switch draft.state {
        case .fasting: return Color.lumeSage
        case .restricted: return Color.orange
        case .normal: return Color.lumeMuted
        case .cheat: return Color.purple
        }
    }

    private var badgeForeground: Color {
        draft.state == .normal ? Color.lumeMuted : Color.white
    }

    private var badgeBackground: Color {
        switch draft.state {
        case .fasting: return Color.lumeSage
        case .restricted: return Color.orange
        case .normal: return Color.lumeSurfaceSoft
        case .cheat: return Color.purple
        }
    }
}

private struct ScheduleTemplatePicker: View {
    @Environment(\.dismiss) private var dismiss
    let templates: [ScheduleTemplate]
    let applyTemplate: (ScheduleTemplate) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(templates) { template in
                        Button {
                            applyTemplate(template)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(template.title)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(Color.lumePrimary)
                                        if template.isRecommended {
                                            Text(AppStrings.scheduleRecommended)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(Color.lumeSage)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(Color.lumeSage.opacity(0.12), in: Capsule())
                                        } else if template.isAdvanced {
                                            Text(AppStrings.scheduleAdvanced)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(Color.orange)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(Color.orange.opacity(0.12), in: Capsule())
                                        }
                                    }
                                    Text(template.subtitle)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.lumeMuted)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.lumeSage)
                            }
                            .padding(16)
                            .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.lumeStroke.opacity(0.54), lineWidth: 0.5)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("schedule.template.\(template.id)")
                    }
                }
                .padding(20)
            }
            .background(Color.timerBackground)
            .navigationTitle(AppStrings.scheduleSelectTemplate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.close) { dismiss() }
                }
            }
        }
    }
}

private struct ScheduleDayEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ScheduleDayDraft
    let plans: [FastingPlan]
    let dayName: String
    let timeText: (Int) -> String
    let save: (ScheduleDayDraft) -> Void

    init(
        draft: ScheduleDayDraft,
        plans: [FastingPlan],
        dayName: String,
        timeText: @escaping (Int) -> String,
        save: @escaping (ScheduleDayDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        self.plans = plans
        self.dayName = dayName
        self.timeText = timeText
        self.save = save
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(AppStrings.scheduleDayState) {
                    Picker(AppStrings.scheduleDayState, selection: $draft.state) {
                        ForEach(ScheduleDayState.allCases) { state in
                            Text(state.title)
                                .tag(state)
                                .accessibilityIdentifier("schedule.editor.state.\(state.id)")
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("schedule.editor.statePicker")
                }

                if draft.state == .fasting {
                    Section(AppStrings.schedulePlanSelection) {
                        Picker(AppStrings.schedulePlan, selection: planBinding) {
                            ForEach(plans, id: \.id) { plan in
                                Text(AppStrings.schedulePlanProtocol(plan.name)).tag(Optional(plan))
                            }
                        }
                        .accessibilityIdentifier("schedule.editor.planPicker")

                        DatePicker(
                            AppStrings.scheduleFastingStarts,
                            selection: startTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .accessibilityIdentifier("schedule.editor.startTimePicker")

                        Toggle(AppStrings.scheduleNotifyStart, isOn: $draft.reminderEnabled)
                            .accessibilityIdentifier("schedule.editor.reminderToggle")
                    }

                    Section(AppStrings.scheduleFastingPreview) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(previewTitle)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.lumePrimary)
                            Text(previewSubtitle)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.lumeMuted)
                        }
                        .accessibilityIdentifier("schedule.editor.preview")
                    }
                }

                if draft.state == .restricted {
                    Section(AppStrings.scheduleRestrictedGuidance) {
                        Stepper(value: restrictedCaloriesBinding, in: 300...900, step: 50) {
                            Text(AppStrings.scheduleCalorieGuidance(draft.restrictedCalorieGuidance ?? 550))
                        }
                        .accessibilityIdentifier("schedule.editor.restrictedCalories")
                    }
                }

                if draft.state == .cheat {
                    Section(AppStrings.scheduleCheatDaySection) {
                        TextField(AppStrings.scheduleReason, text: $draft.cheatReason)
                            .accessibilityIdentifier("schedule.editor.cheatReason")
                        Toggle(AppStrings.scheduleExcludeCheat, isOn: $draft.excludesCheatDayFromStreak)
                            .accessibilityIdentifier("schedule.editor.excludeCheatToggle")
                    }
                }
            }
            .navigationTitle(AppStrings.scheduleEditDay(dayName))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.save) {
                        save(normalizedDraft)
                    }
                    .accessibilityIdentifier("schedule.editor.saveButton")
                }
            }
            .onChange(of: draft.state) { _, newState in
                if newState == .restricted {
                    draft.restrictedCalorieGuidance = draft.restrictedCalorieGuidance ?? 550
                    draft.reminderEnabled = false
                } else if newState == .normal {
                    draft.reminderEnabled = false
                    draft.restrictedCalorieGuidance = nil
                } else if newState == .cheat {
                    draft.reminderEnabled = false
                    draft.restrictedCalorieGuidance = nil
                } else if newState == .fasting {
                    draft.plan = draft.plan ?? plans.first
                    draft.startTimeMinutes = draft.startTimeMinutes ?? 20 * 60
                    draft.reminderEnabled = true
                }
            }
        }
    }

    private var normalizedDraft: ScheduleDayDraft {
        var copy = draft
        switch copy.state {
        case .fasting:
            copy.plan = copy.plan ?? plans.first
            copy.startTimeMinutes = copy.startTimeMinutes ?? 20 * 60
            copy.restrictedCalorieGuidance = nil
        case .restricted:
            copy.plan = nil
            copy.startTimeMinutes = nil
            copy.reminderEnabled = false
            copy.restrictedCalorieGuidance = copy.restrictedCalorieGuidance ?? 550
        case .normal:
            copy.plan = nil
            copy.startTimeMinutes = nil
            copy.reminderEnabled = false
            copy.restrictedCalorieGuidance = nil
        case .cheat:
            copy.plan = nil
            copy.startTimeMinutes = nil
            copy.reminderEnabled = false
            copy.restrictedCalorieGuidance = nil
        }
        copy.templateIdentifier = nil
        return copy
    }

    private var planBinding: Binding<FastingPlan?> {
        Binding(
            get: { draft.plan ?? plans.first },
            set: { draft.plan = $0 }
        )
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: {
                let minutes = draft.startTimeMinutes ?? 20 * 60
                var components = DateComponents()
                components.hour = minutes / 60
                components.minute = minutes % 60
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                draft.startTimeMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

    private var restrictedCaloriesBinding: Binding<Int> {
        Binding(
            get: { draft.restrictedCalorieGuidance ?? 550 },
            set: { draft.restrictedCalorieGuidance = $0 }
        )
    }

    private var previewTitle: String {
        guard let plan = draft.plan ?? plans.first, let start = draft.startTimeMinutes else {
            return AppStrings.scheduleChoosePlanStart
        }
        let fastEnd = (start + plan.fastingMinutes) % 1440
        let eatEnd = (fastEnd + plan.eatingMinutes) % 1440
        return AppStrings.scheduleFastPreview(start: timeText(start), fastEnd: timeText(fastEnd), eatEnd: timeText(eatEnd))
    }

    private var previewSubtitle: String {
        guard let plan = draft.plan ?? plans.first else { return "" }
        return AppStrings.schedulePreviewSubtitle(fastingHours: plan.fastingMinutes / 60, eatingHours: plan.eatingMinutes / 60)
    }
}

#Preview {
    NavigationStack {
        ScheduleScreen()
    }
    .modelContainer(for: [FastingPlan.self, WeeklySchedule.self], inMemory: true)
}
