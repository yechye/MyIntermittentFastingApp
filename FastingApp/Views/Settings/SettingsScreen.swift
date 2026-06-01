import SwiftUI

struct SettingsScreen: View {
    @Binding var selectedTheme: AppTheme
    @AppStorage("settings.defaultPlan") private var defaultPlan = "16:8"
    @AppStorage("settings.defaultStartTime") private var defaultStartTimeInterval: Double = defaultStartTimeSeed.timeIntervalSinceReferenceDate
    @AppStorage("settings.fastingReminders") private var fastingReminders = true
    @AppStorage("settings.eatingWindowAlert") private var eatingWindowAlert = true
    @AppStorage("settings.fastCompletionAlert") private var fastCompletionAlert = true
    @AppStorage("settings.weightSync") private var weightSync = false
    @AppStorage("settings.weightUnit") private var weightUnit = WeightUnit.kg.rawValue
    @AppStorage("settings.timeFormat") private var timeFormat = TimeFormat.system.rawValue
    @AppStorage(AppLogger.minimumLevelKey) private var minimumLogLevel = AppLogger.defaultMinimumLevel.storageValue

    private let fastingPlans = ["16:8", "18:6", "20:4", "OMAD"]

    private var defaultStartTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSinceReferenceDate: defaultStartTimeInterval) },
            set: { defaultStartTimeInterval = $0.timeIntervalSinceReferenceDate }
        )
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
                }

                SettingsSection(title: AppStrings.localized("settings_fasting_preferences_section")) {
                    SettingsPickerRow(
                        icon: "timer",
                        iconColor: Color.lumeSage,
                        iconBackground: Color.lumeSage.opacity(0.14),
                        title: AppStrings.localized("settings_default_plan_label"),
                        selection: $defaultPlan,
                        options: fastingPlans,
                        displayName: fastingPlanTitle
                    )
                    SettingsDivider()
                    SettingsDateRow(
                        icon: "clock",
                        title: AppStrings.localized("settings_default_start_time_label"),
                        selection: defaultStartTime
                    )
                }

                SettingsSection(title: AppStrings.localized("settings_notifications_section")) {
                    SettingsToggleRow(icon: "bell", title: AppStrings.localized("settings_fasting_reminders_label"), isOn: $fastingReminders)
                    SettingsDivider()
                    SettingsToggleRow(icon: "fork.knife", title: AppStrings.localized("settings_eating_window_alert_label"), isOn: $eatingWindowAlert)
                    SettingsDivider()
                    SettingsToggleRow(icon: "checkmark.seal", title: AppStrings.localized("settings_fast_completion_alert_label"), isOn: $fastCompletionAlert)
                }

                SettingsSection(title: AppStrings.localized("settings_health_section")) {
                    SettingsNavigationRow(
                        icon: "heart.fill",
                        iconColor: Color.red,
                        iconBackground: Color.red.opacity(0.1),
                        title: AppStrings.appleHealth,
                        value: AppStrings.localized("settings_health_connected_status")
                    )
                    SettingsDivider()
                    SettingsToggleRow(
                        icon: "scalemass",
                        iconColor: Color.blue,
                        iconBackground: Color.blue.opacity(0.1),
                        title: AppStrings.localized("settings_weight_sync_label"),
                        isOn: $weightSync
                    )
                    SettingsDivider()
                    SettingsPickerRow(
                        icon: "ruler",
                        iconColor: Color.lumePrimary.opacity(0.72),
                        iconBackground: Color.lumeSurfaceSoft,
                        title: AppStrings.localized("settings_weight_unit_label"),
                        selection: $weightUnit,
                        options: [WeightUnit.kg.rawValue, WeightUnit.lb.rawValue]
                    )
                }

                SettingsSection(title: AppStrings.localized("settings_time_format_section")) {
                    SettingsPickerRow(
                        icon: "clock.badge",
                        iconColor: Color.orange,
                        iconBackground: Color.orange.opacity(0.12),
                        title: AppStrings.localized("settings_time_format_label"),
                        selection: $timeFormat,
                        options: [TimeFormat.system.rawValue, TimeFormat.twelveHour.rawValue, TimeFormat.twentyFourHour.rawValue],
                        displayName: timeFormatTitle
                    )
                }

                SettingsSection(title: AppStrings.localized("settings_data_privacy_section")) {
                    SettingsActionRow(icon: "square.and.arrow.up", title: AppStrings.localized("settings_export_history_label")) {
                        AppLogger.info("Tapped export fasting history", category: "Interaction")
                    }
                    SettingsDivider()
                    SettingsActionRow(
                        icon: "trash",
                        iconColor: Color.timerDestructive,
                        iconBackground: Color.timerDestructive.opacity(0.1),
                        title: AppStrings.localized("settings_reset_data_label"),
                        titleColor: Color.timerDestructive
                    ) {
                        AppLogger.warning("Tapped reset app data", category: "Interaction")
                    }
                }
                Text(AppStrings.localized("settings_privacy_note"))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.lumeMuted)
                    .padding(.horizontal, 16)
                    .padding(.top, -12)

                SettingsSection(title: AppStrings.localized("settings_debug_section")) {
                    SettingsPickerRow(
                        icon: "ladybug",
                        iconColor: Color.purple,
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
        .onChange(of: defaultPlan) { _, newValue in
            AppLogger.info("Changed default fasting plan to \(newValue)", category: "Interaction")
        }
        .onChange(of: defaultStartTimeInterval) { _, newValue in
            let date = Date(timeIntervalSinceReferenceDate: newValue)
            AppLogger.info("Changed default start time to \(date.formatted(date: .omitted, time: .shortened))", category: "Interaction")
        }
        .onChange(of: fastingReminders) { _, newValue in
            AppLogger.info("Set fasting reminders to \(newValue)", category: "Interaction")
        }
        .onChange(of: eatingWindowAlert) { _, newValue in
            AppLogger.info("Set eating window alert to \(newValue)", category: "Interaction")
        }
        .onChange(of: fastCompletionAlert) { _, newValue in
            AppLogger.info("Set fast completion alert to \(newValue)", category: "Interaction")
        }
        .onChange(of: weightSync) { _, newValue in
            AppLogger.info("Set weight sync to \(newValue)", category: "Interaction")
        }
        .onChange(of: weightUnit) { _, newValue in
            AppLogger.info("Changed weight unit to \(newValue)", category: "Interaction")
        }
        .onChange(of: timeFormat) { _, newValue in
            AppLogger.info("Changed time format to \(newValue)", category: "Interaction")
        }
        .onChange(of: minimumLogLevel) { oldValue, newValue in
            let previousLevel = AppLogLevel(storageValue: oldValue)
            let newLevel = AppLogLevel(storageValue: newValue)
            AppLogger.warning("Changed minimum log level from \(previousLevel.storageValue) to \(newLevel.storageValue)", category: "Interaction")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version ?? "1.0"
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

    private static var defaultStartTimeSeed: Date {
        var components = DateComponents()
        components.hour = 20
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
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

private struct SettingsNavigationRow: View {
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
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.lumeMuted.opacity(0.7))
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
            HStack(spacing: 12) {
                SettingsIcon(systemName: icon, color: iconColor, background: iconBackground)
                Text(title)
                    .settingsRowTitle(color: titleColor)
                Spacer(minLength: 12)
                if titleColor != Color.timerDestructive {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.lumeMuted.opacity(0.7))
                }
            }
            .settingsRowFrame()
        }
        .buttonStyle(.plain)
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
