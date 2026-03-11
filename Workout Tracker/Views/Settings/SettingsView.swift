import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var context

    @Query(filter: #Predicate<Workout> { $0.endTime != nil }) var workouts: [Workout]
    @Query var bodyEntries: [BodyEntry]
    @Query var prs: [PersonalRecord]

    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showResetAlert = false
    @State private var showWorkoutReminderPicker = false
    @State private var reminderHour = 7
    @State private var reminderMinute = 0
    @State private var reminderEnabled = false
    @State private var heightFeet = 5
    @State private var heightInches = 10

    var body: some View {
        NavigationStack {
            Form {
                // Units
                unitsSection

                // Workout defaults
                workoutDefaultsSection

                // Rest Timer
                restTimerSection

                // Notifications
                notificationsSection

                // Appearance
                appearanceSection

                // Data
                dataSection

                // About
                aboutSection
            }
            .navigationTitle("Settings")
            .onChange(of: appState.weightUnit) { _, _ in appState.saveSettings() }
            .onChange(of: appState.measurementUnit) { _, _ in appState.saveSettings() }
            .onChange(of: appState.defaultRestTime) { _, _ in appState.saveSettings() }
            .onChange(of: appState.theme) { _, _ in appState.saveSettings() }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var unitsSection: some View {
        @Bindable var appState = appState
        Section("Units") {
            Picker("Weight Unit", selection: $appState.weightUnit) {
                ForEach(WeightUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            Picker("Measurements", selection: $appState.measurementUnit) {
                ForEach(MeasurementUnit.allCases, id: \.self) { u in
                    Text(u.rawValue).tag(u)
                }
            }

            HStack {
                Text("Height")
                Spacer()
                Picker("Feet", selection: $heightFeet) {
                    ForEach(3...8, id: \.self) { Text("\($0)'") }
                }
                .pickerStyle(.wheel)
                .frame(width: 60, height: 80)

                Picker("Inches", selection: $heightInches) {
                    ForEach(0..<12, id: \.self) { Text("\($0)\"") }
                }
                .pickerStyle(.wheel)
                .frame(width: 60, height: 80)
            }
            .onChange(of: heightFeet) { _, _ in updateHeight() }
            .onChange(of: heightInches) { _, _ in updateHeight() }
        }
    }

    @ViewBuilder
    private var workoutDefaultsSection: some View {
        @Bindable var appState = appState
        Section("Workout Defaults") {
            Stepper("Warmup Sets: \(appState.warmupSetsDefault)", value: $appState.warmupSetsDefault, in: 0...3)
            Stepper("Working Sets: \(appState.workingSetsDefault)", value: $appState.workingSetsDefault, in: 1...8)
            Stepper("Default Reps: \(appState.repsDefault)", value: $appState.repsDefault, in: 1...50)
            Toggle("Show Plate Calculator Button", isOn: $appState.showPlateCalculatorButton)
        }
    }

    @ViewBuilder
    private var restTimerSection: some View {
        @Bindable var appState = appState
        Section("Rest Timer") {
            HStack {
                Text("Default Rest Time")
                Spacer()
                Text(formatRestTime(appState.defaultRestTime))
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { Double(appState.defaultRestTime) },
                    set: { appState.defaultRestTime = Int($0) }
                ),
                in: 15...600,
                step: 15
            )
            .tint(.orange)

            HStack(spacing: 8) {
                ForEach([60, 90, 120, 180, 300], id: \.self) { seconds in
                    Button(formatRestTime(seconds)) {
                        appState.defaultRestTime = seconds
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(appState.defaultRestTime == seconds ? Color.orange : Color(.systemGray5))
                    .foregroundStyle(appState.defaultRestTime == seconds ? .white : .primary)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                }
            }

            Toggle("Rest Timer Notifications", isOn: $appState.useRestTimerNotifications)
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Daily Workout Reminder", isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { _, enabled in
                    if enabled {
                        NotificationService.shared.scheduleWorkoutReminder(hour: reminderHour, minute: reminderMinute)
                    } else {
                        NotificationService.shared.cancelAllNotifications()
                    }
                }

            if reminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: {
                            var c = DateComponents()
                            c.hour = reminderHour
                            c.minute = reminderMinute
                            return Calendar.current.date(from: c) ?? Date()
                        },
                        set: { date in
                            reminderHour = Calendar.current.component(.hour, from: date)
                            reminderMinute = Calendar.current.component(.minute, from: date)
                            if reminderEnabled {
                                NotificationService.shared.scheduleWorkoutReminder(
                                    hour: reminderHour, minute: reminderMinute
                                )
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    @ViewBuilder
    private var appearanceSection: some View {
        @Bindable var appState = appState
        Section("Appearance") {
            Picker("Theme", selection: $appState.theme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
        }
    }

    @ViewBuilder
    private var dataSection: some View {
        Section("Data") {
            // Stats
            HStack {
                Text("Workouts")
                Spacer()
                Text("\(workouts.count)").foregroundStyle(.secondary)
            }
            HStack {
                Text("Body Entries")
                Spacer()
                Text("\(bodyEntries.count)").foregroundStyle(.secondary)
            }
            HStack {
                Text("Personal Records")
                Spacer()
                Text("\(prs.count)").foregroundStyle(.secondary)
            }

            // Export
            Button {
                exportData()
            } label: {
                Label("Export Data (CSV)", systemImage: "square.and.arrow.up")
            }

            // Reset
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
        }
        .alert("Clear All Data?", isPresented: $showResetAlert) {
            Button("Clear Everything", role: .destructive) { clearAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all workouts, body entries, and personal records. This cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("WorkoutTracker")
                Spacer()
                Text("1.0.0").foregroundStyle(.secondary)
            }
            HStack {
                Text("Built with")
                Spacer()
                Text("SwiftUI + SwiftData").foregroundStyle(.secondary)
            }
            NavigationLink("Plate Calculator") {
                PlateCalculatorView()
            }
        }
    }

    // MARK: - Actions

    private func updateHeight() {
        // Convert feet/inches to cm and store
        let totalInches = heightFeet * 12 + heightInches
        appState.heightCm = Double(totalInches) * 2.54
        appState.saveSettings()
    }

    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }

    private func exportData() {
        let workoutsCSV = ExportService.exportWorkoutsCSV(workouts: workouts)
        let bodyCSV = ExportService.exportBodyEntriesCSV(entries: bodyEntries)
        let prsCSV = ExportService.exportPRsCSV(prs: prs)

        let combined = "=== WORKOUTS ===\n\(workoutsCSV)\n\n=== BODY TRACKING ===\n\(bodyCSV)\n\n=== PERSONAL RECORDS ===\n\(prsCSV)"

        if let url = ExportService.writeToTemporaryFile(
            content: combined,
            filename: "workout_data_\(Date().shortDateString).csv"
        ) {
            exportURL = url
            showExportSheet = true
        }
    }

    private func clearAllData() {
        for w in workouts { context.delete(w) }
        for b in bodyEntries { context.delete(b) }
        for p in prs { context.delete(p) }
        try? context.save()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
