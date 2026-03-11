import SwiftUI
import Foundation

// MARK: - TimeInterval

extension TimeInterval {
    var durationFormatted: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    var shortDurationFormatted: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 { return String(format: "%dh %dm", hours, minutes) }
        return String(format: "%dm", minutes)
    }
}

// MARK: - Date

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: self) ?? self
    }

    var weekdayName: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: self)
    }

    var shortDateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: self)
    }

    var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: self)
    }

    var relativeString: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: self, relativeTo: Date())
    }

    var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: self)
    }
}

// MARK: - Double

extension Double {
    var cleanString: String {
        self.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }

    var isZero: Bool { self == 0 }
}

// MARK: - Color from category

extension Color {
    static func forCategory(_ category: String) -> Color {
        switch category {
        case "Chest": return .red
        case "Back": return .blue
        case "Shoulders": return .purple
        case "Arms": return .orange
        case "Legs": return .green
        case "Core": return .yellow
        case "Cardio": return .pink
        case "Full Body": return .teal
        default: return .secondary
        }
    }
}

// MARK: - View helpers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Collection

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
