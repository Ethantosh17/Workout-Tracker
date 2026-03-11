import SwiftData
import Foundation

@Model
final class PersonalRecord {
    var id: UUID = UUID()
    var exerciseName: String = ""
    var exerciseIdString: String = ""   // UUID stored as string (avoids SwiftData issues)
    var metric: String = PRMetric.maxWeight.rawValue
    var value: Double = 0.0
    var reps: Int = 0
    var date: Date = Date()
    var workoutName: String = ""

    init(
        exerciseName: String,
        exerciseId: UUID,
        metric: PRMetric,
        value: Double,
        reps: Int = 0,
        workoutName: String
    ) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.exerciseIdString = exerciseId.uuidString
        self.metric = metric.rawValue
        self.value = value
        self.reps = reps
        self.date = Date()
        self.workoutName = workoutName
    }

    var metricEnum: PRMetric { PRMetric(rawValue: metric) ?? .maxWeight }
    var exerciseId: UUID { UUID(uuidString: exerciseIdString) ?? UUID() }
}

enum PRMetric: String, CaseIterable {
    case maxWeight = "Max Weight"
    case estimatedOneRepMax = "Est. 1RM"
    case maxReps = "Max Reps"
    case maxVolume = "Max Set Volume"
    case maxSessionVolume = "Max Session Volume"

    var icon: String {
        switch self {
        case .maxWeight: return "scalemass.fill"
        case .estimatedOneRepMax: return "chart.bar.fill"
        case .maxReps: return "repeat.circle.fill"
        case .maxVolume: return "cube.fill"
        case .maxSessionVolume: return "sum"
        }
    }

    var unit: String {
        switch self {
        case .maxWeight, .estimatedOneRepMax, .maxVolume, .maxSessionVolume: return "lbs"
        case .maxReps: return "reps"
        }
    }
}
