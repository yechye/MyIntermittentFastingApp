import SwiftData
import SwiftUI

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingPlan.name) private var plans: [FastingPlan]
    @Query(sort: \FastingSession.startedAt, order: .reverse) private var sessions: [FastingSession]
    @Query(sort: \UserSettings.createdAt) private var settingsRows: [UserSettings]
    @Binding var selectedTheme: AppTheme
    @AppStorage(AppLanguage.storageKey) private var selectedLanguageRaw = AppLanguage.system.storageValue
    @AppStorage(AppLogger.minimumLevelKey) private var minimumLogLevel = AppLogger.defaultMinimumLevel.storageValue
    @State private var settings: UserSettings?
    @State private var errorMessage: String?
    @State private var isResetConfirmationPresented = false

    private var service: UserSettingsService {
        UserSettingsService(
            context: modelContext,
            notificationService: NotificationService()
        )
    }

    private var activeSettings: UserSettings? {
        settingsRows.first ?? settings
    }

    private var export: FastingHistoryExport {
        let history = FastingHistoryCalculator().historySessions(from: sessions)
        return FastingHistoryExport(csvText: FastingHistoryExporter().csv(for: history, timeFormat: activeSettings?.timeFormat ?? .system))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsSection(title: AppStrings.appearance) {
                    Picker(AppStrings.theme, selection: $selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Label(theme.title, systemImage: theme.systemImage)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(14)
                    .accessibilityIdentifier("settings.themePicker")
                }

                SettingsSection(title: AppStrings.localized("settings_fasting_preferences_section")) {
                    SettingsPickerRow(
                        icon: "timer",
                        title: AppStrings.localized("settings_default_plan_label"),
                        selection: defaultPlanBinding,
                        options: planNames,
                        displayName: fastingPlanTitle
                    )
                    SettingsDivider()
                    SettingsDateRow(
                        icon: "clock",
                        title: AppStrings.localized("settings_default_start_time_label"),
                        selection: defaultStartTimeBinding
                    )
                }

                SettingsSection(title: AppStrings.localized("settings_notifications_section")) {
                    SettingsToggleRow(
                        icon: "bell",
                        title: AppStrings.localized("settings_fasting_reminders_label"),
                        isOn: fastingRemindersBinding
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        icon: "checkmark.seal",
                        title: AppStrings.localized("settings_fast_completion_alert_label"),
                        isOn: fastCompletionAlertBinding
                    )
                }

                SettingsSection(title: AppStrings.localized("settings_health_section")) {
                    SettingsStaticRow(
                        icon: "heart.fill",
                        iconColor: .red,
                        iconBackground: Color.red.opacity(0.1),
                        title: AppStrings.appleHealth,
                        value: activeSettings?.healthKitWeightEnabled == true ? AppStrings.localized("settings_health_connected_status") : AppStrings.localized("settings_health_not_connected_status")
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        icon: "scalemass",
                        iconColor: .blue,
                        iconBackground: Color.blue.opacity(0.1),
                        title: AppStrings.localized("settings_weight_sync_label"),
                        isOn: weightSyncBinding
                    )
                    SettingsDivider()
                    SettingsPickerRow(
                        icon: "ruler",
                        iconColor: Color.lumePrimary.opacity(0.72),
                        iconBackground: Color.lumeSurfaceSoft,
                        title: AppStrings.localized("settings_weight_unit_label"),
                        selection: weightUnitBinding,
                        options: [WeightUnit.kg.rawValue, WeightUnit.lb.rawValue]
                    )
                }

                SettingsSection(title: AppStrings.localized("settings_language_format_section")) {
                    SettingsPickerRow(
                        icon: "globe",
                        iconColor: Color.lumeSage,
                        iconBackground: Color.lumeSage.opacity(0.14),
                        title: AppStrings.localized("settings_language_label"),
                        selection: languageBinding,
                        options: AppLanguage.allCases.map(\.storageValue),
                        displayName: { AppLanguage(storageValue: $0).title }
                    )
                    SettingsDivider()
                    SettingsPickerRow(
                        icon: "clock.badge",
                        iconColor: .orange,
                        iconBackground: Color.orange.opacity(0.12),
                        title: AppStrings.localized("settings_time_format_label"),
                        selection: timeFormatBinding,
                        options: [TimeFormat.system.rawValue, TimeFormat.twelveHour.rawValue, TimeFormat.twentyFourHour.rawValue],
                        displayName: timeFormatTitle
                    )
                }

                SettingsSection(title: AppStrings.localized("settings_data_privacy_section")) {
                    ShareLink(item: export, preview: SharePreview(AppStrings.localized("history_export_title"))) {
                        SettingsActionRowContent(icon: "square.and.arrow.up", title: AppStrings.localized("settings_export_history_label"))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.exportHistoryButton")
                    SettingsDivider()
                    SettingsActionRow(
                        icon: "trash",
                        iconColor: Color.timerDestructive,
                        iconBackground: Color.timerDestructive.opacity(0.1),
                        title: AppStrings.localized("settings_reset_data_label"),
                        titleColor: Color.timerDestructive
                    ) {
                        isResetConfirmationPresented = true
                    }
                    .accessibilityIdentifier("settings.resetDataButton")
                }
                Text(AppStrings.localized("settings_privacy_note"))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.lumeMuted)
                    .padding(.horizontal, 16)
                    .padding(.top, -12)

                SettingsSection(title: AppStrings.localized("settings_debug_section")) {
                    SettingsPickerRow(
                        icon: "ladybug",
                        iconColor: .purple,
                        iconBackground: Color.purple.opacity(0.12),
                        title: AppStrings.localized("settings_log_level_label"),
                        selection: $minimumLogLevel,
                        options: AppLogLevel.allCases.map(\.storageValue),
                        displayName: { AppLogLevel(storageValue: $0).localizedTitle }
                    )
                }

                SettingsSection(title: AppStrings.localized("settings_about_section")) {
                    SettingsStaticRow(icon: "app", title: AppStrings.localized("settings_app_name_label"), value: AppStrings.appName)
                    SettingsDivider()
                    SettingsStaticRow(icon: "info.circle", title: AppStrings.localized("settings_version_label"), value: appVersion)
                    SettingsDivider()
                    SettingsActionRow(icon: "questionmark.bubble", title: AppStrings.localized("settings_support_feedback_label")) {
                        AppLogger.info("Tapped support or feedback", category: "Interaction")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(Color.timerBackground)
        .navigationBarTitleDisplayMode(.large)
        .task { loadSettings() }
        .alert(AppStrings.localized("settings_error_title"), isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button(AppStrings.localized("ok_button"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            AppStrings.localized("settings_reset_data_title"),
            isPresented: $isResetConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppStrings.localized("settings_reset_data_confirm"), role: .destructive) {
                resetFastingData()
            }
            Button(AppStrings.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.localized("settings_reset_data_message"))
        }
        .onChange(of: minimumLogLevel) { oldValue, newValue in
            let previousLevel = AppLogLevel(storageValue: oldValue)
            let newLevel = AppLogLevel(storageValue: newValue)
            AppLogger.warning("Changed minimum log level from \(previousLevel.storageValue) to \(newLevel.storageValue)", category: "Interaction")
        }
    }

    private var planNames: [String] {
        let names = plans.map(\.name)
        return names.isEmpty ? ["16:8"] : names
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version ?? "1.0"
    }

    private var defaultPlanBinding: Binding<String> {
        Binding(
            get: { activeSettings?.defaultPlan?.name ?? "16:8" },
            set: { newValue in
                guard activeSettings != nil, let plan = plans.first(where: { $0.name == newValue }) else { return }
                save("default fasting plan") { $0.defaultPlan = plan }
            }
        )
    }

    private var defaultStartTimeBinding: Binding<Date> {
        Binding(
            get: { date(minutesFromMidnight: activeSettings?.defaultStartTimeMinutesFromMidnight ?? UserSettings.defaultStartTimeMinutesFromMidnight) },
            set: { newValue in
                let minutes = Calendar.current.component(.hour, from: newValue) * 60 + Calendar.current.component(.minute, from: newValue)
                save("default start time") { $0.defaultStartTimeMinutesFromMidnight = minutes }
            }
        )
    }

    private var fastingRemindersBinding: Binding<Bool> {
        Binding(
            get: { activeSettings?.fastingRemindersEnabled ?? true },
            set: { newValue in
                guard let settings = activeSettings else { return }
                Task { @MainActor in
                    do {
                        try await service.setFastingRemindersEnabled(newValue, settings: settings)
                        AppLogger.info("Set fasting reminders to \(settings.fastingRemindersEnabled)", category: "Interaction")
                    } catch {
                        present(error, context: "update fasting reminders")
                    }
                }
            }
        )
    }

    private var fastCompletionAlertBinding: Binding<Bool> {
        Binding(
            get: { activeSettings?.fastCompletionAlertEnabled ?? true },
            set: { newValue in
                guard let settings = activeSettings else { return }
                Task { @MainActor in
                    do {
                        try await service.setFastCompletionAlertEnabled(newValue, settings: settings)
                        AppLogger.info("Set fast completion alert to \(settings.fastCompletionAlertEnabled)", category: "Interaction")
                    } catch {
                        present(error, context: "update fast completion alert")
                    }
                }
            }
        )
    }

    private var weightSyncBinding: Binding<Bool> {
        Binding(
            get: { activeSettings?.healthKitWeightEnabled ?? false },
            set: { newValue in
                Task { @MainActor in
                    await setWeightSyncEnabled(newValue)
                }
            }
        )
    }

    private var weightUnitBinding: Binding<String> {
        Binding(
            get: { activeSettings?.weightUnit.rawValue ?? WeightUnit.kg.rawValue },
            set: { newValue in
                save("weight unit") { $0.weightUnit = WeightUnit(rawValue: newValue) ?? .kg }
            }
        )
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { selectedLanguageRaw },
            set: {
                selectedLanguageRaw = AppLanguage(storageValue: $0).storageValue
                AppLogger.info("Changed app language to \(selectedLanguageRaw)", category: "Interaction")
            }
        )
    }

    private var timeFormatBinding: Binding<String> {
        Binding(
            get: { activeSettings?.timeFormat.rawValue ?? TimeFormat.system.rawValue },
            set: { newValue in
                save("time format") { $0.timeFormat = TimeFormat(rawValue: newValue) ?? .system }
            }
        )
    }

    private func loadSettings() {
        do {
            let loaded = try service.fetchOrCreate()
            settings = loaded
        } catch {
            present(error, context: "load settings")
        }
    }

    private func save(_ label: String, changes: (UserSettings) -> Void) {
        guard let settings = activeSettings else { return }
        do {
            try service.update(settings, changes: changes)
            AppLogger.info("Updated \(label)", category: "Interaction")
        } catch {
            present(error, context: "update \(label)")
        }
    }

    private func setWeightSyncEnabled(_ isEnabled: Bool) async {
        guard activeSettings != nil else { return }
        if isEnabled {
            do {
                try await HealthKitService().requestAuthorization()
                save("weight sync") { $0.healthKitWeightEnabled = true }
            } catch {
                save("weight sync") { $0.healthKitWeightEnabled = false }
                present(error, context: "authorize HealthKit weight sync")
            }
        } else {
            save("weight sync") { $0.healthKitWeightEnabled = false }
        }
    }

    private func resetFastingData() {
        do {
            try service.resetFastingDataPreservingPreferences()
            AppLogger.warning("Reset fasting data from Settings", category: "Interaction")
        } catch {
            present(error, context: "reset fasting data")
        }
    }

    private func present(_ error: Error, context: String) {
        errorMessage = error.localizedDescription
        AppLogger.error("Failed to \(context): \(error)", category: "Settings")
    }

    private func date(minutesFromMidnight: Int) -> Date {
        var components = DateComponents()
        components.hour = minutesFromMidnight / 60
        components.minute = minutesFromMidnight % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    private func timeFormatTitle(_ value: String) -> String {
        switch TimeFormat(rawValue: value) ?? .system {
        case .system:
            return AppStrings.localized("theme_system_label")
        case .twelveHour:
            return AppStrings.localized("settings_time_format_12_hour")
        case .twentyFourHour:
            return AppStrings.localized("settings_time_format_24_hour")
        }
    }

    private func fastingPlanTitle(_ value: String) -> String {
        value == "OMAD" ? AppStrings.localized("settings_plan_omad") : value
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.lumeSage)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                content
            }
            .background(Color.lumeSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.lumeStroke.opacity(0.54), lineWidth: 0.5)
            }
            .shadow(color: Color.lumePrimary.opacity(0.035), radius: 8, x: 0, y: 3)
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 60)
    }
}

