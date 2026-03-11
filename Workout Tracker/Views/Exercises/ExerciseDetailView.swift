import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

    @Query(filter: #Predicate<Workout> { $0.endTime != nil },
           sort: \Workout.startTime, order: .reverse)
    var workouts: [Workout]

    @State private var showDeleteAlert = false

    private var history: [(workout: Workout, sets: [WorkoutSet])] {
        workouts.compactMap { workout in
            let sets = workout.sortedExercises
                .filter { $0.exercise?.id == exercise.id || $0.exerciseName == exercise.name }
                .flatMap { $0.completedSets }
            return sets.isEmpty ? nil : (workout, sets)
        }
    }

    private var allCompletedSets: [(date: Date, set: WorkoutSet)] {
        history.flatMap { entry in
            entry.sets.map { (date: entry.workout.startTime, set: $0) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info card
                infoCard

                // Stats
                if !allCompletedSets.isEmpty {
                    statsCard
                    strengthChart
                    volumeChart
                }

                // History
                if !history.isEmpty {
                    historySection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if exercise.isCustom {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .alert("Delete Exercise?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(exercise)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: ExerciseCategory(rawValue: exercise.category)?.icon ?? "dumbbell")
                    Text(exercise.category)
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.forCategory(exercise.category).opacity(0.15))
                .foregroundStyle(Color.forCategory(exercise.category))
                .clipShape(Capsule())

                // Equipment badge
                HStack(spacing: 6) {
                    Image(systemName: "wrench.fill")
                    Text(exercise.equipment)
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.systemGray5))
                .foregroundStyle(.secondary)
                .clipShape(Capsule())

                if exercise.isCustom {
                    Text("Custom")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }

            if !exercise.primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Primary Muscles")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(exercise.primaryMuscles.joined(separator: ", "))
                        .font(.subheadline)
                }
            }

            if !exercise.secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Secondary Muscles")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(exercise.secondaryMuscles.joined(separator: ", "))
                        .font(.subheadline)
                }
            }

            if !exercise.instructions.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Instructions")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(exercise.instructions)
                        .font(.subheadline)
                        .lineLimit(nil)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats

    private var statsCard: some View {
        let maxWeight = allCompletedSets.map(\.set.weight).max() ?? 0
        let maxEstimated1RM = allCompletedSets.map(\.set.estimatedOneRepMax).max() ?? 0
        let maxReps = allCompletedSets.map(\.set.reps).max() ?? 0
        let totalSets = allCompletedSets.count

        return VStack(alignment: .leading, spacing: 8) {
            Text("Personal Bests")
                .font(.subheadline.bold())

            HStack(spacing: 0) {
                PRStatItem(
                    label: "Max Weight",
                    value: "\(maxWeight.cleanString) \(appState.weightUnit.rawValue)"
                )
                PRStatItem(
                    label: "Est. 1RM",
                    value: "\(maxEstimated1RM.cleanString) \(appState.weightUnit.rawValue)"
                )
                PRStatItem(
                    label: "Max Reps",
                    value: "\(maxReps)"
                )
                PRStatItem(
                    label: "Total Sets",
                    value: "\(totalSets)"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Charts

    private var strengthChart: some View {
        let data = allCompletedSets
            .filter { $0.set.weight > 0 }
            .map { (date: $0.date, value: $0.set.estimatedOneRepMax) }
            .sorted { $0.date < $1.date }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Estimated 1RM over Time")
                .font(.subheadline.bold())

            if data.count < 2 {
                Text("Need more data to display chart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.value)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.value)
                    )
                    .foregroundStyle(Color.orange.opacity(0.1).gradient)
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var volumeChart: some View {
        let data = history.map { entry -> (date: Date, volume: Double) in
            let vol = entry.sets.reduce(0.0) { $0 + $1.volume }
            return (date: entry.workout.startTime, volume: vol)
        }.sorted { $0.date < $1.date }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Session Volume")
                .font(.subheadline.bold())

            if data.count < 2 {
                Text("Need more data to display chart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(data, id: \.date) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History (\(history.count) sessions)")
                .font(.subheadline.bold())

            ForEach(history.prefix(10), id: \.workout.id) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.workout.startTime.shortDateString)
                            .font(.caption.bold())
                        Spacer()
                        if let best = entry.sets.max(by: { $0.weight < $1.weight }) {
                            Text("Best: \(best.weight.cleanString) × \(best.reps)")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    ForEach(entry.sets.sorted { $0.setNumber < $1.setNumber }) { set in
                        HStack {
                            SetTypeBadge(type: set.typeEnum, number: set.setNumber)
                            Text("\(set.weight.cleanString) \(appState.weightUnit.rawValue) × \(set.reps) reps")
                                .font(.caption)
                            Spacer()
                            Text("~\(set.estimatedOneRepMax.cleanString) 1RM")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                if entry.workout.id != history.prefix(10).last?.workout.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PRStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.bold())
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
