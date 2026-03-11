import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var context
    @Query(filter: #Predicate<Workout> { $0.endTime != nil },
           sort: \Workout.startTime, order: .reverse)
    var completedWorkouts: [Workout]

    @Query(sort: \WorkoutTemplate.lastUsed, order: .reverse)
    var templates: [WorkoutTemplate]

    @Query(sort: \PersonalRecord.date, order: .reverse)
    var recentPRs: [PersonalRecord]

    @State private var showStartOptions = false
    @State private var showExercisePicker = false
    @State private var workoutName = "Morning Workout"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greetingHeader
                    statsRow
                    if appState.isWorkoutActive {
                        activeWorkoutCard
                    } else {
                        quickStartCard
                    }
                    weeklyVolumeChart
                    recentWorkoutsSection
                    if !recentPRs.isEmpty {
                        recentPRsSection
                    }
                    muscleGroupSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.title2).bold()
                Text(Date().shortDateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            streakBadge
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning 🌅"
        case 12..<17: return "Good afternoon ☀️"
        case 17..<21: return "Good evening 🌆"
        default: return "Good night 🌙"
        }
    }

    private var streakBadge: some View {
        VStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            Text("\(currentStreak)")
                .font(.headline).bold()
            Text("streak")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(workoutsThisWeek)",
                label: "This Week",
                icon: "dumbbell.fill",
                color: .orange
            )
            StatCard(
                value: totalVolumeThisWeek > 0 ? "\(Int(totalVolumeThisWeek / 1000))k" : "0",
                label: "Volume (lbs)",
                icon: "scalemass.fill",
                color: .blue
            )
            StatCard(
                value: "\(completedWorkouts.count)",
                label: "All Time",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }

    // MARK: - Active Workout Card

    private var activeWorkoutCard: some View {
        Button {
            appState.showingActiveWorkout = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout In Progress")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let vm = appState.activeWorkoutVM {
                        Text("\(vm.elapsedFormatted) • \(vm.workout.exercises.count) exercises")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.orange)
            }
            .padding()
            .background(Color.orange.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Quick Start

    private var quickStartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)

            Button {
                appState.startWorkout(name: "Empty Workout", context: context)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Start Empty Workout")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !templates.isEmpty {
                Text("From Template")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(templates.prefix(5)) { template in
                            TemplateQuickStartCard(template: template) {
                                appState.startWorkout(name: template.name, context: context, template: template)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Volume Chart

    private var weeklyVolumeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Volume")
                .font(.headline)

            if weeklyData.isEmpty {
                Text("Complete workouts to see your progress")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(weeklyData) { point in
                    BarMark(
                        x: .value("Day", point.label),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartYAxis(.hidden)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Workouts

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    WorkoutHistoryView()
                }
                .font(.subheadline)
                .foregroundStyle(.orange)
            }

            if completedWorkouts.isEmpty {
                Text("No workouts yet. Start your first one!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(completedWorkouts.prefix(3)) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        WorkoutRowView(workout: workout)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent PRs

    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent PRs 🏆")
                .font(.headline)

            ForEach(recentPRs.prefix(3)) { pr in
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pr.exerciseName)
                            .font(.subheadline).bold()
                        Text(pr.metric)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(pr.value.cleanString) \(appState.weightUnit.rawValue)")
                        .font(.subheadline).bold()
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Muscle Group Section

    private var muscleGroupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Muscles Trained (Last 7 Days)")
                .font(.headline)

            let counts = muscleFrequencyLastWeek

            if counts.isEmpty {
                Text("Start training to see muscle frequency")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(counts.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { item in
                    HStack {
                        Circle()
                            .fill(Color.forCategory(item.key))
                            .frame(width: 10, height: 10)
                        Text(item.key)
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.value) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        GeometryReader { geo in
                            let maxCount = counts.values.max() ?? 1
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.forCategory(item.key).opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(item.value) / CGFloat(maxCount))
                        }
                        .frame(width: 80, height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Computed Properties

    private var workoutsThisWeek: Int {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return completedWorkouts.filter { $0.startTime >= weekStart }.count
    }

    private var totalVolumeThisWeek: Double {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return completedWorkouts
            .filter { $0.startTime >= weekStart }
            .reduce(0) { $0 + $1.totalVolume }
    }

    private var currentStreak: Int {
        var streak = 0
        var checkDate = Date().startOfDay
        let calendar = Calendar.current

        for _ in 0..<365 {
            let hasWorkout = completedWorkouts.contains { $0.startTime.isSameDay(as: checkDate) }
            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if streak == 0 {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    struct WeeklyPoint: Identifiable {
        let id = UUID()
        let label: String
        let volume: Double
    }

    private var weeklyData: [WeeklyPoint] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { daysAgo -> WeeklyPoint in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date().startOfDay) ?? Date()
            let volume = completedWorkouts
                .filter { $0.startTime.isSameDay(as: date) }
                .reduce(0) { $0 + $1.totalVolume }
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return WeeklyPoint(label: formatter.string(from: date), volume: volume)
        }
    }

    private var muscleFrequencyLastWeek: [String: Int] {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        var counts: [String: Int] = [:]
        for workout in completedWorkouts where workout.startTime >= weekStart {
            for exercise in workout.exercises {
                let cat = exercise.exerciseCategory
                counts[cat, default: 0] += exercise.completedSets.count
            }
        }
        return counts
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2).bold()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct TemplateQuickStartCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.subheadline).bold()
                    .lineLimit(1)
                Text("\(template.exerciseCount) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(width: 130)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(.orange)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(.subheadline).bold()
                HStack(spacing: 8) {
                    Text(workout.startTime.relativeString)
                    Text("•")
                    Text(workout.duration.shortDurationFormatted)
                    Text("•")
                    Text("\(workout.sortedExercises.count) ex")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(workout.totalVolume))")
                    .font(.subheadline).bold()
                Text("lbs")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
