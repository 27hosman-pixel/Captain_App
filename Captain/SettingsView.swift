import SwiftUI

enum ProfileVisibility: String, CaseIterable, Identifiable {
    case `public` = "Public"
    case `private` = "Private"
    var id: String { rawValue }
}

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sessionStore: SessionStore
    @StateObject private var profileStore = ProfileStore()

    // Simple persisted preferences
    @AppStorage("reminders_enabled") private var remindersEnabled: Bool = false
    @AppStorage("reminder_time") private var reminderTime: Double = Date().timeIntervalSinceReferenceDate
    @AppStorage("default_session_public") private var defaultSessionPublic: Bool = true

    @State private var showingExportShare: Bool = false
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section(header: Text("Account")) {
                Button("Manage Profile") {
                    router.navigate(.buildProfile)
                }
                Button(role: .destructive) {
                    profileStore.clear()
                } label: {
                    Text("Clear Profile")
                }
            }

            Section(header: Text("Notifications")) {
                Toggle("Remind me to log sessions", isOn: $remindersEnabled)
                DatePicker("Reminder time", selection: Binding(get: {
                    Date(timeIntervalSinceReferenceDate: reminderTime)
                }, set: { newDate in
                    reminderTime = newDate.timeIntervalSinceReferenceDate
                }), displayedComponents: .hourAndMinute)
                .disabled(!remindersEnabled)
            }

            Section(header: Text("Privacy")) {
                Toggle("Default new sessions are Public", isOn: $defaultSessionPublic)
                Text("You can still change visibility per session when logging.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Data & Storage")) {
                Button("Export my data") {
                    exportData()
                }
                Button(role: .destructive) {
                    sessionStore.clearAll()
                } label: {
                    Text("Clear all sessions")
                }
                Button(role: .destructive) {
                    sessionStore.deleteAllSessionMediaFiles()
                } label: {
                    Text("Remove stored media files")
                }
            }

            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersionString()).foregroundColor(.secondary)
                }
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingExportShare, onDismiss: cleanupExportURL) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
        .onAppear {
            // optional: set router.current
            router.current = .settings
        }
    }

    private func exportData() {
        let data = sessionStore.exportData(profile: profileStore.profile)
        guard let data, let url = writeTempFile(data: data, suggestedName: "CaptainExport.json") else { return }
        exportURL = url
        showingExportShare = true
    }

    private func writeTempFile(data: Data, suggestedName: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedName)
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            print("Failed to write export:", error)
            return nil
        }
    }

    private func cleanupExportURL() {
        if let url = exportURL {
            try? FileManager.default.removeItem(at: url)
        }
        exportURL = nil
    }

    private func appVersionString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "v\(v) (\(b))"
    }
}

// Simple UIKit share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(AppRouter())
                .environmentObject(SessionStore())
        }
    }
}

