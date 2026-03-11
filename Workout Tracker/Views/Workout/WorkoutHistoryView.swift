import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(AppState.self) var appState
    @Query(filter: #Predicate<Workout> { $0.endTime != nil },
           sort: \Workout.startTime, order: .reverse)
    var workouts: [Workout]

    @State private var searchText = ""
    @State private var showCalendar = false
    @State private var selectedMonth: Date = Date()

    var filteredWorkouts: [Workout] {
        if searchText.isEmpty { return workouts }
        return workouts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sortedExercises.contains { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var groupedWorkouts: [(String, [Workout])] {
        let grouped = Dictionary(grouping: filteredWorkouts) { $0.startTime.monthYearString }
        return grouped.sorted { a, b in
            let df = DateFormatter()
            df.dateFormat = "MMMM yyyy"
            let da = df.date(from: a.key) ?? .distantPast
            let db = df.date(from: b.key) ?? .distantPast
            return da > db
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyState
                } else {
                    workoutList
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCalendar.toggle() } label: {
                        Image(systemName: showCalendar ? "list.bullet" : "calendar")
                    }
                }
            }
            .sheet(isPresented: $showCalendar) {
                WorkoutCalendarView(workouts: workouts)
            }
        }
    }

    private var workoutList: some View {
        List {
            // Stats summary
            statsSection

            // Grouped workouts
            ForEach(groupedWorkouts, id: \.0) { month, monthWorkouts in
                Section(month) {
                    ForEach(monthWorkouts) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            WorkoutHistoryRow(workout: workout, weightUnit: appState.weightUnit)
                        }
                    }
                    .onDelete { offsets in
                        // Note: deletion handled via WorkoutDetailView
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var statsSection: some View {
        Section {
            HStack(spacing: 0) {
                HistoryStatItem(value: "\(workouts.count)", label: "Workouts")
                Divider()
                HistoryStatItem(
                    value: "\(Int(workouts.reduce(0) { $0 + $1.totalVolume } / 1000))k",
                    label: "Total Volume"
                )
                Divider()
                HistoryStatItem(
                    value: workouts.isEmpty ? "0" : String(format: "%.0f", workouts.reduce(0) { $0 + $1.duration } / Double(workouts.count) / 60),
                    label: "Avg. Duration (min)"
                )
            }
            .frame(maxWidth: .infinity)
        }
        .listRowInsets(EdgeInsets())
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No Workouts Yet")
                .font(.title2.bold())
            Text("Complete a workout to see your history here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct WorkoutHistoryRow: View {
    let workout: Workout
    let weightUnit: WeightUnit

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline.bold())
                Text(workout.startTime.shortDateString + " • " + workout.startTime.timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(workout.sortedExercises.prefix(3).map(\.displayName).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(workout.duration.shortDurationFormatted)
                    .font(.subheadline)
                Text("\(Int(workout.totalVolume)) \(weightUnit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("\(workout.totalSets) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Calendar View

struct WorkoutCalendarView: View {
    let workouts: [Workout]
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate: Date = Date()
    @State private var displayMonth: Date = Date()

    var workoutDates: Set<String> {
        Set(workouts.map { Calendar.current.startOfDay(for: $0.startTime).shortDateString })
    }

    var workoutsForSelected: [Workout] {
        workouts.filter { $0.startTime.isSameDay(as: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader

                calendarGrid

                Divider()

                dayWorkoutList
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(-1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(displayMonth.monthYearString)
                .font(.headline)
            Spacer()
            Button { changeMonth(1) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }

    private func changeMonth(_ delta: Int) {
        displayMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayMonth) ?? displayMonth
    }

    private var calendarGrid: some View {
        let days = daysInMonth()
        let columns = Array(repeating: GridItem(.flexible()), count: 7)

        return VStack {
            // Day headers
            HStack {
                ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { d in
                    Text(d)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days.indices, id: \.self) { i in
                    if let date = days[i] {
                        CalendarDay(
                            date: date,
                            hasWorkout: workoutDates.contains(date.shortDateString),
                            isSelected: date.isSameDay(as: selectedDate),
                            isToday: date.isToday
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var dayWorkoutList: some View {
        Group {
            if workoutsForSelected.isEmpty {
                Text("No workouts on \(selectedDate.shortDateString)")
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(workoutsForSelected) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutHistoryRow(workout: workout, weightUnit: .lbs)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: startOfMonth))
        }
        return days
    }
}

struct CalendarDay: View {
    let date: Date
    let hasWorkout: Bool
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : (isToday ? .orange : .primary))

                if hasWorkout {
                    Circle()
                        .fill(isSelected ? .white : .orange)
                        .frame(width: 5, height: 5)
                } else {
                    Color.clear.frame(width: 5, height: 5)
                }
            }
            .frame(width: 36, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.orange : (isToday ? Color.orange.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(.plain)
    }
}
