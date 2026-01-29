import SwiftUI
import UIKit

struct BibleTrackerView: View {
    // Persist progress as [BookName: Set<ChapterIndex>] where chapter index is 1-based
    @AppStorage("bibleProgress", store: UserDefaults(suiteName: "group.N20")) private var progressJSON: String = "{}"
    @AppStorage("lastReadDate", store: UserDefaults(suiteName: "group.N20")) private var lastReadDateString: String = ""
    @AppStorage("readStreak", store: UserDefaults(suiteName: "group.N20")) private var readStreak: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                NavigationLink {
                    OptionsView(progressJSON: $progressJSON)
                } label: {
                    Text("Biblia")
                        .font(.title2).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    private func bookRow(book: BibleBook, map: [String: Set<Int>]) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                ProgressView(value: Double(map[book.name]?.count ?? 0), total: Double(book.chapters)) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(String(map[book.name]?.count ?? 0))/\(String(book.chapters)) cap.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)
            }
            Spacer()
            if isBookCompleted(book, map: map) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func sectionHeader(title: String, books: [BibleBook]) -> some View {
        HStack {
            if !title.isEmpty { Text(title) }
            Spacer()
            let map = progressMap()
            let read = books.reduce(0) { $0 + (map[$1.name]?.count ?? 0) }
            let total = books.reduce(0) { $0 + $1.chapters }
            Text("\(String(read))/\(String(total)) cap.")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }

    // MARK: - Progress Helpers

    private func progressMap() -> [String: Set<Int>] {
        guard let data = progressJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else {
            return [:]
        }
        return decoded.mapValues { Set($0) }
    }

    private func isBookCompleted(_ book: BibleBook, map: [String: Set<Int>]) -> Bool {
        let count = map[book.name]?.count ?? 0
        return count >= book.chapters
    }
}

struct BooksSectionView: View {
    let title: String
    let books: [BibleBook]
    @Binding var progressJSON: String

