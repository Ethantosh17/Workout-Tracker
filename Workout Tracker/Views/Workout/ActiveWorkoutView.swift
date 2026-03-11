import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var vm: ActiveWorkoutViewModel
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var context

    @State private var showExercisePicker = false
    @State private var showFinishAlert = false
    @State private var showDiscardAlert = false
    @State private var showPlateCalc = false
    @State private var workoutName: String = ""

    init(vm: ActiveWorkoutViewModel) {
        self._vm = Bindable(vm)
        self._workoutName = State(initialValue: vm.workout.name)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                exerciseList

                // Rest Timer overlay
                if vm.restTimerActive {
                    VStack {
                        Spacer()
                        RestTimerOverlay(vm: vm, defaultRestTime: appState.defaultRestTime)
                            .padding(.bottom, 8)
                    }
                    .animation(.spring(), value: vm.restTimerActive)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet { exercise in
                    vm.addExercise(exercise, context: context)
                }
            }
            .sheet(isPresented: $showPlateCalc) {
                PlateCalculatorView()
                    .presentationDetents([.medium, .large])
            }
            .alert("Finish Workout?", isPresented: $showFinishAlert) {
                Button("Finish", role: .destructive) { appState.finishWorkout(context: context) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will save your workout and end the session.")
            }
            .alert("Discard Workout?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { appState.discardWorkout(context: context) }
                Button("Keep Training", role: .cancel) {}
            } message: {
                Text("All progress will be lost.")
            }
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        List {
            // Workout header
            Section {
                workoutHeaderRow
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Exercises
            ForEach(vm.workout.sortedExercises) { workoutExercise in
                Section {
                    ExerciseSection(
                        workoutExercise: workoutExercise,
                        vm: vm,
                        weightUnit: appState.weightUnit
                    )
                } header: {
                    ExerciseSectionHeader(
                        workoutExercise: workoutExercise,
                        onDelete: { vm.removeExercise(workoutExercise, context: context) }
                    )
                }
            }
            .onMove { from, to in vm.moveExercise(from: from, to: to) }

            // Add Exercise
            Section {
                Button {
                    showExercisePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Add Exercise")
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Bottom padding for rest timer
            Section { Color.clear.frame(height: vm.restTimerActive ? 160 : 0) }
                .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Workout Header

    private var workoutHeaderRow: some View {
        HStack(spacing: 16) {
            // Timer
            VStack(spacing: 2) {
                Image(systemName: vm.isRunning ? "timer" : "pause.circle")
                    .foregroundStyle(.orange)
                Text(vm.elapsedFormatted)
                    .font(.headline.monospacedDigit())
                Text("Duration")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .onTapGesture { vm.toggleTimer() }

            Divider().frame(height: 40)

            VStack(spacing: 2) {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.blue)
                Text("\(vm.workout.exercises.count)")
                    .font(.headline)
                Text("Exercises")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider().frame(height: 40)

            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(vm.workout.totalSets)")
                    .font(.headline)
                Text("Sets Done")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider().frame(height: 40)

            VStack(spacing: 2) {
                Image(systemName: "scalemass.fill")
                    .foregroundStyle(.purple)
                Text("\(Int(vm.workout.totalVolume))")
                    .font(.headline)
                Text("Volume")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button(role: .destructive) { showDiscardAlert = true } label: {
                    Label("Discard Workout", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }

        ToolbarItem(placement: .principal) {
            TextField("Workout Name", text: $workoutName)
                .font(.headline)
                .multilineTextAlignment(.center)
                .onSubmit { vm.workout.name = workoutName }
                .onChange(of: workoutName) { _, new in vm.workout.name = new }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack {
                if appState.showPlateCalculatorButton {
                    Button { showPlateCalc = true } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                }
                Button {
                    showFinishAlert = true
                } label: {
                    Text("Finish")
                        .bold()
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - Exercise Section Header

struct ExerciseSectionHeader: View {
    let workoutExercise: WorkoutExercise
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(Color.forCategory(workoutExercise.exerciseCategory).opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: categoryIcon(workoutExercise.exerciseCategory))
                        .font(.caption)
                        .foregroundStyle(Color.forCategory(workoutExercise.exerciseCategory))
                )

            Text(workoutExercise.displayName)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .textCase(nil)
    }

    func categoryIcon(_ category: String) -> String {
        ExerciseCategory(rawValue: category)?.icon ?? "dumbbell"
    }
}

// MARK: - Exercise Section

struct ExerciseSection: View {
    let workoutExercise: WorkoutExercise
    @Bindable var vm: ActiveWorkoutViewModel
    let weightUnit: WeightUnit
    @Environment(\.modelContext) var context

    var body: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Text("SET")
                    .frame(width: 36)
                Text("PREV")
                    .frame(maxWidth: .infinity)
                Text(weightUnit.rawValue.uppercased())
                    .frame(width: 72)
                Text("REPS")
                    .frame(width: 56)
                Spacer().frame(width: 36)
            }
            .font(.caption2.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            ForEach(workoutExercise.sortedSets) { set in
                SetRow(
                    set: set,
                    setIndex: workoutExercise.sortedSets.firstIndex(of: set) ?? 0,
                    workoutExercise: workoutExercise,
                    vm: vm,
                    weightUnit: weightUnit
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        vm.removeSet(set, context: context)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            // Add Set
            Button {
                vm.addSet(to: workoutExercise, context: context)
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.caption)
                    Text("Add Set")
                        .font(.subheadline)
                }
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Set Row

struct SetRow: View {
    @Bindable var set: WorkoutSet
    let setIndex: Int
    let workoutExercise: WorkoutExercise
    @Bindable var vm: ActiveWorkoutViewModel
    let weightUnit: WeightUnit

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var showTypeMenu = false

    var body: some View {
        HStack(spacing: 4) {
            // Set type badge
            Menu {
                ForEach(SetType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        set.setType = type.rawValue
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(badgeColor(for: set.typeEnum).opacity(0.2))
                    Text(set.typeEnum.badge)
                        .font(.caption2.bold())
                        .foregroundStyle(badgeColor(for: set.typeEnum))
                }
                .frame(width: 32, height: 32)
            }

            // Previous performance
            Text(previousText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .lineLimit(1)

            // Weight field
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 68)
                .padding(.vertical, 6)
                .background(set.isCompleted ? Color.green.opacity(0.15) : Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onAppear { weightText = set.weight == 0 ? "" : set.weight.cleanString }
                .onChange(of: weightText) { _, new in
                    if let v = Double(new) { set.weight = v }
                }

            // Reps field
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 52)
                .padding(.vertical, 6)
                .background(set.isCompleted ? Color.green.opacity(0.15) : Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onAppear { repsText = set.reps == 0 ? "" : "\(set.reps)" }
                .onChange(of: repsText) { _, new in
                    if let v = Int(new) { set.reps = v }
                }

            // Done button
            Button {
                if set.isCompleted {
                    vm.uncompleteSet(set)
                } else {
                    vm.completeSet(set)
                }
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : Color(.systemGray3))
                    .font(.title3)
            }
            .frame(width: 36)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(set.isCompleted ? Color.green.opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
    }

    private var previousText: String {
        // Look at last workout for this exercise
        if let exercise = workoutExercise.exercise {
            let prevSets = exercise.workoutExercises?
                .filter { $0.workout?.id != workoutExercise.workout?.id }
                .sorted { ($0.workout?.startTime ?? .distantPast) > ($1.workout?.startTime ?? .distantPast) }
                .first?.completedSets ?? []

            if setIndex < prevSets.count {
                let prev = prevSets[setIndex]
                return "\(prev.weight.cleanString) × \(prev.reps)"
            }
        }
        return "—"
    }

    private func badgeColor(for type: SetType) -> Color {
        switch type {
        case .normal: return .blue
        case .warmup: return .yellow
        case .dropSet: return .orange
        case .failure: return .red
        case .amrap: return .purple
        }
    }
}

// MARK: - Exercise Picker Sheet

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Exercise.name) var exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    @State private var search = ""
    @State private var selectedCategory: String = "All"

    var filtered: [Exercise] {
        var result = exercises
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }
        if !search.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(search) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPicker

                List(filtered) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        ExercisePickerRow(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(label: "All", isSelected: selectedCategory == "All") {
                    selectedCategory = "All"
                }
                ForEach(ExerciseCategory.allCases, id: \.rawValue) { cat in
                    CategoryChip(label: cat.rawValue, isSelected: selectedCategory == cat.rawValue) {
                        selectedCategory = cat.rawValue
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct ExercisePickerRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.forCategory(exercise.category).opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: ExerciseCategory(rawValue: exercise.category)?.icon ?? "dumbbell")
                        .font(.caption)
                        .foregroundStyle(Color.forCategory(exercise.category))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text(exercise.primaryMuscles.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !exercise.equipment.isEmpty {
                        Text("• \(exercise.equipment)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// Fix: extend WorkoutExercise for optional backward relationship access
private extension Exercise {
    var workoutExercises: [WorkoutExercise]? { nil }
}
