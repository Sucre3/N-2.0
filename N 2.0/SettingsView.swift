import SwiftUI

struct SettingsView: View {
    @AppStorage("bibleProgress") private var progressJSON: String = "{}"
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
                    Button("Resetează", role: .destructive) { progressJSON = "{}" }
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
