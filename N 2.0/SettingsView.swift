import SwiftUI

struct SettingsView: View {
    @AppStorage("bibleProgress", store: UserDefaults(suiteName: "group.N20")) private var progressJSON: String = "{}"
    @AppStorage("lastReadDate", store: UserDefaults(suiteName: "group.N20")) private var lastReadDateString: String = ""
    @AppStorage("readStreak", store: UserDefaults(suiteName: "group.N20")) private var readStreak: Int = 0
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section(header: Text("Progres")) {
                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .confirmationDialog("Ești sigur(ă) că vrei să resetezi progresul?", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("Resetează", role: .destructive) {
                        progressJSON = "{}"
                        lastReadDateString = ""
                        readStreak = 0

                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                    Button("Anulează", role: .cancel) { }
                }
            }
        }
        .navigationTitle("Setări")
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
