import Foundation
import Observation
import SwiftData

enum WeightUnit: String, CaseIterable {
    case lbs = "lbs"
    case kg = "kg"

    func toKg(_ value: Double) -> Double {
        self == .kg ? value : value * 0.453592
    }
    func toLbs(_ value: Double) -> Double {
        self == .lbs ? value : value * 2.20462
    }
    func convert(_ value: Double, to target: WeightUnit) -> Double {
        if self == target { return value }
        return target == .kg ? toKg(value) : toLbs(value)
    }
    func display(_ value: Double) -> String {
        let v = value.truncatingRemainder(dividingBy: 1) == 0
        return String(format: v ? "%.0f %@" : "%.1f %@", value, rawValue)
    }
    func format(_ value: Double) -> String {
        let v = value.truncatingRemainder(dividingBy: 1) == 0
        return String(format: v ? "%.0f" : "%.1f", value)
    }
}

enum MeasurementUnit: String, CaseIterable {
    case imperial = "Imperial (in / lbs)"
    case metric = "Metric (cm / kg)"
    var lengthLabel: String { self == .metric ? "cm" : "in" }
}

@Observable
class AppState {
    // Active workout
    var activeWorkoutVM: ActiveWorkoutViewModel? = nil
    var isWorkoutActive: Bool { activeWorkoutVM != nil }
    var showingActiveWorkout: Bool = false

    // Settings
    var weightUnit: WeightUnit = .lbs
    var measurementUnit: MeasurementUnit = .imperial
    var defaultRestTime: Int = 90
    var useRestTimerNotifications: Bool = true
    var heightCm: Double = 0
    var warmupSetsDefault: Int = 1
    var workingSetsDefault: Int = 3
    var repsDefault: Int = 10
    var showPlateCalculatorButton: Bool = true
    var theme: String = "system"

    init() { loadSettings() }

    func saveSettings() {
        let d = UserDefaults.standard
        d.set(weightUnit.rawValue, forKey: "weightUnit")
        d.set(measurementUnit.rawValue, forKey: "measurementUnit")
        d.set(defaultRestTime, forKey: "defaultRestTime")
        d.set(useRestTimerNotifications, forKey: "useRestTimerNotifications")
        d.set(heightCm, forKey: "heightCm")
        d.set(warmupSetsDefault, forKey: "warmupSetsDefault")
        d.set(workingSetsDefault, forKey: "workingSetsDefault")
        d.set(repsDefault, forKey: "repsDefault")
        d.set(showPlateCalculatorButton, forKey: "showPlateCalculatorButton")
        d.set(theme, forKey: "theme")
    }

    func loadSettings() {
        let d = UserDefaults.standard
        if let wu = d.string(forKey: "weightUnit"), let u = WeightUnit(rawValue: wu) { weightUnit = u }
        if let mu = d.string(forKey: "measurementUnit"), let u = MeasurementUnit(rawValue: mu) { measurementUnit = u }
        defaultRestTime = d.integer(forKey: "defaultRestTime").nonZero(fallback: 90)
        useRestTimerNotifications = d.object(forKey: "useRestTimerNotifications") as? Bool ?? true
        heightCm = d.double(forKey: "heightCm")
        warmupSetsDefault = d.integer(forKey: "warmupSetsDefault").nonZero(fallback: 1)
        workingSetsDefault = d.integer(forKey: "workingSetsDefault").nonZero(fallback: 3)
        repsDefault = d.integer(forKey: "repsDefault").nonZero(fallback: 10)
        showPlateCalculatorButton = d.object(forKey: "showPlateCalculatorButton") as? Bool ?? true
        theme = d.string(forKey: "theme") ?? "system"
    }

    // MARK: - Workout lifecycle

    func startWorkout(name: String, context: ModelContext, template: WorkoutTemplate? = nil) {
        let workout = Workout(
            name: name,
            templateId: template?.id,
            templateName: template?.name ?? ""
        )
        context.insert(workout)

        if let template = template {
            for te in template.sortedExercises {
                guard let exercise = te.exercise else { continue }
                let we = WorkoutExercise(exercise: exercise, orderIndex: te.orderIndex)
                we.workout = workout
                context.insert(we)

                // Warmup set
                let wu = WorkoutSet(setNumber: 1, reps: te.targetReps, weight: 0, type: .warmup)
                wu.workoutExercise = we
                context.insert(wu)

                // Working sets
                for i in 0..<te.targetSets {
                    let s = WorkoutSet(setNumber: i + 2, reps: te.targetReps, weight: te.targetWeight, type: .normal)
                    s.workoutExercise = we
                    context.insert(s)
                }
            }
            template.timesUsed += 1
            template.lastUsed = Date()
        }

        activeWorkoutVM = ActiveWorkoutViewModel(workout: workout, appState: self)
        showingActiveWorkout = true
    }

    func finishWorkout(context: ModelContext) {
        guard let vm = activeWorkoutVM else { return }
        vm.workout.endTime = Date()
        vm.stopTimers()

        // Prune incomplete sets and empty exercises
        for exercise in vm.workout.exercises {
            for set in exercise.sets where !set.isCompleted {
                context.delete(set)
            }
        }
        for exercise in vm.workout.exercises where exercise.completedSets.isEmpty {
            context.delete(exercise)
        }

        try? context.save()
        activeWorkoutVM = nil
        showingActiveWorkout = false
    }

    func discardWorkout(context: ModelContext) {
        guard let vm = activeWorkoutVM else { return }
        vm.stopTimers()
        context.delete(vm.workout)
        try? context.save()
        activeWorkoutVM = nil
        showingActiveWorkout = false
    }
}

private extension Int {
    func nonZero(fallback: Int) -> Int { self == 0 ? fallback : self }
}
