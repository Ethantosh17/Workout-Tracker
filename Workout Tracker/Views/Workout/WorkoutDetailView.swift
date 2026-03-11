import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Bindable var workout: Workout
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) var appState

    @State private var showDeleteAlert = false
    @State private var isEditingName = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header stats
                headerStats

                // Exercises
                ForEach(workout.sortedExercises) { exercise in
                    ExerciseDetailCard(workoutExercise: exercise, weightUnit: appState.weightUnit)
                }

                // Notes
                if !workout.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Notes", systemImage: "note.text")
                            .font(.subheadline.bold())
                        Text(workout.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        // Use as template action could go here
                    } label: {
                        Label("Save as Template", systemImage: "doc.badge.plus")
                    }
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Workout?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(workout)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var headerStats: some View {
        VStack(spacing: 12) {
            // Date and duration
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.startTime.shortDateString)
                        .font(.subheadline.bold())
                    Text(workout.startTime.timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label(workout.duration.durationFormatted, systemImage: "timer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Volume stats
            HStack(spacing: 0) {
                DetailStatItem(
                    value: "\(Int(workout.totalVolume))",
                    label: "Volume (\(appState.weightUnit.rawValue))",
                    icon: "scalemass.fill", color: .blue
                )
                DetailStatItem(
                    value: "\(workout.sortedExercises.count)",
                    label: "Exercises",
                    icon: "dumbbell.fill", color: .orange
                )
                DetailStatItem(
                    value: "\(workout.totalSets)",
                    label: "Sets",
                    icon: "checkmark.circle.fill", color: .green
                )
                DetailStatItem(
                    value: "\(workout.totalReps)",
                    label: "Total Reps",
                    icon: "repeat.circle.fill", color: .purple
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DetailStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value).font(.headline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExerciseDetailCard: View {
    let workoutExercise: WorkoutExercise
    let weightUnit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise header
            HStack {
                Circle()
                    .fill(Color.forCategory(workoutExercise.exerciseCategory).opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: ExerciseCategory(rawValue: workoutExercise.exerciseCategory)?.icon ?? "dumbbell")
                            .font(.caption)
                            .foregroundStyle(Color.forCategory(workoutExercise.exerciseCategory))
                    )

                Text(workoutExercise.displayName)
                    .font(.subheadline.bold())

                Spacer()

                if let best = workoutExercise.bestSet {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Best: \(best.weight.cleanString) \(weightUnit.rawValue)")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                        Text("× \(best.reps) reps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Column headers
            HStack {
                Text("SET")
                    .frame(width: 36, alignment: .leading)
                Spacer()
                Text(weightUnit.rawValue.uppercased())
                    .frame(width: 70, alignment: .center)
                Text("REPS")
                    .frame(width: 50, alignment: .center)
                Text("VOL")
                    .frame(width: 60, alignment: .trailing)
            }
            .font(.caption2.bold())
            .foregroundStyle(.secondary)

            // Sets
            ForEach(workoutExercise.completedSets, id: \.id) { set in
                HStack {
                    SetTypeBadge(type: set.typeEnum, number: set.setNumber)
                        .frame(width: 36, alignment: .leading)
                    Spacer()
                    Text(set.weight.cleanString)
                        .font(.subheadline)
                        .frame(width: 70, alignment: .center)
                    Text("\(set.reps)")
                        .font(.subheadline)
                        .frame(width: 50, alignment: .center)
                    Text("\(Int(set.volume))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
            }

            // Volume summary
            let vol = workoutExercise.totalVolume
            if vol > 0 {
                HStack {
                    Spacer()
                    Text("Total: \(Int(vol)) \(weightUnit.rawValue)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SetTypeBadge: View {
    let type: SetType
    let number: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(badgeColor.opacity(0.2))
                .frame(width: 28, height: 28)
            if type == .normal {
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(badgeColor)
            } else {
                Text(type.badge)
                    .font(.caption2.bold())
                    .foregroundStyle(badgeColor)
            }
        }
    }

    var badgeColor: Color {
        switch type {
        case .normal: return .blue
        case .warmup: return .yellow
        case .dropSet: return .orange
        case .failure: return .red
        case .amrap: return .purple
        }
    }
}
