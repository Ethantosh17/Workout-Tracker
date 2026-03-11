import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var category: ExerciseCategory = .other
    @State private var equipment: EquipmentType = .barbell
    @State private var primaryMusclesText = ""
    @State private var secondaryMusclesText = ""
    @State private var instructions = ""

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Info") {
                    TextField("Exercise Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    Picker("Equipment", selection: $equipment) {
                        ForEach(EquipmentType.allCases, id: \.self) { eq in
                            Text(eq.rawValue).tag(eq)
                        }
                    }
                }

                Section("Muscles") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Primary Muscles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Chest, Triceps", text: $primaryMusclesText)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Secondary Muscles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("e.g. Shoulders", text: $secondaryMusclesText)
                    }
                }

                Section("Instructions (Optional)") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let primary = primaryMusclesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let secondary = secondaryMusclesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category.rawValue,
            primaryMuscles: primary,
            secondaryMuscles: secondary,
            equipment: equipment.rawValue,
            instructions: instructions,
            isCustom: true
        )
        context.insert(exercise)
        try? context.save()
        dismiss()
    }
}
