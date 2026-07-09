import SwiftUI

enum HabitColor: String, CaseIterable, Identifiable, Codable, Hashable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        }
    }
}

enum HabitPalette {
    /// Curated SF Symbols that cover common habit categories.
    static let icons: [String] = [
        "drop.fill", "figure.run", "figure.walk", "bicycle",
        "book.fill", "book.closed.fill", "pencil",
        "bed.double.fill", "moon.stars.fill", "sun.max.fill",
        "cup.and.saucer.fill", "fork.knife", "leaf.fill",
        "pills.fill", "heart.fill", "brain.head.profile",
        "dumbbell.fill", "figure.mind.and.body", "flame.fill",
        "wind", "music.note", "cart.fill", "house.fill",
        "banknote.fill", "checkmark.seal.fill", "sparkles",
        "paintbrush.fill", "camera.fill", "gamecontroller.fill",
        "phone.down.fill"
    ]
}

struct Habit: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var colorName: HabitColor
    var targetQuantity: Double
    var unit: String
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorName: HabitColor,
        targetQuantity: Double,
        unit: String,
        reminderEnabled: Bool = false,
        reminderHour: Int = 20,
        reminderMinute: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.targetQuantity = targetQuantity
        self.unit = unit
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.createdAt = createdAt
    }

    var color: Color { colorName.color }
}

@MainActor
final class HabitStore: ObservableObject {
    @Published private(set) var habits: [Habit] = []
    /// habitId -> "yyyy-MM-dd" -> logged amount for that day
    @Published private(set) var entries: [UUID: [String: Double]] = [:]

    private let defaults = UserDefaults.standard
    private let habitsKey = "habits.v1"
    private let entriesKey = "habitEntries.v1"

    static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init() {
        load()
    }

    // MARK: - CRUD

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        save()
        if habit.reminderEnabled {
            NotificationManager.shared.scheduleReminder(for: habit)
        }
    }

    func updateHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index] = habit
        save()
        NotificationManager.shared.cancelReminder(habitId: habit.id)
        if habit.reminderEnabled {
            NotificationManager.shared.scheduleReminder(for: habit)
        }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        entries.removeValue(forKey: habit.id)
        save()
        NotificationManager.shared.cancelReminder(habitId: habit.id)
    }

    // MARK: - Progress

    func amount(for habit: Habit, on date: Date = Date()) -> Double {
        entries[habit.id]?[Self.dateKeyFormatter.string(from: date)] ?? 0
    }

    func setAmount(_ amount: Double, for habit: Habit, on date: Date = Date()) {
        let key = Self.dateKeyFormatter.string(from: date)
        var dayMap = entries[habit.id] ?? [:]
        if amount <= 0 {
            dayMap.removeValue(forKey: key)
        } else {
            dayMap[key] = amount
        }
        entries[habit.id] = dayMap
        save()
    }

    func addAmount(_ delta: Double, for habit: Habit, on date: Date = Date()) {
        setAmount(max(0, amount(for: habit, on: date) + delta), for: habit, on: date)
    }

    func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        habit.targetQuantity > 0 && amount(for: habit, on: date) >= habit.targetQuantity
    }

    func progressFraction(for habit: Habit, on date: Date = Date()) -> Double {
        guard habit.targetQuantity > 0 else { return 0 }
        return min(amount(for: habit, on: date) / habit.targetQuantity, 1)
    }

    // MARK: - Streaks

    /// Consecutive completed days ending today. A day still in progress
    /// doesn't break a streak earned through yesterday.
    func currentStreak(for habit: Habit, today: Date = Date()) -> Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: today)

        if !isCompleted(habit, on: day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while isCompleted(habit, on: day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    func bestStreak(for habit: Habit) -> Int {
        guard habit.targetQuantity > 0, let dayMap = entries[habit.id], !dayMap.isEmpty else { return 0 }

        let calendar = Calendar.current
        let completedDays: Set<Date> = Set(dayMap.compactMap { key, value -> Date? in
            guard value >= habit.targetQuantity, let date = Self.dateKeyFormatter.date(from: key) else { return nil }
            return calendar.startOfDay(for: date)
        })
        guard !completedDays.isEmpty else { return 0 }

        var best = 0
        for start in completedDays {
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: start)
            if let dayBefore, completedDays.contains(dayBefore) { continue } // not a streak start

            var length = 1
            var cursor = start
            while let next = calendar.date(byAdding: .day, value: 1, to: cursor), completedDays.contains(next) {
                length += 1
                cursor = next
            }
            best = max(best, length)
        }
        return best
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(habits) {
            defaults.set(data, forKey: habitsKey)
        }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: entriesKey)
        }
    }

    private func load() {
        if let data = defaults.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
        if let data = defaults.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([UUID: [String: Double]].self, from: data) {
            entries = decoded
        }
    }
}
