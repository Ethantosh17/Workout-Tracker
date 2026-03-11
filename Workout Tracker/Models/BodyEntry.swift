import SwiftData
import Foundation

@Model
final class BodyEntry {
    var id: UUID = UUID()
    var date: Date = Date()

    // Body composition
    var weight: Double = 0.0       // lbs or kg depending on settings
    var bodyFatPercent: Double = 0.0
    var muscleMassLbs: Double = 0.0

    // Measurements (inches or cm)
    var neck: Double = 0.0
    var shoulders: Double = 0.0
    var chest: Double = 0.0
    var leftBicep: Double = 0.0
    var rightBicep: Double = 0.0
    var leftForearm: Double = 0.0
    var rightForearm: Double = 0.0
    var waist: Double = 0.0
    var abdomen: Double = 0.0
    var hips: Double = 0.0
    var leftThigh: Double = 0.0
    var rightThigh: Double = 0.0
    var leftCalf: Double = 0.0
    var rightCalf: Double = 0.0
    var notes: String = ""

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
    }

    var hasWeightData: Bool { weight > 0 }
    var hasMeasurements: Bool {
        chest > 0 || waist > 0 || hips > 0 || leftBicep > 0 || rightBicep > 0
    }

    // Fat-free mass if body fat % set
    var fatFreeMass: Double? {
        guard bodyFatPercent > 0 && weight > 0 else { return nil }
        return weight * (1.0 - bodyFatPercent / 100.0)
    }

    var fatMass: Double? {
        guard bodyFatPercent > 0 && weight > 0 else { return nil }
        return weight * (bodyFatPercent / 100.0)
    }

    func bmi(heightCm: Double) -> Double? {
        guard heightCm > 0 && weight > 0 else { return nil }
        let weightKg = weight * 0.453592
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }
}
