import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleReminder(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])

        let content = UNMutableNotificationContent()
        content.title = "Ora pentru \(habit.name)"
        content.body = "Nu uita: \(formattedTarget(for: habit)) astăzi."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = habit.reminderHour
        dateComponents.minute = habit.reminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder(habitId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habitId.uuidString])
    }

    private func formattedTarget(for habit: Habit) -> String {
        let value = habit.targetQuantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(habit.targetQuantity))
            : String(habit.targetQuantity)
        return "\(value) \(habit.unit)"
    }
}
