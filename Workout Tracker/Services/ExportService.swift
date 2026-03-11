import Foundation
import SwiftData

enum ExportService {
    static func exportWorkoutsCSV(workouts: [Workout]) -> String {
        var lines = ["Date,Workout Name,Duration (min),Total Volume,Exercises,Sets,Reps,Notes"]
        for w in workouts.sorted(by: { $0.startTime > $1.startTime }) {
            guard w.isCompleted else { continue }
            let date = w.startTime.shortDateString
            let name = w.name.csvEscaped
            let duration = String(format: "%.0f", w.duration / 60)
            let volume = w.totalVolume.cleanString
            let exerciseNames = w.sortedExercises.map(\.displayName).joined(separator: "; ").csvEscaped
            let sets = w.totalSets
            let reps = w.totalReps
            let notes = w.notes.csvEscaped
            lines.append("\(date),\(name),\(duration),\(volume),\(exerciseNames),\(sets),\(reps),\(notes)")
        }
        return lines.joined(separator: "\n")
    }

    static func exportBodyEntriesCSV(entries: [BodyEntry]) -> String {
        var lines = ["Date,Weight,Body Fat %,Muscle Mass,Neck,Shoulders,Chest,Left Bicep,Right Bicep,Waist,Abdomen,Hips,Left Thigh,Right Thigh,Left Calf,Right Calf,Notes"]
        for e in entries.sorted(by: { $0.date > $1.date }) {
            let row = [
                e.date.shortDateString,
                e.weight.csvNum, e.bodyFatPercent.csvNum, e.muscleMassLbs.csvNum,
                e.neck.csvNum, e.shoulders.csvNum, e.chest.csvNum,
                e.leftBicep.csvNum, e.rightBicep.csvNum,
                e.waist.csvNum, e.abdomen.csvNum, e.hips.csvNum,
                e.leftThigh.csvNum, e.rightThigh.csvNum,
                e.leftCalf.csvNum, e.rightCalf.csvNum,
                e.notes.csvEscaped
            ]
            lines.append(row.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func exportPRsCSV(prs: [PersonalRecord]) -> String {
        var lines = ["Exercise,Metric,Value,Reps,Date,Workout"]
        for pr in prs.sorted(by: { $0.date > $1.date }) {
            let row = [
                pr.exerciseName.csvEscaped,
                pr.metric,
                pr.value.cleanString,
                String(pr.reps),
                pr.date.shortDateString,
                pr.workoutName.csvEscaped
            ]
            lines.append(row.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func writeToTemporaryFile(content: String, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

private extension String {
    var csvEscaped: String {
        if contains(",") || contains("\"") || contains("\n") {
            return "\"" + replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return self
    }
}

private extension Double {
    var csvNum: String { self == 0 ? "" : cleanString }
}
