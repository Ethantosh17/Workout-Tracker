import SwiftData
import Foundation

@Model
final class Workout {
    var id: UUID = UUID()
    var name: String = ""
    var startTime: Date = Date()
    var endTime: Date? = nil
    var notes: String = ""
    var templateId: UUID? = nil
    var templateName: String = ""

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise] = []

    init(name: String = "Workout", templateId: UUID? = nil, templateName: String = "") {
        self.id = UUID()
        self.name = name
        self.startTime = Date()
        self.templateId = templateId
        self.templateName = templateName
    }

    var duration: TimeInterval {
        guard let end = endTime else { return Date().timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }

    var totalVolume: Double {
        exercises.flatMap { $0.sets }.filter { $0.isCompleted }.reduce(0.0) {
            $0 + ($1.weight * Double($1.reps))
        }
    }

    var totalSets: Int {
        exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }

    var totalReps: Int {
        exercises.flatMap { $0.sets }.filter { $0.isCompleted }.reduce(0) { $0 + $1.reps }
    }

    var sortedExercises: [WorkoutExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var isCompleted: Bool { endTime != nil }
}

// MARK: - WorkoutExercise

@Model
final class WorkoutExercise {
    var id: UUID = UUID()
    var orderIndex: Int = 0
    var notes: String = ""
    var isSuperset: Bool = false
    var supersetGroup: Int = 0
    var exerciseName: String = ""
    var exerciseCategory: String = ""

    var exercise: Exercise? = nil
    var workout: Workout? = nil

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet] = []

    init(exercise: Exercise, orderIndex: Int) {
        self.id = UUID()
        self.exercise = exercise
        self.exerciseName = exercise.name
        self.exerciseCategory = exercise.category
        self.orderIndex = orderIndex
    }

    var sortedSets: [WorkoutSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    var completedSets: [WorkoutSet] {
        sets.filter { $0.isCompleted }.sorted { $0.setNumber < $1.setNumber }
    }

    var displayName: String { exercise?.name ?? exerciseName }

    var totalVolume: Double {
        completedSets.reduce(0.0) { $0 + $1.volume }
    }

    var bestSet: WorkoutSet? {
        completedSets.max { $0.weight < $1.weight }
    }
}

// MARK: - WorkoutSet

@Model
final class WorkoutSet {
    var id: UUID = UUID()
    var setNumber: Int = 1
    var reps: Int = 0
    var weight: Double = 0.0
    var setType: String = SetType.normal.rawValue
    var isCompleted: Bool = false
    var rpe: Double = 0.0
    var durationSeconds: Int = 0
    var distanceMeters: Double = 0.0
    var notes: String = ""

    var workoutExercise: WorkoutExercise? = nil

    init(setNumber: Int, reps: Int = 0, weight: Double = 0.0, type: SetType = .normal) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.setType = type.rawValue
    }

    var estimatedOneRepMax: Double {
        guard reps > 0 && weight > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0) // Epley formula
    }

    var volume: Double { weight * Double(reps) }

    var typeEnum: SetType {
        SetType(rawValue: setType) ?? .normal
    }
}

enum SetType: String, CaseIterable {
    case normal = "Normal"
    case warmup = "Warm-up"
    case dropSet = "Drop Set"
    case failure = "To Failure"
    case amrap = "AMRAP"

    var badge: String {
        switch self {
        case .normal: return "N"
        case .warmup: return "W"
        case .dropSet: return "D"
        case .failure: return "F"
        case .amrap: return "A"
        }
    }

    var badgeColor: String {
        switch self {
        case .normal: return "blue"
        case .warmup: return "yellow"
        case .dropSet: return "orange"
        case .failure: return "red"
        case .amrap: return "purple"
        }
    }
}
