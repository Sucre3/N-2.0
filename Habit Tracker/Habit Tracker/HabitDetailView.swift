import SwiftUI

struct HabitDetailView: View {
    @EnvironmentObject private var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    let habitId: UUID
    @State private var showingEdit = false
    @State private var customAmountText = ""
    @State private var monthAnchor = Calendar.current.startOfDay(for: Date())

    private var habit: Habit? {
        store.habits.first { $0.id == habitId }
    }

    var body: some View {
        Group {
            if let habit {
                content(for: habit)
            } else {
                ContentUnavailableFallback()
            }
        }
        .onChange(of: store.habits) { _, habits in
            if !habits.contains(where: { $0.id == habitId }) { dismiss() }
        }
    }

    @ViewBuilder
    private func content(for habit: Habit) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                progressRing(for: habit)
                quickActions(for: habit)
                streakSummary(for: habit)
                HabitCalendarView(habit: habit, monthAnchor: $monthAnchor)
            }
            .padding()
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditHabitView(habit: habit)
        }
    }

    private func progressRing(for habit: Habit) -> some View {
        let fraction = store.progressFraction(for: habit)
        let amount = store.amount(for: habit)
        return ZStack {
            Circle()
                .stroke(habit.color.opacity(0.15), lineWidth: 18)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(habit.color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: fraction)

            VStack(spacing: 4) {
                Image(systemName: habit.icon)
                    .font(.largeTitle)
                    .foregroundStyle(habit.color)
                Text("\(formattedAmount(amount)) / \(formattedAmount(habit.targetQuantity))")
                    .font(.title3).bold()
                Text(habit.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .padding(.top, 8)
    }

    private func quickActions(for habit: Habit) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    store.addAmount(quickStep(for: habit), for: habit)
                } label: {
                    Label("+\(formattedAmount(quickStep(for: habit))) \(habit.unit)", systemImage: "plus")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(habit.color.opacity(0.2), in: Capsule())
                        .foregroundStyle(habit.color)
                }
                .buttonStyle(.plain)

                Button {
                    store.setAmount(0, for: habit)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline).bold()
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TextField("Cantitate personalizată", text: $customAmountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Button("Adaugă") {
                    guard let value = Double(customAmountText.replacingOccurrences(of: ",", with: ".")), value > 0 else { return }
                    store.addAmount(value, for: habit)
                    customAmountText = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(habit.color)
            }
        }
    }

    private func streakSummary(for habit: Habit) -> some View {
        HStack(spacing: 12) {
            statCard(title: "Streak curent", value: "\(store.currentStreak(for: habit))", icon: "flame.fill", tint: .orange)
            statCard(title: "Cel mai lung", value: "\(store.bestStreak(for: habit))", icon: "trophy.fill", tint: .yellow)
        }
    }

    private func statCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).font(.title2).bold()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.quaternary, lineWidth: 1))
    }

    private func quickStep(for habit: Habit) -> Double {
        habit.targetQuantity >= 10 ? max(1, (habit.targetQuantity / 8).rounded()) : 1
    }

    private func formattedAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}

private struct ContentUnavailableFallback: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Acest obicei nu mai există")
                .foregroundStyle(.secondary)
        }
    }
}

struct HabitCalendarView: View {
    @EnvironmentObject private var store: HabitStore
    let habit: Habit
    @Binding var monthAnchor: Date

    private let calendar = Calendar.current
    private let weekdaySymbols = ["Lu", "Ma", "Mi", "Jo", "Vi", "Sb", "Du"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    monthAnchor = calendar.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthTitle)
                    .font(.headline)
                Spacer()
                Button {
                    let next = calendar.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor
                    if next <= Date() { monthAnchor = next }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(isCurrentMonth)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)

            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(leadingBlanks), id: \.self) { _ in
                    Color.clear.frame(height: 32)
                }
                ForEach(daysInMonth, id: \.self) { day in
                    let fraction = store.progressFraction(for: habit, on: day)
                    let isToday = calendar.isDateInToday(day)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(fraction > 0 ? habit.color.opacity(0.25 + 0.55 * fraction) : Color(.secondarySystemBackground))
                        if isToday {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(habit.color, lineWidth: 2)
                        }
                        Text("\(calendar.component(.day, from: day))")
                            .font(.caption2)
                            .foregroundStyle(fraction >= 1 ? .white : .primary)
                    }
                    .frame(height: 32)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.quaternary, lineWidth: 1))
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ro_RO")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: monthAnchor).capitalized
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(monthAnchor, equalTo: Date(), toGranularity: .month)
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: monthAnchor),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthAnchor)) else {
            return []
        }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
    }

    /// Empty leading cells so day 1 lands under the right weekday (week starts Monday).
    private var leadingBlanks: Range<Int> {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthAnchor)) else {
            return 0..<0
        }
        let weekday = calendar.component(.weekday, from: firstOfMonth) // 1 = Sunday ... 7 = Saturday
        let mondayIndexed = (weekday + 5) % 7 // 0 = Monday ... 6 = Sunday
        return 0..<mondayIndexed
    }
}

#Preview {
    NavigationStack {
        HabitDetailView(habitId: UUID())
    }
    .environmentObject(HabitStore())
}
