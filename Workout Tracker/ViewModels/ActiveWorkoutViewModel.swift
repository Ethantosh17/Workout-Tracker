import Foundation
import Observation
import SwiftData
import SwiftUI

@Observable
class ActiveWorkoutViewModel {
    var workout: Workout
    var elapsedSeconds: Int = 0
    var isRunning: Bool = true

    // Rest timer
    var restSecondsRemaining: Int = 0
    var restTimerActive: Bool = false
    var restTimerInitial: Int = 0

    private var workoutTimer: Timer?
    private var restTimer: Timer?
    private weak var appState: AppState?

    init(workout: Workout, appState: AppState) {
        self.workout = workout
        self.appState = appState
        startWorkoutTimer()
    }

    func stopTimers() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        restTimer?.invalidate()
        restTimer = nil
    }

    // MARK: - Workout Timer

    private func startWorkoutTimer() {
        isRunning = true
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    func toggleTimer() {
        if isRunning {
            isRunning = false
            workoutTimer?.invalidate()
            workoutTimer = nil
        } else {
            startWorkoutTimer()
        }
    }

    var elapsedFormatted: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int) {
        restTimer?.invalidate()
        restTimerInitial = seconds
        restSecondsRemaining = seconds
        restTimerActive = true
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.restSecondsRemaining > 0 {
                self.restSecondsRemaining -= 1
            } else {
                self.restTimerActive = false
                self.restTimer?.invalidate()
                self.restTimer = nil
            }
        }
    }

    func skipRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restSecondsRemaining = 0
    }

    func addRestTime(_ extra: Int) {
        restSecondsRemaining = min(restSecondsRemaining + extra, 600)
    }

    var restProgress: Double {
        guard restTimerInitial > 0 else { return 1 }
        return Double(restSecondsRemaining) / Double(restTimerInitial)
    }

    var restFormatted: String {
        String(format: "%d:%02d", restSecondsRemaining / 60, restSecondsRemaining % 60)
    }

    // MARK: - Exercise Management

    func addExercise(_ exercise: Exercise, context: ModelContext) {
        let orderIndex = workout.exercises.count
        let we = WorkoutExercise(exercise: exercise, orderIndex: orderIndex)
        we.workout = workout
        context.insert(we)

        let defaultReps = appState?.repsDefault ?? 10

        // Warmup set
        let numWarmups = appState?.warmupSetsDefault ?? 1
        for i in 0..<numWarmups {
            let wu = WorkoutSet(setNumber: i + 1, reps: defaultReps, weight: 0, type: .warmup)
            wu.workoutExercise = we
            context.insert(wu)
        }

        // Working sets
        let numSets = appState?.workingSetsDefault ?? 3
        for i in 0..<numSets {
            let s = WorkoutSet(setNumber: numWarmups + i + 1, reps: defaultReps, weight: 0, type: .normal)
            s.workoutExercise = we
            context.insert(s)
        }
    }

    func addSet(to we: WorkoutExercise, context: ModelContext) {
        let last = we.sortedSets.last
        let nextNum = (we.sets.map(\.setNumber).max() ?? 0) + 1
        let set = WorkoutSet(
            setNumber: nextNum,
            reps: last?.reps ?? (appState?.repsDefault ?? 10),
            weight: last?.weight ?? 0,
            type: last?.typeEnum == .warmup ? .normal : (last?.typeEnum ?? .normal)
        )
        set.workoutExercise = we
        context.insert(set)
    }

    func removeSet(_ set: WorkoutSet, context: ModelContext) {
        context.delete(set)
    }

    func removeExercise(_ we: WorkoutExercise, context: ModelContext) {
        context.delete(we)
    }

    func completeSet(_ set: WorkoutSet) {
        set.isCompleted = true
        if let restTime = appState?.defaultRestTime, restTime > 0 {
            startRestTimer(seconds: restTime)
        }
        NotificationService.shared.scheduleRestTimerNotification(seconds: appState?.defaultRestTime ?? 90)
    }

    func uncompleteSet(_ set: WorkoutSet) {
        set.isCompleted = false
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        var sorted = workout.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        for (i, exercise) in sorted.enumerated() {
            exercise.orderIndex = i
        }
    }

    // MARK: - Previous Performance

    func previousBestWeight(for exerciseName: String, context: ModelContext) -> Double? {
        // Look up in PersonalRecords
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { pr in
                pr.exerciseName == exerciseName && pr.metric == "Max Weight"
            },
            sortBy: [SortDescriptor(\.value, order: .reverse)]
        )
        return try? context.fetch(descriptor).first.map(\.value)
    }
}
