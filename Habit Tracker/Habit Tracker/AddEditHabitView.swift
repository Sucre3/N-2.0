import SwiftUI

struct AddEditHabitView: View {
    @EnvironmentObject private var store: HabitStore
    @Environment(\.dismiss) private var dismiss

    /// Non-nil when editing an existing habit.
    let habit: Habit?

    @State private var name: String
    @State private var icon: String
    @State private var color: HabitColor
    @State private var targetQuantityText: String
    @State private var unit: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var confirmDelete = false

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    init(habit: Habit?) {
        self.habit = habit
        _name = State(initialValue: habit?.name ?? "")
        _icon = State(initialValue: habit?.icon ?? HabitPalette.icons[0])
        _color = State(initialValue: habit?.colorName ?? .blue)
        _targetQuantityText = State(initialValue: habit.map { formattedAmount($0.targetQuantity) } ?? "1")
        _unit = State(initialValue: habit?.unit ?? "ori")
        _reminderEnabled = State(initialValue: habit?.reminderEnabled ?? false)
        _reminderTime = State(initialValue: Self.time(hour: habit?.reminderHour ?? 20, minute: habit?.reminderMinute ?? 0))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nume") {
                    TextField("ex: Băut apă", text: $name)
                }

                Section("Iconiță") {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(HabitPalette.icons, id: \.self) { symbol in
                            Button {
                                icon = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(icon == symbol ? color.color.opacity(0.25) : Color(.secondarySystemBackground))
                                    .foregroundStyle(icon == symbol ? color.color : .primary)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().strokeBorder(icon == symbol ? color.color : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Culoare") {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(HabitColor.allCases) { option in
                            Button {
                                color = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle().strokeBorder(.white, lineWidth: color == option ? 2 : 0)
                                    )
                                    .overlay(
                                        Circle().strokeBorder(.quaternary, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Obiectiv zilnic") {
                    HStack {
                        TextField("Cantitate", text: $targetQuantityText)
                            .keyboardType(.decimalPad)
                        TextField("Unitate (ex: pahare)", text: $unit)
                    }
                }

                Section("Reminder") {
                    Toggle("Notificare zilnică", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, isOn in
                            if isOn { NotificationManager.shared.requestAuthorization() }
                        }
                    if reminderEnabled {
                        DatePicker("Ora", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                if habit != nil {
                    Section {
                        Button("Șterge obiceiul", role: .destructive) {
                            confirmDelete = true
                        }
                    }
                }
            }
            .navigationTitle(habit == nil ? "Obicei nou" : "Editează obiceiul")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anulează") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvează") { save() }
                        .disabled(!isValid)
                }
            }
            .confirmationDialog("Ești sigur(ă) că vrei să ștergi acest obicei?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Șterge", role: .destructive) {
                    if let habit { store.deleteHabit(habit) }
                    dismiss()
                }
                Button("Anulează", role: .cancel) {}
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(targetQuantityText.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
            && !unit.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        guard let target = Double(targetQuantityText.replacingOccurrences(of: ",", with: ".")) else { return }
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)

        if var existing = habit {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.icon = icon
            existing.colorName = color
            existing.targetQuantity = target
            existing.unit = unit.trimmingCharacters(in: .whitespaces)
            existing.reminderEnabled = reminderEnabled
            existing.reminderHour = hour
            existing.reminderMinute = minute
            store.updateHabit(existing)
        } else {
            let newHabit = Habit(
                name: name.trimmingCharacters(in: .whitespaces),
                icon: icon,
                colorName: color,
                targetQuantity: target,
                unit: unit.trimmingCharacters(in: .whitespaces),
                reminderEnabled: reminderEnabled,
                reminderHour: hour,
                reminderMinute: minute
            )
            store.addHabit(newHabit)
        }
        dismiss()
    }

    private static func time(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

private func formattedAmount(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
}

#Preview {
    AddEditHabitView(habit: nil)
        .environmentObject(HabitStore())
}
