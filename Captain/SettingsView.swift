import SwiftUI
import UserNotifications

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum MeasurementUnit: String, CaseIterable, Identifiable {
    case imperial = "Miles"
    case metric = "Kilometers"
    var id: String { rawValue }
}

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var previewStore: PreviewStore
    @EnvironmentObject var profileStore: ProfileStore

    // Simple persisted preferences
    @AppStorage("reminders_enabled") private var remindersEnabled: Bool = false
    @AppStorage("reminder_time") private var reminderTime: Double = Date().timeIntervalSinceReferenceDate
    @AppStorage("app_theme") private var appThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("measurement_unit") private var measurementUnitRaw: String = MeasurementUnit.imperial.rawValue

    @State private var showingExportShare: Bool = false
    @State private var exportURL: URL?
    @State private var showingClearProfileConfirmation: Bool = false
    @State private var showingClearAllDataConfirmation: Bool = false
    @State private var storageSize: String = "Calculating..."
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

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
                NavigationLink(value: Destination.buildProfile) {
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
                    showingClearProfileConfirmation = true
                }) {
                    Text("Clear Profile Only")
                        .font(Theme.Typography.body)
                }
                
                Button(role: .destructive, action: {
                    showingClearAllDataConfirmation = true
                }) {
                    Text("Clear All Data")
                        .font(Theme.Typography.body)
                }
            } header: {
                Text("Profile")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            } footer: {
                Text("Clear Profile Only removes your personal info. Clear All Data removes profile, sessions, and resets settings.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            // NEW: Appearance Section
            Section {
                Picker("Theme", selection: Binding(
                    get: { AppTheme(rawValue: appThemeRaw) ?? .system },
                    set: { newTheme in
                        appThemeRaw = newTheme.rawValue
                        applyTheme(newTheme)
                    }
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
                Toggle("Remind me to log sessions", isOn: Binding(
                    get: { remindersEnabled },
                    set: { newValue in
                        remindersEnabled = newValue
                        if newValue {
                            requestNotificationPermission()
                        } else {
                            cancelScheduledNotifications()
                        }
                    }
                ))
                    .font(Theme.Typography.body)
                
                DatePicker(
                    "Reminder time",
                    selection: Binding(
                        get: { Date(timeIntervalSinceReferenceDate: reminderTime) },
                        set: { newDate in
                            reminderTime = newDate.timeIntervalSinceReferenceDate
                            if remindersEnabled {
                                scheduleNotification(at: newDate)
                            }
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .font(Theme.Typography.body)
                .disabled(!remindersEnabled)
                
                if notificationPermissionStatus == .denied {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("⚠️ Notifications Disabled")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.orange)
                        Text("Enable notifications in Settings to receive reminders.")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        Button("Open Settings") {
                            openAppSettings()
                        }
                        .font(Theme.Typography.caption)
                    }
                }
            } header: {
                Text("Notifications")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .textCase(.uppercase)
            }

            Section {
                // Storage usage display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Storage Used")
                            .font(Theme.Typography.body)
                        HStack(spacing: 4) {
                            Text("\(sessionStore.sessions.count) sessions")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            if !previewStore.drafts.isEmpty {
                                Text("•")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                Text("\(previewStore.drafts.count) drafts")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }
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
                    openSupportForm()
                }) {
                    HStack {
                        Image(systemName: "envelope")
                            .font(.system(size: Theme.IconSize.md))
                            .foregroundColor(Theme.Colors.primary)
                        Text("Contact Support")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Button(action: {
                    openSupportForm()
                }) {
                    HStack {
                        Image(systemName: "ladybug")
                            .font(.system(size: Theme.IconSize.md))
                            .foregroundColor(Theme.Colors.primary)
                        Text("Report a Bug")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "arrow.up.right")
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
            } footer: {
                Text("Need help or found an issue? Let us know through our support form.")
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
                
                Link(destination: URL(string: "https://docs.google.com/document/d/e/2PACX-1vRMsK1DejOtJKaxrkXVLIXoelPXa8VzL34DbyyQJx69uNTqjfoJRbqS0VgrWTh8LSTmNMd_NKpapnJh/pub")!) {
                    HStack {
                        Text("Privacy Policy")
                            .font(Theme.Typography.body)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: Theme.IconSize.sm))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
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
        .confirmationDialog("Clear Profile Only", isPresented: $showingClearProfileConfirmation, titleVisibility: .visible) {
            Button("Clear Profile", role: .destructive) {
                clearProfileOnly()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove your profile information but keep your sessions and settings.")
        }
        .confirmationDialog("Clear All Data", isPresented: $showingClearAllDataConfirmation, titleVisibility: .visible) {
            Button("Clear Everything", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your profile, all sessions, media files, and reset all settings. This cannot be undone.")
        }
        .onAppear {
            router.current = .settings
            calculateStorageSize()
            checkNotificationPermission()
        }
        .preferredColorScheme(appTheme.colorScheme)
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
            
            // Session images
            let allImageNames = sessionStore.sessions.flatMap { $0.imageFileNames }
            for imageName in allImageNames {
                let imageURL = docsURL.appendingPathComponent(imageName)
                if let attributes = try? FileManager.default.attributesOfItem(atPath: imageURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            
            // Draft images
            let allDraftImageNames = previewStore.drafts.flatMap { $0.imageFileNames }
            for imageName in allDraftImageNames {
                let imageURL = docsURL.appendingPathComponent(imageName)
                if let attributes = try? FileManager.default.attributesOfItem(atPath: imageURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            
            // Profile photo
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
    
    private func openSupportForm() {
        // Opens Google Form for support and bug reports
        if let url = URL(string: "https://forms.gle/Tu22YPaR8gjZn2HD9") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        // Opens App Store review page for Captain
        if let url = URL(string: "https://apps.apple.com/app/id6768445637?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Theme Management
    
    private func applyTheme(_ theme: AppTheme) {
        // The theme is applied via .preferredColorScheme modifier on the view
        // This happens automatically when appThemeRaw changes
        print("Theme changed to: \(theme.rawValue)")
    }
    
    // MARK: - Notification Management
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationPermissionStatus = .authorized
                    self.scheduleNotification(at: Date(timeIntervalSinceReferenceDate: self.reminderTime))
                } else {
                    self.notificationPermissionStatus = .denied
                    self.remindersEnabled = false
                }
                
                if let error = error {
                    print("Error requesting notification permission: \(error)")
                }
            }
        }
    }
    
    private func scheduleNotification(at date: Date) {
        // Remove existing notifications first
        cancelScheduledNotifications()
        
        guard remindersEnabled else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Log Your Session!"
        content.body = "Don't forget to track your training progress today."
        content.sound = .default
        content.categoryIdentifier = "SESSION_REMINDER"
        
        // Extract hour and minute from the selected time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        // Create a daily repeating trigger
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(identifier: "daily_session_reminder", content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("✅ Scheduled daily reminder at \(components.hour ?? 0):\(String(format: "%02d", components.minute ?? 0))")
            }
        }
    }
    
    private func cancelScheduledNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_session_reminder"])
        print("🔕 Cancelled scheduled notifications")
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
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
    
    // MARK: - Data Management
    
    private func clearProfileOnly() {
        profileStore.clear()
        // Navigate back to landing page since profile is now empty
        NotificationCenter.default.post(name: Notification.Name("ProfileCompleted"), object: nil)
    }
    
    private func clearAllData() {
        // Cancel any scheduled notifications
        cancelScheduledNotifications()
        
        // Delete all data
        sessionStore.deleteAllSessionMediaFiles()
        sessionStore.clearAll()
        profileStore.clear()
        previewStore.clearAllDrafts()
        previewStore.clear()
        
        // Reset all preferences to defaults
        remindersEnabled = false
        reminderTime = Date().timeIntervalSinceReferenceDate
        appThemeRaw = AppTheme.system.rawValue
        measurementUnitRaw = MeasurementUnit.imperial.rawValue
        
        // Recalculate storage
        calculateStorageSize()
        
        // Navigate back to landing page
        NotificationCenter.default.post(name: Notification.Name("ProfileCompleted"), object: nil)
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
                .environmentObject(PreviewStore())
                .environmentObject(ProfileStore())
        }
    }
}

