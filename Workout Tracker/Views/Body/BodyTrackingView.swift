import SwiftUI
import SwiftData
import Charts

struct BodyTrackingView: View {
    @Query(sort: \BodyEntry.date, order: .reverse) var entries: [BodyEntry]
    @Environment(\.modelContext) var context
    @Environment(AppState.self) var appState

    @State private var showAddEntry = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Weight").tag(0)
                    Text("Measurements").tag(1)
                    Text("Log").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case 0: weightTab
                case 1: measurementsTab
                case 2: logTab
                default: weightTab
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Body Tracking")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddEntry = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEntry) {
                AddBodyEntryView()
            }
        }
    }

    // MARK: - Weight Tab

    private var weightTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                let weightEntries = entries.filter { $0.weight > 0 }

                if weightEntries.isEmpty {
                    emptyState("No weight data yet.\nLog your first entry to start tracking.")
                } else {
                    // Current weight card
                    if let latest = weightEntries.first {
                        VStack(spacing: 6) {
                            Text("Current Weight")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(latest.weight.cleanString) \(appState.weightUnit.rawValue)")
                                .font(.largeTitle.bold())
                            Text(latest.date.relativeString)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let bmi = latest.bmi(heightCm: appState.heightCm) {
                                HStack {
                                    Text("BMI: \(String(format: "%.1f", bmi))")
                                        .font(.subheadline)
                                        .foregroundStyle(bmiColor(bmi))
                                    Text(bmiCategory(bmi))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Weight chart
                    weightChart(entries: Array(weightEntries.prefix(30).reversed()))

                    // Stats
                    weightStats(entries: weightEntries)
                }
            }
            .padding()
        }
    }

    private func weightChart(entries: [BodyEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight Over Time")
                .font(.headline)

            if entries.count < 2 {
                Text("Log more entries to see chart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(entries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(Color.orange.opacity(0.1).gradient)

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(Color.orange)
                    .symbolSize(25)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func weightStats(entries: [BodyEntry]) -> some View {
        let weights = entries.map(\.weight)
        let min = weights.min() ?? 0
        let max = weights.max() ?? 0
        let avg = weights.isEmpty ? 0 : weights.reduce(0, +) / Double(weights.count)
        let change = entries.count >= 2 ? entries[0].weight - entries[entries.count - 1].weight : 0

        return HStack(spacing: 0) {
            BodyStatItem(value: min.cleanString, label: "Min")
            BodyStatItem(value: max.cleanString, label: "Max")
            BodyStatItem(value: avg.cleanString, label: "Average")
            BodyStatItem(
                value: (change >= 0 ? "+" : "") + change.cleanString,
                label: "Total Change",
                color: change > 0 ? .red : (change < 0 ? .green : .primary)
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Measurements Tab

    private var measurementsTab: some View {
        let measurementEntries = entries.filter { $0.hasMeasurements }

        return ScrollView {
            VStack(spacing: 16) {
                if measurementEntries.isEmpty {
                    emptyState("No measurements yet.\nLog your first entry to track measurements.")
                } else if let latest = measurementEntries.first {
                    measurementsCard(latest)

                    // Change from earliest
                    if measurementEntries.count >= 2 {
                        measurementsChangeCard(from: measurementEntries.last!, to: latest)
                    }
                }
            }
            .padding()
        }
    }

    private func measurementsCard(_ entry: BodyEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Latest Measurements")
                    .font(.headline)
                Spacer()
                Text(entry.date.shortDateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let unit = appState.measurementUnit.lengthLabel

            let measurements: [(String, Double)] = [
                ("Neck", entry.neck), ("Shoulders", entry.shoulders),
                ("Chest", entry.chest),
                ("Left Bicep", entry.leftBicep), ("Right Bicep", entry.rightBicep),
                ("Left Forearm", entry.leftForearm), ("Right Forearm", entry.rightForearm),
                ("Waist", entry.waist), ("Abdomen", entry.abdomen), ("Hips", entry.hips),
                ("Left Thigh", entry.leftThigh), ("Right Thigh", entry.rightThigh),
                ("Left Calf", entry.leftCalf), ("Right Calf", entry.rightCalf),
            ].filter { $0.1 > 0 }

            if measurements.isEmpty {
                Text("No measurements recorded for this entry")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(measurements, id: \.0) { name, value in
                        HStack {
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(value.cleanString) \(unit)")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func measurementsChangeCard(from: BodyEntry, to: BodyEntry) -> some View {
        let unit = appState.measurementUnit.lengthLabel
        let changes: [(String, Double)] = [
            ("Chest", to.chest - from.chest),
            ("Waist", to.waist - from.waist),
            ("Hips", to.hips - from.hips),
            ("Left Bicep", to.leftBicep - from.leftBicep),
            ("Left Thigh", to.leftThigh - from.leftThigh),
        ].filter { abs($0.1) > 0 }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Changes Since Start")
                .font(.headline)

            ForEach(changes, id: \.0) { name, delta in
                HStack {
                    Text(name).font(.subheadline)
                    Spacer()
                    Text((delta >= 0 ? "+" : "") + "\(delta.cleanString) \(unit)")
                        .font(.subheadline.bold())
                        .foregroundStyle(delta < 0 && name == "Waist" ? .green : (delta > 0 ? .green : .red))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Log Tab

    private var logTab: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink(destination: BodyEntryDetailView(entry: entry)) {
                    BodyEntryRow(entry: entry, weightUnit: appState.weightUnit)
                }
            }
            .onDelete { offsets in
                for i in offsets { context.delete(entries[i]) }
                try? context.save()
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if entries.isEmpty {
                emptyState("No entries yet.\nTap + to log your first entry.")
            }
        }
    }

    private func emptyState(_ text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // BMI helpers
    private func bmiColor(_ bmi: Double) -> Color {
        switch bmi {
        case ..<18.5: return .blue
        case 18.5..<25: return .green
        case 25..<30: return .yellow
        default: return .red
        }
    }
    private func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "(Underweight)"
        case 18.5..<25: return "(Normal)"
        case 25..<30: return "(Overweight)"
        default: return "(Obese)"
        }
    }
}

// MARK: - Supporting Views

struct BodyStatItem: View {
    let value: String
    let label: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct BodyEntryRow: View {
    let entry: BodyEntry
    let weightUnit: WeightUnit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date.shortDateString)
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    if entry.weight > 0 {
                        Text("\(entry.weight.cleanString) \(weightUnit.rawValue)")
                    }
                    if entry.bodyFatPercent > 0 {
                        Text("\(entry.bodyFatPercent.cleanString)% BF")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if !entry.notes.isEmpty {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct BodyEntryDetailView: View {
    @Bindable var entry: BodyEntry
    @Environment(AppState.self) var appState

    var body: some View {
        List {
            Section("Body Composition") {
                if entry.weight > 0 {
                    LabeledContent("Weight", value: "\(entry.weight.cleanString) \(appState.weightUnit.rawValue)")
                }
                if entry.bodyFatPercent > 0 {
                    LabeledContent("Body Fat", value: "\(entry.bodyFatPercent.cleanString)%")
                }
                if entry.muscleMassLbs > 0 {
                    LabeledContent("Muscle Mass", value: "\(entry.muscleMassLbs.cleanString) \(appState.weightUnit.rawValue)")
                }
            }

            let unit = appState.measurementUnit.lengthLabel
            let measurements: [(String, Double)] = [
                ("Neck", entry.neck), ("Shoulders", entry.shoulders),
                ("Chest", entry.chest),
                ("Left Bicep", entry.leftBicep), ("Right Bicep", entry.rightBicep),
                ("Waist", entry.waist), ("Abdomen", entry.abdomen), ("Hips", entry.hips),
                ("Left Thigh", entry.leftThigh), ("Right Thigh", entry.rightThigh),
                ("Left Calf", entry.leftCalf), ("Right Calf", entry.rightCalf),
            ].filter { $0.1 > 0 }

            if !measurements.isEmpty {
                Section("Measurements (\(unit))") {
                    ForEach(measurements, id: \.0) { name, val in
                        LabeledContent(name, value: "\(val.cleanString) \(unit)")
                    }
                }
            }

            if !entry.notes.isEmpty {
                Section("Notes") {
                    Text(entry.notes)
                }
            }
        }
        .navigationTitle(entry.date.shortDateString)
    }
}

// MARK: - Add Body Entry

struct AddBodyEntryView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) var appState

    @State private var date = Date()
    @State private var weight = ""
    @State private var bodyFat = ""
    @State private var muscleMass = ""
    @State private var neck = ""
    @State private var shoulders = ""
    @State private var chest = ""
    @State private var leftBicep = ""
    @State private var rightBicep = ""
    @State private var leftForearm = ""
    @State private var rightForearm = ""
    @State private var waist = ""
    @State private var abdomen = ""
    @State private var hips = ""
    @State private var leftThigh = ""
    @State private var rightThigh = ""
    @State private var leftCalf = ""
    @State private var rightCalf = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Body Composition") {
                    TextField("Weight (\(appState.weightUnit.rawValue))", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Body Fat (%)", text: $bodyFat)
                        .keyboardType(.decimalPad)
                    TextField("Muscle Mass (\(appState.weightUnit.rawValue))", text: $muscleMass)
                        .keyboardType(.decimalPad)
                }

                Section("Measurements (\(appState.measurementUnit.lengthLabel))") {
                    TextField("Neck", text: $neck).keyboardType(.decimalPad)
                    TextField("Shoulders", text: $shoulders).keyboardType(.decimalPad)
                    TextField("Chest", text: $chest).keyboardType(.decimalPad)
                    TextField("Left Bicep", text: $leftBicep).keyboardType(.decimalPad)
                    TextField("Right Bicep", text: $rightBicep).keyboardType(.decimalPad)
                    TextField("Left Forearm", text: $leftForearm).keyboardType(.decimalPad)
                    TextField("Right Forearm", text: $rightForearm).keyboardType(.decimalPad)
                    TextField("Waist", text: $waist).keyboardType(.decimalPad)
                    TextField("Abdomen", text: $abdomen).keyboardType(.decimalPad)
                    TextField("Hips", text: $hips).keyboardType(.decimalPad)
                    TextField("Left Thigh", text: $leftThigh).keyboardType(.decimalPad)
                    TextField("Right Thigh", text: $rightThigh).keyboardType(.decimalPad)
                    TextField("Left Calf", text: $leftCalf).keyboardType(.decimalPad)
                    TextField("Right Calf", text: $rightCalf).keyboardType(.decimalPad)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Log Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                }
            }
        }
    }

    private func save() {
        let entry = BodyEntry(date: date)
        entry.weight = Double(weight) ?? 0
        entry.bodyFatPercent = Double(bodyFat) ?? 0
        entry.muscleMassLbs = Double(muscleMass) ?? 0
        entry.neck = Double(neck) ?? 0
        entry.shoulders = Double(shoulders) ?? 0
        entry.chest = Double(chest) ?? 0
        entry.leftBicep = Double(leftBicep) ?? 0
        entry.rightBicep = Double(rightBicep) ?? 0
        entry.leftForearm = Double(leftForearm) ?? 0
        entry.rightForearm = Double(rightForearm) ?? 0
        entry.waist = Double(waist) ?? 0
        entry.abdomen = Double(abdomen) ?? 0
        entry.hips = Double(hips) ?? 0
        entry.leftThigh = Double(leftThigh) ?? 0
        entry.rightThigh = Double(rightThigh) ?? 0
        entry.leftCalf = Double(leftCalf) ?? 0
        entry.rightCalf = Double(rightCalf) ?? 0
        entry.notes = notes
        context.insert(entry)
        try? context.save()
        dismiss()
    }
}
