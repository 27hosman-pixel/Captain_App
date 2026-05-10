import SwiftUI

enum ProfileVisibility: String, CaseIterable, Identifiable {
    case `public` = "Public"
    case `private` = "Private"
    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }
}

enum MeasurementUnit: String, CaseIterable, Identifiable {
    case imperial = "Miles"
    case metric = "Kilometers"
    var id: String { rawValue }
}

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var authStore: AuthStore
    @StateObject private var profileStore = ProfileStore()

    // Simple persisted preferences
    @AppStorage("reminders_enabled") private var remindersEnabled: Bool = false
    @AppStorage("reminder_time") private var reminderTime: Double = Date().timeIntervalSinceReferenceDate
    @AppStorage("default_session_public") private var defaultSessionPublic: Bool = true
    @AppStorage("app_theme") private var appThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("measurement_unit") private var measurementUnitRaw: String = MeasurementUnit.imperial.rawValue

    @State private var showingExportShare: Bool = false
    @State private var exportURL: URL?
    @State private var showingLogoutConfirmation: Bool = false
    @State private var showingDeleteAccountConfirmation: Bool = false
    @State private var storageSize: String = "Calculating..."

    var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .system }
        set { appThemeRaw = newValue.rawValue }
    }
    
    var measurementUnit: MeasurementUnit {
        get { MeasurementUnit(rawValue: measurementUnitRaw) ?? .imperial }
        set { measurementUnitRaw = newValue.rawValue }
    }

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
            
            // NEW: Appearance Section
            Section {
                Picker("Theme", selection: Binding(
                    get: { AppTheme(rawValue: appThemeRaw) ?? .system },
                    set: { appThemeRaw = $0.rawValue }
                )) {
                    ForEach(AppTheme.allCases) { theme in
                        HStack {
                            themeIcon(for: theme)
                            Text(theme.rawValue)
                        }
                        .tag(theme)
                    }
                }
                .font(Theme.Typography.body)
            } header: {
                Text("Appearance")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            } footer: {
                Text("Choose how the app looks. System will match your device settings.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            // NEW: Units & Measurements Section
            Section {
                Picker("Distance", selection: Binding(
                    get: { MeasurementUnit(rawValue: measurementUnitRaw) ?? .imperial },
                    set: { measurementUnitRaw = $0.rawValue }
                )) {
                    ForEach(MeasurementUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .font(Theme.Typography.body)
            } header: {
                Text("Units & Measurements")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            } footer: {
                Text("Your preferred unit for distance measurements.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
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
                // NEW: Storage usage display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Storage Used")
                            .font(Theme.Typography.body)
                        Text("\(sessionStore.sessions.count) sessions")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    Spacer()
                    Text(storageSize)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
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
                    calculateStorageSize()
                }) {
                    Text("Clear all sessions")
                        .font(Theme.Typography.body)
                }
                
                Button(role: .destructive, action: {
                    sessionStore.deleteAllSessionMediaFiles()
                    calculateStorageSize()
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
            
            // NEW: Help & Support Section
            Section {
                Button(action: {
                    // Open help center
                    if let url = URL(string: "https://example.com/help") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: Theme.IconSize.md))
                            .foregroundColor(Theme.Colors.primary)
                        Text("Help Center")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Button(action: {
                    sendSupportEmail()
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.system(size: Theme.IconSize.md))
                            .foregroundColor(Theme.Colors.primary)
                        Text("Contact Support")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Button(action: {
                    sendBugReport()
                }) {
                    HStack {
                        Image(systemName: "ladybug")
                            .font(.system(size: Theme.IconSize.md))
                            .foregroundColor(Theme.Colors.primary)
                        Text("Report a Bug")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Button(action: {
                    rateApp()
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: Theme.IconSize.md))
                            .foregroundColor(.yellow)
                        Text("Rate Captain")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            } header: {
                Text("Help & Support")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            }

            Section {
                Button(action: {
                    showingLogoutConfirmation = true
                }) {
                    HStack {
                        Text("Log Out")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Button(role: .destructive, action: {
                    showingDeleteAccountConfirmation = true
                }) {
                    Text("Delete Account")
                        .font(Theme.Typography.body)
                }
            } header: {
                Text("Account Management")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            } footer: {
                Text("Deleting your account will permanently remove all your data including profile, sessions, and media files. This action cannot be undone.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
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
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExportShare, onDismiss: cleanupExportURL) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
        .confirmationDialog("Log Out", isPresented: $showingLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out? Your data will remain on this device.")
        }
        .confirmationDialog("Delete Account", isPresented: $showingDeleteAccountConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .onAppear {
            router.current = .settings
            calculateStorageSize()
        }
    }
    
    // MARK: - Helper Functions
    
    private func themeIcon(for theme: AppTheme) -> some View {
        Group {
            switch theme {
            case .system:
                Image(systemName: "circle.lefthalf.filled")
            case .light:
                Image(systemName: "sun.max.fill")
            case .dark:
                Image(systemName: "moon.fill")
            }
        }
    }
    
    private func calculateStorageSize() {
        DispatchQueue.global(qos: .utility).async {
            var totalSize: Int64 = 0
            
            // Calculate size of all session images
            guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    storageSize = "—"
                }
                return
            }
            
            let allImageNames = sessionStore.sessions.flatMap { $0.imageFileNames }
            for imageName in allImageNames {
                let imageURL = docsURL.appendingPathComponent(imageName)
                if let attributes = try? FileManager.default.attributesOfItem(atPath: imageURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            
            // Also check profile photo
            let profilePhotoURL = docsURL.appendingPathComponent("profile_photo.jpg")
            if let attributes = try? FileManager.default.attributesOfItem(atPath: profilePhotoURL.path),
               let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
            
            DispatchQueue.main.async {
                storageSize = formatBytes(totalSize)
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func sendSupportEmail() {
        let email = "support@captainapp.com"
        let subject = "Captain Support Request"
        let body = """
        
        
        ---
        App Version: \(appVersionString())
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        """
        
        let coded = "mailto:\(email)?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if let coded = coded, let url = URL(string: coded) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendBugReport() {
        let email = "bugs@captainapp.com"
        let subject = "Bug Report - Captain"
        let body = """
        Please describe the bug:
        
        
        Steps to reproduce:
        1. 
        2. 
        3. 
        
        Expected behavior:
        
        
        ---
        App Version: \(appVersionString())
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        """
        
        let coded = "mailto:\(email)?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if let coded = coded, let url = URL(string: coded) {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        // In a real app, replace with your actual App Store ID
        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") {
            UIApplication.shared.open(url)
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
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }
    
    private func logout() {
        authStore.logout()
        router.replaceWith(.login)
    }
    
    private func deleteAccount() {
        // Delete all data
        sessionStore.deleteAllSessionMediaFiles()
        sessionStore.clearAll()
        profileStore.clear()
        
        // Clear preferences
        remindersEnabled = false
        reminderTime = Date().timeIntervalSinceReferenceDate
        defaultSessionPublic = true
        
        // Log out and navigate to login
        authStore.logout()
        router.replaceWith(.login)
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
                .environmentObject(AuthStore())
        }
    }
}

