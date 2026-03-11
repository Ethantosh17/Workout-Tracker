import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query(filter: #Predicate<Workout> { $0.endTime != nil },
           sort: \Workout.startTime, order: .reverse)
    var workouts: [Workout]

    @Query(sort: \PersonalRecord.date, order: .reverse) var allPRs: [PersonalRecord]
    @Environment(AppState.self) var appState

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("PRs").tag(1)
                    Text("Charts").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case 0: overviewTab
                case 1: prsTab
                case 2: chartsTab
                default: overviewTab
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Lifetime stats
                lifetimeStatsSection

                // Weekly summary
                weeklyChart

                // Muscle frequency heatmap
                muscleHeatmapSection

                // Recent PRs
                if !allPRs.isEmpty {
                    recentPRsSection
                }
            }
            .padding()
        }
    }

    private var lifetimeStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifetime Stats")
                .font(.headline)

            let totalWorkouts = workouts.count
            let totalVolume = workouts.reduce(0.0) { $0 + $1.totalVolume }
            let totalSets = workouts.reduce(0) { $0 + $1.totalSets }
            let totalDuration = workouts.reduce(0.0) { $0 + $1.duration }
            let avgDuration = totalWorkouts > 0 ? totalDuration / Double(totalWorkouts) : 0

            let grid = [GridItem(.flexible()), GridItem(.flexible())]

            LazyVGrid(columns: grid, spacing: 12) {
                LifetimeStatCard(
                    value: "\(totalWorkouts)",
                    label: "Total Workouts",
                    icon: "dumbbell.fill",
                    color: .orange
                )
                LifetimeStatCard(
                    value: formatVolume(totalVolume),
                    label: "Total Volume",
                    icon: "scalemass.fill",
                    color: .blue
                )
                LifetimeStatCard(
                    value: "\(totalSets)",
                    label: "Total Sets",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                LifetimeStatCard(
                    value: avgDuration.shortDurationFormatted,
                    label: "Avg. Duration",
                    icon: "timer",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatVolume(_ v: Double) -> String {
        v >= 1_000_000 ? String(format: "%.1fM", v / 1_000_000) :
        v >= 1_000 ? String(format: "%.0fk", v / 1_000) :
        String(format: "%.0f", v)
    }

    private var weeklyChart: some View {
        let last8Weeks = (0..<8).reversed().map { weeksAgo -> (label: String, count: Int) in
            let calendar = Calendar.current
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date().startOfDay)!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            let count = workouts.filter { $0.startTime >= weekStart && $0.startTime < weekEnd }.count

            let fmt = DateFormatter()
            fmt.dateFormat = "M/d"
            return (label: fmt.string(from: weekStart), count: count)
        }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Workouts per Week")
                .font(.headline)

            if last8Weeks.allSatisfy({ $0.count == 0 }) {
                Text("Complete workouts to see your frequency")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(last8Weeks, id: \.label) { point in
                    BarMark(
                        x: .value("Week", point.label),
                        y: .value("Workouts", point.count)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
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

    private var muscleHeatmapSection: some View {
        let categories = ExerciseCategory.allCases.filter { $0 != .other }
        let counts = muscleSetCounts()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Muscle Group Focus (All Time)")
                .font(.headline)

            let maxCount = (counts.values.max() ?? 1)
            let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

            LazyVGrid(columns: grid, spacing: 10) {
                ForEach(categories, id: \.rawValue) { cat in
                    let count = counts[cat.rawValue] ?? 0
                    let ratio = maxCount > 0 ? Double(count) / Double(maxCount) : 0

                    VStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.title3)
                            .foregroundStyle(count > 0 ? Color.forCategory(cat.rawValue) : .secondary)
                        Text(cat.rawValue)
                            .font(.caption2.bold())
                            .multilineTextAlignment(.center)
                        Text("\(count) sets")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.forCategory(cat.rawValue).opacity(0.1 + 0.4 * ratio))
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func muscleSetCounts() -> [String: Int] {
        var counts: [String: Int] = [:]
        for workout in workouts {
            for exercise in workout.exercises {
                counts[exercise.exerciseCategory, default: 0] += exercise.completedSets.count
            }
        }
        return counts
    }

    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent PRs 🏆")
                .font(.headline)

            ForEach(allPRs.prefix(5)) { pr in
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(pr.exerciseName)
                            .font(.subheadline.bold())
                        Text(pr.metric + " • " + pr.date.shortDateString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(pr.value.cleanString) \(appState.weightUnit.rawValue)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - PRs Tab

    private var prsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if allPRs.isEmpty {
                    emptyPRsView
                } else {
                    let grouped = Dictionary(grouping: allPRs) { $0.exerciseName }
                    ForEach(grouped.keys.sorted(), id: \.self) { exerciseName in
                        PRExerciseCard(exerciseName: exerciseName, prs: grouped[exerciseName] ?? [], weightUnit: appState.weightUnit)
                    }
                }
            }
            .padding()
        }
    }

    private var emptyPRsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No PRs Yet")
                .font(.title2.bold())
            Text("PRs are automatically tracked as you train.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }

    // MARK: - Charts Tab

    private var chartsTab: some View {
        let exerciseNames = Array(Set(
            workouts.flatMap { $0.sortedExercises.map(\.displayName) }
        )).sorted()

        return ScrollView {
            VStack(spacing: 16) {
                if exerciseNames.isEmpty {
                    Text("Complete workouts to see exercise charts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(40)
                } else {
                    ForEach(exerciseNames.prefix(10), id: \.self) { exerciseName in
                        ExerciseProgressCard(
                            exerciseName: exerciseName,
                            workouts: workouts,
                            weightUnit: appState.weightUnit
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct LifetimeStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.headline.bold())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PRExerciseCard: View {
    let exerciseName: String
    let prs: [PersonalRecord]
    let weightUnit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseName)
                .font(.subheadline.bold())

            ForEach(prs.sorted(by: { $0.date > $1.date }).prefix(3)) { pr in
                HStack {
                    Image(systemName: pr.metricEnum.icon)
                        .foregroundStyle(.yellow)
                        .frame(width: 20)
                    Text(pr.metric)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(pr.value.cleanString) \(pr.metricEnum == .maxReps ? "reps" : weightUnit.rawValue)")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Text(pr.date.shortDateString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ExerciseProgressCard: View {
    let exerciseName: String
    let workouts: [Workout]
    let weightUnit: WeightUnit

    private var data: [(date: Date, max1rm: Double, maxWeight: Double)] {
        workouts.compactMap { w in
            let sets = w.sortedExercises
                .filter { $0.displayName == exerciseName }
                .flatMap { $0.completedSets }
            guard !sets.isEmpty else { return nil }
            let max1rm = sets.map(\.estimatedOneRepMax).max() ?? 0
            let maxWeight = sets.map(\.weight).max() ?? 0
            return (date: w.startTime, max1rm: max1rm, maxWeight: maxWeight)
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseName)
                .font(.subheadline.bold())

            if data.count < 2 {
                Text("Need more sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Est. 1RM", point.max1rm)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Est. 1RM", point.max1rm)
                    )
                    .foregroundStyle(Color.orange)
                    .symbolSize(30)
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxisLabel("\(weightUnit.rawValue)")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
