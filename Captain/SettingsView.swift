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
            Section {
                Button(action: {
                    router.navigate(.buildProfile)
                }) {
                    HStack {
                        Text("Manage Profile")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Button(role: .destructive, action: {
                    profileStore.clear()
                }) {
                    Text("Clear Profile")
                        .font(Theme.Typography.body)
                }
            } header: {
                Text("Account")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            }

            Section {
                Toggle("Remind me to log sessions", isOn: $remindersEnabled)
                    .font(Theme.Typography.body)
                
                DatePicker(
                    "Reminder time",
                    selection: Binding(
                        get: { Date(timeIntervalSinceReferenceDate: reminderTime) },
                        set: { newDate in reminderTime = newDate.timeIntervalSinceReferenceDate }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .font(Theme.Typography.body)
                .disabled(!remindersEnabled)
            } header: {
                Text("Notifications")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            }

            Section {
                Toggle("Default new sessions are Public", isOn: $defaultSessionPublic)
                    .font(Theme.Typography.body)
                
                Text("You can still change visibility per session when logging.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            } header: {
                Text("Privacy")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            }

            Section {
                Button(action: {
                    exportData()
                }) {
                    HStack {
                        Text("Export my data")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                
                Button(role: .destructive, action: {
                    sessionStore.clearAll()
                }) {
                    Text("Clear all sessions")
                        .font(Theme.Typography.body)
                }
                
                Button(role: .destructive, action: {
                    sessionStore.deleteAllSessionMediaFiles()
                }) {
                    Text("Remove stored media files")
                        .font(Theme.Typography.body)
                }
            } header: {
                Text("Data & Storage")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            }

            Section {
                HStack {
                    Text("Version")
                        .font(Theme.Typography.body)
                    Spacer()
                    Text(appVersionString())
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Link(destination: URL(string: "https://example.com/terms")!) {
                    HStack {
                        Text("Terms of Service")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            } header: {
                Text("About")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
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