private struct SettingsIcon: View {
    let systemName: String
    let color: Color
    let background: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .background(background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SettingsStaticRow: View {
    let icon: String
    var iconColor = Color.lumeSage
    var iconBackground = Color.lumeSage.opacity(0.14)
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, color: iconColor, background: iconBackground)
            Text(title)
                .settingsRowTitle()
            Spacer(minLength: 12)
            Text(value)
                .settingsRowValue()
        }
        .settingsRowFrame()
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    var iconColor = Color.lumeSage
    var iconBackground = Color.lumeSage.opacity(0.14)
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                SettingsIcon(systemName: icon, color: iconColor, background: iconBackground)
                Text(title)
                    .settingsRowTitle()
            }
        }
        .tint(Color.lumeSage)
        .settingsRowFrame()
    }
}

private struct SettingsPickerRow: View {
    let icon: String
    var iconColor = Color.lumeSage
    var iconBackground = Color.lumeSage.opacity(0.14)
    let title: String
    @Binding var selection: String
    let options: [String]
    var displayName: (String) -> String = { $0 }

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, color: iconColor, background: iconBackground)
            Text(title)
                .settingsRowTitle()
            Spacer(minLength: 12)
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayName(option))
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.lumeMuted)
        }
        .settingsRowFrame()
    }
}

