import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: HabitStore
    @State private var showingAddHabit = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                if store.habits.isEmpty {
                    emptyState
                } else {
                    habitList
                }
            }
            .navigationTitle("Obiceiuri")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddEditHabitView(habit: nil)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
            Text("Niciun obicei încă")
                .font(.title2).bold()
            Text("Adaugă primul obicei pe care vrei să-l urmărești zilnic.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showingAddHabit = true
            } label: {
                Label("Adaugă obicei", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.tint, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var habitList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(store.habits) { habit in
                    NavigationLink {
                        HabitDetailView(habitId: habit.id)
                    } label: {
                        HabitCard(habit: habit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

private struct HabitCard: View {
    @EnvironmentObject private var store: HabitStore
    let habit: Habit

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(habit.color.opacity(0.2))
                Image(systemName: habit.icon)
                    .font(.title2)
                    .foregroundStyle(habit.color)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name)
                    .font(.headline)
                ProgressView(value: store.progressFraction(for: habit)) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(formattedAmount(store.amount(for: habit)))/\(formattedAmount(habit.targetQuantity)) \(habit.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tint(habit.color)
            }

            Spacer(minLength: 8)

            let streak = store.currentStreak(for: habit)
            if streak > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(streak)")
                        .font(.caption).bold()
                }
            }

            Button {
                store.addAmount(quickStep(for: habit), for: habit)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(habit.color)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private func quickStep(for habit: Habit) -> Double {
        habit.targetQuantity >= 10 ? max(1, (habit.targetQuantity / 8).rounded()) : 1
    }

    private func formattedAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
    }
}

#Preview {
    ContentView()
        .environmentObject(HabitStore())
}
