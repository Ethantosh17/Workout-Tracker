import SwiftData
import Foundation

@Model
final class WorkoutTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var lastUsed: Date? = nil
    var timesUsed: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise] = []

    init(name: String, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
    }

    var sortedExercises: [TemplateExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var exerciseCount: Int { exercises.count }

    var totalTargetSets: Int {
        exercises.reduce(0) { $0 + $1.targetSets }
    }

    var estimatedDurationMinutes: Int {
        // ~3 minutes per working set (rest + set time)
        totalTargetSets * 3
    }
}

@Model
final class TemplateExercise {
    var id: UUID = UUID()
    var orderIndex: Int = 0
    var targetSets: Int = 3
    var targetReps: Int = 10
    var targetWeight: Double = 0.0
    var targetDuration: Int = 0  // seconds, for time-based
    var notes: String = ""
    var isSuperset: Bool = false
    var supersetGroup: Int = 0
    var exerciseName: String = ""

    var exercise: Exercise? = nil
    var template: WorkoutTemplate? = nil

    init(exercise: Exercise, orderIndex: Int, targetSets: Int = 3, targetReps: Int = 10, targetWeight: Double = 0) {
        self.id = UUID()
        self.exercise = exercise
        self.exerciseName = exercise.name
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
    }

    var displayName: String { exercise?.name ?? exerciseName }
}