private struct SettingsDateRow: View {
    let icon: String
    let title: String
    @Binding var selection: Date

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, color: Color.lumeSage, background: Color.lumeSage.opacity(0.14))
            Text(title)
                .settingsRowTitle()
            Spacer(minLength: 12)
            DatePicker(title, selection: $selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color.lumeSage)
        }
        .settingsRowFrame()
    }
}

private struct SettingsActionRow: View {
    let icon: String
    var iconColor = Color.lumePrimary.opacity(0.72)
    var iconBackground = Color.lumeSurfaceSoft
    let title: String
    var titleColor = Color.lumePrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsActionRowContent(icon: icon, iconColor: iconColor, iconBackground: iconBackground, title: title, titleColor: titleColor)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsActionRowContent: View {
    let icon: String
    var iconColor = Color.lumePrimary.opacity(0.72)
    var iconBackground = Color.lumeSurfaceSoft
    let title: String
    var titleColor = Color.lumePrimary

    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(systemName: icon, color: iconColor, background: iconBackground)
            Text(title)
                .settingsRowTitle(color: titleColor)
            Spacer(minLength: 12)
            if titleColor != Color.timerDestructive {
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.lumeMuted.opacity(0.7))
                    .accessibilityHidden(true)
            }
        }
        .settingsRowFrame()
    }
}

private extension Text {
    func settingsRowTitle(color: Color = Color.lumePrimary) -> some View {
        self
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }

    func settingsRowValue() -> some View {
        self
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(Color.lumeMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }
}

private extension View {
    func settingsRowFrame() -> some View {
        self
            .frame(minHeight: 52)
            .padding(.horizontal, 16)
    }
}
