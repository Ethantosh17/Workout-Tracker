import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let restTimerIdentifier = "com.workouttracker.resttimer"

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleRestTimerNotification(seconds: Int) {
        cancelRestTimerNotification()
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time to hit your next set! 💪"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: restTimerIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [restTimerIdentifier])
    }

    func scheduleWorkoutReminder(hour: Int, minute: Int) {
        let identifier = "com.workouttracker.reminder"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Workout Time 🏋️"
        content.body = "Don't skip today's session. You've got this!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
