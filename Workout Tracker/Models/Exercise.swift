import SwiftData
import Foundation

@Model
final class Exercise {
    var id: UUID = UUID()
    var name: String = ""
    var category: String = ""
    var primaryMuscles: [String] = []
    var secondaryMuscles: [String] = []
    var equipment: String = ""
    var instructions: String = ""
    var isCustom: Bool = false
    var createdAt: Date = Date()

    init(
        name: String,
        category: String,
        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        equipment: String = "Barbell",
        instructions: String = "",
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.instructions = instructions
        self.isCustom = isCustom
        self.createdAt = Date()
    }
}

enum ExerciseCategory: String, CaseIterable, Codable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    case other = "Other"

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.strengthtraining.functional"
        case .shoulders: return "bolt.horizontal"
        case .arms: return "figure.arms.open"
        case .legs: return "figure.walk"
        case .core: return "circle.grid.cross.fill"
        case .cardio: return "heart.fill"
        case .fullBody: return "figure.mixed.cardio"
        case .other: return "ellipsis.circle"
        }
    }

    var color: String {
        switch self {
        case .chest: return "red"
        case .back: return "blue"
        case .shoulders: return "purple"
        case .arms: return "orange"
        case .legs: return "green"
        case .core: return "yellow"
        case .cardio: return "pink"
        case .fullBody: return "teal"
        case .other: return "secondary"
        }
    }
}

enum EquipmentType: String, CaseIterable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case cable = "Cable"
    case machine = "Machine"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case bands = "Resistance Bands"
    case cardioMachine = "Cardio Machine"
    case other = "Other"
}
