import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedEquipment: String = "All"
    @State private var showAddExercise = false
    @State private var showFilters = false

    var filtered: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.primaryMuscles.joined().localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All" || exercise.category == selectedCategory
            let matchesEquipment = selectedEquipment == "All" || exercise.equipment == selectedEquipment
            return matchesSearch && matchesCategory && matchesEquipment
        }
    }

    var grouped: [(String, [Exercise])] {
        let g = Dictionary(grouping: filtered) { $0.category }
        return g.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                categoryFilter

                List {
                    ForEach(grouped, id: \.0) { category, exList in
                        Section(category) {
                            ForEach(exList) { exercise in
                                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                    ExercisePickerRow(exercise: exercise)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .searchable(text: $searchText, prompt: "Search \(exercises.count) exercises")
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedEquipment != "All" {
                        Button {
                            selectedEquipment = "All"
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                Text(selectedEquipment)
                                    .font(.caption)
                            }
                            .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView()
            }
            .sheet(isPresented: $showFilters) {
                equipmentFilterSheet
            }
        }
    }

    private var categoryFilter: some View {
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
                // Equipment filter
                Button {
                    showFilters = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Equipment")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(selectedEquipment != "All" ? Color.orange : Color(.systemGray5))
                    .foregroundStyle(selectedEquipment != "All" ? .white : .primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var equipmentFilterSheet: some View {
        NavigationStack {
            List {
                Button { selectedEquipment = "All" } label: {
                    HStack {
                        Text("All Equipment")
                        Spacer()
                        if selectedEquipment == "All" {
                            Image(systemName: "checkmark").foregroundStyle(.orange)
                        }
                    }
                }
                .foregroundStyle(.primary)
                ForEach(EquipmentType.allCases, id: \.rawValue) { eq in
                    Button { selectedEquipment = eq.rawValue } label: {
                        HStack {
                            Text(eq.rawValue)
                            Spacer()
                            if selectedEquipment == eq.rawValue {
                                Image(systemName: "checkmark").foregroundStyle(.orange)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Filter by Equipment")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
