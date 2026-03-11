import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    @Bindable var template: WorkoutTemplate
    @Environment(AppState.self) var appState
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

    @State private var showEdit = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Start button
                Button {
                    appState.startWorkout(name: template.name, context: context, template: template)
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Stats
                HStack(spacing: 0) {
                    HistoryStatItem(value: "\(template.exerciseCount)", label: "Exercises")
                    HistoryStatItem(value: "\(template.totalTargetSets)", label: "Sets")
                    HistoryStatItem(value: "~\(template.estimatedDurationMinutes)", label: "Minutes")
                    HistoryStatItem(value: "\(template.timesUsed)", label: "Used")
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Exercises
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercises")
                        .font(.headline)

                    ForEach(template.sortedExercises) { te in
                        TemplateExerciseRow(te: te)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Notes
                if !template.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Notes", systemImage: "note.text")
                            .font(.subheadline.bold())
                        Text(template.notes)
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
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showEdit = true } label: {
                        Label("Edit Template", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("Delete Template", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Template?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(template)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showEdit) {
            TemplateEditView(template: template)
        }
    }
}

struct TemplateExerciseRow: View {
    let te: TemplateExercise

    var body: some View {
        HStack(spacing: 12) {
            Text("\(te.orderIndex + 1)")
                .font(.caption.bold())
                .frame(width: 20)
                .foregroundStyle(.secondary)

            Circle()
                .fill(Color.forCategory(te.exercise?.category ?? "").opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: ExerciseCategory(rawValue: te.exercise?.category ?? "")?.icon ?? "dumbbell")
                        .font(.caption)
                        .foregroundStyle(Color.forCategory(te.exercise?.category ?? ""))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(te.displayName)
                    .font(.subheadline.bold())
                Text("\(te.targetSets) sets × \(te.targetReps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if te.targetWeight > 0 {
                Text("\(te.targetWeight.cleanString) lbs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Template Edit View

struct TemplateEditView: View {
    let template: WorkoutTemplate?
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var exercises: [TemplateExerciseEdit] = []
    @State private var showExercisePicker = false

    struct TemplateExerciseEdit: Identifiable {
        let id = UUID()
        var exercise: Exercise
        var sets: Int = 3
        var reps: Int = 10
        var weight: Double = 0
    }

    init(template: WorkoutTemplate?) {
        self.template = template
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Info") {
                    TextField("Template Name", text: $name)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    ForEach($exercises) { $ex in
                        VStack(spacing: 8) {
                            HStack {
                                Text(ex.exercise.name)
                                    .font(.subheadline.bold())
                                Spacer()
                            }
                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    Text("Sets").font(.caption).foregroundStyle(.secondary)
                                    TextField("3", value: $ex.sets, format: .number)
                                        .keyboardType(.numberPad)
                                        .frame(width: 50)
                                        .textFieldStyle(.roundedBorder)
                                }
                                VStack(alignment: .leading) {
                                    Text("Reps").font(.caption).foregroundStyle(.secondary)
                                    TextField("10", value: $ex.reps, format: .number)
                                        .keyboardType(.numberPad)
                                        .frame(width: 50)
                                        .textFieldStyle(.roundedBorder)
                                }
                                VStack(alignment: .leading) {
                                    Text("Weight").font(.caption).foregroundStyle(.secondary)
                                    TextField("0", value: $ex.weight, format: .number)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 70)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { exercises.remove(atOffsets: $0) }
                    .onMove { from, to in exercises.move(fromOffsets: from, toOffset: to) }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Exercises")
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(name.isEmpty && exercises.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    EditButton()
                }
            }
            .onAppear { loadTemplate() }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet { exercise in
                    exercises.append(TemplateExerciseEdit(exercise: exercise))
                }
            }
        }
    }

    private func loadTemplate() {
        guard let t = template else { return }
        name = t.name
        notes = t.notes
        exercises = t.sortedExercises.compactMap { te in
            guard let ex = te.exercise else { return nil }
            return TemplateExerciseEdit(
                exercise: ex,
                sets: te.targetSets,
                reps: te.targetReps,
                weight: te.targetWeight
            )
        }
    }

    private func save() {
        let finalName = name.isEmpty ? "My Template" : name
        if let t = template {
            t.name = finalName
            t.notes = notes
            // Remove old exercises
            for te in t.exercises { context.delete(te) }
            addExercises(to: t)
        } else {
            let newTemplate = WorkoutTemplate(name: finalName, notes: notes)
            context.insert(newTemplate)
            addExercises(to: newTemplate)
        }
        try? context.save()
        dismiss()
    }

    private func addExercises(to t: WorkoutTemplate) {
        for (i, ex) in exercises.enumerated() {
            let te = TemplateExercise(
                exercise: ex.exercise,
                orderIndex: i,
                targetSets: ex.sets,
                targetReps: ex.reps,
                targetWeight: ex.weight
            )
            te.template = t
            context.insert(te)
        }
    }
}