    var body: some View {
        List {
            Section(header: Text(title)) {
                let map = progressMap()
                if let idx = books.firstIndex(where: { !isBookCompleted($0, map: map) }) {
                    let current = books[idx]
                    NavigationLink {
                        ProgressiveBookView(book: current, progressJSON: $progressJSON)
                    } label: {
                        bookRow(book: current, map: map)
                    }
                } else {
                    Text("Toate cărțile sunt bifate aici").foregroundStyle(.secondary)
                }

                // Completed books
                let completed = books.filter { isBookCompleted($0, map: map) }
                if !completed.isEmpty {
                    ForEach(completed, id: \.name) { book in
                        HStack {
                            Text(book.name)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(title)
        .preferredColorScheme(.dark)
    }

    private func progressMap() -> [String: Set<Int>] {
        guard let data = progressJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else { return [:] }
        return decoded.mapValues { Set($0) }
    }
    private func isBookCompleted(_ book: BibleBook, map: [String: Set<Int>]) -> Bool {
        let count = map[book.name]?.count ?? 0
        return count >= book.chapters
    }
    private func bookRow(book: BibleBook, map: [String: Set<Int>]) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.name).font(.headline)
                ProgressView(value: Double(map[book.name]?.count ?? 0), total: Double(book.chapters)) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(String(map[book.name]?.count ?? 0))/\(String(book.chapters)) cap.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .progressViewStyle(.linear)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Shows only the next unread chapter; as you check it, the next one appears.
struct ProgressiveBookView: View {
    let book: BibleBook
    @Binding var progressJSON: String

    var body: some View {
        List {
            Section(header: Text(book.name).font(.headline)) {
                if let nextChapter = nextUnreadChapter() {
                    // Next unread (interactive)
                    ChapterRow(book: book, chapter: nextChapter, progressJSON: $progressJSON)

                    // Already read chapters
                    let readChapters = Array(progressMap()[book.name] ?? []).sorted()
                    if !readChapters.isEmpty {
                        ForEach(readChapters, id: \.self) { ch in
                            HStack {
                                Text("Capitolul \(String(ch))")
                                Spacer()
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Cartea este completă")
                    }
                }
            }
        }
        .navigationTitle(book.name)
    }

    private func progressMap() -> [String: Set<Int>] {
        guard let data = progressJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else {
            return [:]
        }
        return decoded.mapValues { Set($0) }
    }

    private func nextUnreadChapter() -> Int? {
        let map = progressMap()
        let read = map[book.name] ?? []
        // Return the smallest chapter in 1...chapters that is not read
        for ch in 1...book.chapters {
            if !read.contains(ch) { return ch }
        }
        return nil
    }
}

private struct ChapterRow: View {
    let book: BibleBook
    let chapter: Int
    @Binding var progressJSON: String
    @AppStorage("lastReadDate", store: UserDefaults(suiteName: "group.N20")) private var lastReadDateString: String = ""
    @AppStorage("readStreak", store: UserDefaults(suiteName: "group.N20")) private var readStreak: Int = 0

    var body: some View {
        HStack {
            Text("Capitolul \(String(chapter))")
            Spacer()
            Toggle("", isOn: Binding(
                get: { isRead() },
                set: { newValue in updateRead(newValue) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
    }

    private func progressMap() -> [String: Set<Int>] {
        guard let data = progressJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else {
            return [:]
        }
        return decoded.mapValues { Set($0) }
    }

    private func saveProgressMap(_ map: [String: Set<Int>]) {
        let encodable = map.mapValues { Array($0).sorted() }
        if let data = try? JSONEncoder().encode(encodable),
           let string = String(data: data, encoding: .utf8) {
            progressJSON = string
        }
    }

    private func isRead() -> Bool {
        let map = progressMap()
        return map[book.name]?.contains(chapter) ?? false
    }

    private func updateRead(_ isOn: Bool) {
        var map = progressMap()
        var set = map[book.name] ?? []
        if isOn {
            set.insert(chapter)
        } else {
            set.remove(chapter)
        }
        map[book.name] = set
        saveProgressMap(map)

        // Haptics feedback on toggle
        if isOn {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        // Update reading streak when marking as read
        if isOn {
            let today = Calendar.current.startOfDay(for: Date())
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            if let lastDate = ISO8601DateFormatter().date(from: lastReadDateString) {
                let lastDay = Calendar.current.startOfDay(for: lastDate)
                if Calendar.current.isDate(lastDay, inSameDayAs: today) {
                    // Already counted today
                } else if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today), Calendar.current.isDate(lastDay, inSameDayAs: yesterday) {
                    readStreak += 1
                    lastReadDateString = formatter.string(from: today)
                } else {
                    readStreak = max(readStreak, 1)
                    lastReadDateString = formatter.string(from: today)
                }
            } else {
                // First time
                readStreak = max(readStreak, 1)
                lastReadDateString = formatter.string(from: today)
            }
        }
    }
}

struct OptionsView: View {
    @Binding var progressJSON: String

    private var psalmsBooks: [BibleBook] {
        // Try to find a book named "Psalmi" inside the Old Testament list
        if let psalms = BibleData.oldTestament.first(where: { $0.name.localizedCaseInsensitiveCompare("Psalmi") == .orderedSame }) {
            return [psalms]
        }
        return []
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    BooksSectionView(title: "Vechiul Testament", books: BibleData.oldTestament, progressJSON: $progressJSON)
                } label: {
                    HStack {
                        Image(systemName: "book")
                        Text("Vechiul Testament")
                        Spacer()
                        sectionHeader(title: "", books: BibleData.oldTestament)
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    BooksSectionView(title: "Noul Testament", books: BibleData.newTestament, progressJSON: $progressJSON)
                } label: {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Noul Testament")
                        Spacer()
                        sectionHeader(title: "", books: BibleData.newTestament)
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    BooksSectionView(title: "Psalmi", books: psalmsBooks, progressJSON: $progressJSON)
                } label: {
                    HStack {
                        Image(systemName: "music.note.list")
                        Text("Psalmi")
                        Spacer()
                        sectionHeader(title: "", books: psalmsBooks)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Alege secțiunea")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    StatisticsView(progressJSON: $progressJSON,
                                    lastReadDateString: .constant(UserDefaults(suiteName: "group.N20")?.string(forKey: "lastReadDate") ?? ""),
                                    readStreak: .constant(UserDefaults(suiteName: "group.N20")?.integer(forKey: "readStreak") ?? 0))
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }
            }
        }
    }

    // Reuse the header helper by delegating to BibleTrackerView's implementation via a local copy
    private func sectionHeader(title: String, books: [BibleBook]) -> some View {
        HStack {
            if !title.isEmpty { Text(title) }
            Spacer()
            let map = progressMap()
            let read = books.reduce(0) { $0 + (map[$1.name]?.count ?? 0) }
            let total = books.reduce(0) { $0 + $1.chapters }
            Text("\(String(read))/\(String(total)) cap.")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }

    private func progressMap() -> [String: Set<Int>] {
        guard let data = progressJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else {
            return [:]
        }
        return decoded.mapValues { Set($0) }
    }
}

struct StatisticsView: View {
    @Binding var progressJSON: String
    @Binding var lastReadDateString: String
    @Binding var readStreak: Int

    // Adjust this to tune average time per chapter (in minutes)
    @AppStorage("avgMinutesPerChapter", store: UserDefaults(suiteName: "group.N20")) private var avgMinutesPerChapter: Int = 5

    private func progressMap() -> [String: Set<Int>] {
        guard let data = progressJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) else { return [:] }
        return decoded.mapValues { Set($0) }
    }

    private func countRead(in books: [BibleBook], map: [String: Set<Int>]) -> Int {
        books.reduce(0) { $0 + (map[$1.name]?.count ?? 0) }
    }
    
    private func totalChapters(in books: [BibleBook]) -> Int { books.reduce(0) { $0 + $1.chapters } }

    private var psalmsBooks: [BibleBook] {
        if let psalms = BibleData.oldTestament.first(where: { $0.name.localizedCaseInsensitiveCompare("Psalmi") == .orderedSame }) { return [psalms] }
        return []
    }

    private func estimatedMinutesRemaining(read: Int, total: Int) -> Int {
        let remaining = max(total - read, 0)
        return remaining * max(avgMinutesPerChapter, 1)
    }

    var body: some View {
        let map = progressMap()
        let allBooks = BibleData.oldTestament + BibleData.newTestament
        let totalAll = totalChapters(in: allBooks)
        let readAll = countRead(in: allBooks, map: map)

        let totalOT = totalChapters(in: BibleData.oldTestament)
        let readOT = countRead(in: BibleData.oldTestament, map: map)

        let totalNT = totalChapters(in: BibleData.newTestament)
        let readNT = countRead(in: BibleData.newTestament, map: map)

        let totalP = totalChapters(in: psalmsBooks)
        let readP = countRead(in: psalmsBooks, map: map)

        List {
            Section(header: Text("Progres general")) {
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: Double(readAll), total: Double(totalAll))
                    HStack {
                        Text("\(String(readAll))/\(String(totalAll)) capitole")
                        Spacer()
                        Text(String(format: "%.0f%%", totalAll > 0 ? (Double(readAll) / Double(totalAll) * 100.0) : 0))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(header: Text("Progres pe secțiuni")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vechiul Testament")
                    ProgressView(value: Double(readOT), total: Double(totalOT))
                    Text("\(String(readOT))/\(String(totalOT)) cap.").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Noul Testament")
                    ProgressView(value: Double(readNT), total: Double(totalNT))
                    Text("\(String(readNT))/\(String(totalNT)) cap.").font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Psalmi")
                    ProgressView(value: Double(readP), total: Double(totalP))
                    Text("\(String(readP))/\(String(totalP)) cap.").font(.caption).foregroundStyle(.secondary)
                }
            }

            Section(header: Text("Zile consecutive")) {
                HStack {
                    Text("Streak: \(String(readStreak)) zile")
                    Spacer()
                    if let last = ISO8601DateFormatter().date(from: lastReadDateString) {
                        Text("Ultima citire: \(last.formatted(date: .abbreviated, time: .omitted))")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(header: Text("Timp estimat rămas")) {
                let minutes = estimatedMinutesRemaining(read: readAll, total: totalAll)
                let hours = minutes / 60
                let mins = minutes % 60
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Timp mediu/Capitol: \(String(avgMinutesPerChapter)) min")
                        Spacer()
                    }
                    HStack {
                        Text("Rămas: \(String(hours))h \(String(mins))m")
                        Spacer()
                    }
                    Stepper("Ajustează timpul mediu: \(avgMinutesPerChapter) min", value: $avgMinutesPerChapter, in: 1...60)
                }
            }
        }
        .navigationTitle("Statistici")
    }
}

#Preview {
    NavigationStack { BibleTrackerView() }
        .preferredColorScheme(.dark)
}

