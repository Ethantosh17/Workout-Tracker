import Foundation

// MARK: - Plate Calculator

struct PlateCalculator {
    static let barWeightLbs: Double = 45
    static let barWeightKg: Double = 20

    // Standard plate weights (per side)
    static let availablePlatesLbs: [Double] = [45, 35, 25, 10, 5, 2.5, 1.25]
    static let availablePlatesKg: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    struct PlateResult {
        let plates: [Double]        // per side
        let totalWeight: Double
        let remainder: Double       // weight that can't be loaded
        let unit: WeightUnit
    }

    static func calculate(targetWeight: Double, unit: WeightUnit) -> PlateResult {
        let barWeight = unit == .lbs ? barWeightLbs : barWeightKg
        let availablePlates = unit == .lbs ? availablePlatesLbs : availablePlatesKg

        guard targetWeight > barWeight else {
            return PlateResult(plates: [], totalWeight: barWeight, remainder: 0, unit: unit)
        }

        var weightPerSide = (targetWeight - barWeight) / 2.0
        var plates: [Double] = []

        for plate in availablePlates {
            while weightPerSide >= plate {
                plates.append(plate)
                weightPerSide -= plate
                weightPerSide = (weightPerSide * 10).rounded() / 10  // avoid float drift
            }
        }

        let loadedPerSide = plates.reduce(0, +)
        let total = barWeight + loadedPerSide * 2
        let remainder = (weightPerSide * 10).rounded() / 10

        return PlateResult(plates: plates, totalWeight: total, remainder: remainder, unit: unit)
    }

    // Common barbell weights for quick reference
    static func commonWeights(unit: WeightUnit) -> [Double] {
        if unit == .lbs {
            return [45, 95, 135, 155, 185, 205, 225, 245, 275, 315, 365, 405]
        } else {
            return [20, 40, 60, 80, 100, 120, 140, 160, 180, 200]
        }
    }
}
