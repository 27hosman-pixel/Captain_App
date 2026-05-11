
//
//  ContentView.swift
//  Captain
//
//  Created by Hana Osman on 3/4/26.
//
//  Simplified - No authentication required, just profile creation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @StateObject private var previewStore = PreviewStore()
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var feedFilters = FeedFilters()
    @StateObject private var profileStore = ProfileStore()
    
    // Read theme preference
    @AppStorage("app_theme") private var appThemeRaw: String = AppTheme.system.rawValue
    
    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeRaw) ?? .system
    }

    // Tab selection
    private enum Tab: Hashable {
        case home, profile, log, stats, settings
    }
    @State private var selectedTab: Tab = .home
    @State private var showingBuildProfile = false

    // Per-tab navigation paths
    @State private var homePath = NavigationPath()
    @State private var profilePath = NavigationPath()
    @State private var logPath = NavigationPath()
    @State private var statsPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    var body: some View {
        Group {
            if !profileStore.hasProfile {
                // Show landing page if no profile exists
                landingView
                    .preferredColorScheme(.light)
            } else {
                // Show main app
                mainAppView
                    .preferredColorScheme(appTheme.colorScheme)
            }
        }
        .environmentObject(router)
        .environmentObject(previewStore)
        .environmentObject(sessionStore)
        .environmentObject(feedFilters)
        .environmentObject(profileStore)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ProfileCompleted"))) { _ in
            // Profile was saved, refresh to check hasProfile
            profileStore.load()
        }
    }

    // MARK: - Main App View
    
    private var mainAppView: some View {
        TabView(selection: $selectedTab) {
            // Home tab
            NavigationStack(path: $homePath) {
                HomeView()
                    .navigationDestination(for: Destination.self) { dest in
                        destinationView(for: dest)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(Tab.home)

            // Profile tab
            NavigationStack(path: $profilePath) {
                ProfileView()
                    .navigationDestination(for: Destination.self) { dest in
                        destinationView(for: dest)
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(Tab.profile)

            // Log tab
            NavigationStack(path: $logPath) {
                LogSessionChoiceView()
                    .navigationDestination(for: Destination.self) { dest in
                        destinationView(for: dest)
                    }
            }
            .tabItem {
                Label("Log", systemImage: "plus.square.on.square")
            }
            .tag(Tab.log)

            // Stats tab
            NavigationStack(path: $statsPath) {
                StatisticsView()
                    .navigationDestination(for: Destination.self) { dest in
                        destinationView(for: dest)
                    }
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(Tab.stats)

            // Settings tab
            NavigationStack(path: $settingsPath) {
                SettingsView()
                    .navigationDestination(for: Destination.self) { dest in
                        destinationView(for: dest)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(Tab.settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenMessaging"))) { _ in
            selectedTab = .home
            homePath.append(Destination.messaging)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenNotifications"))) { _ in
            selectedTab = .home
            homePath.append(Destination.notifications)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToLogPractice"))) { _ in
            selectedTab = .log
            logPath.append(Destination.logPractice)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToLogGame"))) { _ in
            selectedTab = .log
            logPath.append(Destination.logGame)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToLogWorkout"))) { _ in
            selectedTab = .log
            logPath.append(Destination.logWorkout)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToPreview"))) { _ in
            selectedTab = .log
            logPath.append(Destination.preview)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToHome"))) { _ in
            selectedTab = .home
            clearAllPaths()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToDrafts"))) { _ in
            selectedTab = .profile
            profilePath.append(Destination.drafts)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToLogTab"))) { _ in
            selectedTab = .log
        }
    }

    // MARK: - Landing View

    private var landingView: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and branding
                    VStack(spacing: 8) {
                        Text("CAPTAIN")
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)

                        Image("CaptainLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                    }
                    
                    Spacer()
                    
                    // Call to action
                    VStack(spacing: 12) {
                        Text("Track Your Soccer Journey")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text("Log sessions, track progress, reach your goals")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 32)
                    
                    // Get Started button
                    Button(action: {
                        showingBuildProfile = true
                    }) {
                        Text("GET STARTED")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(
                        colors: [
                            Color(red: 0.78, green: 0.94, blue: 0.99),
                            Color(red: 0.68, green: 0.91, blue: 0.98)
                        ],
                        foreground: .black
                    ))
                    .padding(.horizontal, 36)
                    .padding(.bottom, 60)
                }
            }
            .navigationDestination(isPresented: $showingBuildProfile) {
                BuildProfileView()
            }
        }
    }

    // MARK: - Helpers

    private func destinationView(for dest: Destination) -> some View {
        Group {
            switch dest {
            case .home:
                HomeView()
            case .buildProfile:
                BuildProfileView()
            case .profile:
                ProfileView()
            case .logSession:
                LogSessionChoiceView()
            case .logPractice:
                LogPracticeView()
            case .logGame:
                LogGameView()
            case .logWorkout:
                LogWorkoutView()
            case .preview:
                SessionPreviewView()
            case .drafts:
                DraftsView()
            case .activities:
                ActivitiesView()
            case .statistics:
                StatisticsView()
            case .settings:
                SettingsView()
            case .messaging:
                MessagingView()
            case .notifications:
                NotificationsView()
            case .login, .signup:
                // These destinations no longer exist, show home instead
                HomeView()
            }
        }
        .onAppear {
            router.current = dest
        }
    }

    private func clearAllPaths() {
        homePath = NavigationPath()
        profilePath = NavigationPath()
        logPath = NavigationPath()
        statsPath = NavigationPath()
        settingsPath = NavigationPath()
    }
}

// Reusable pill-style button
struct PillButtonStyle: ButtonStyle {
    var colors: [Color]
    var foreground: Color = .black

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foreground)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        .blendMode(.screen)
                        .padding(0.5)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.18), radius: configuration.isPressed ? 6 : 12, x: 0, y: configuration.isPressed ? 3 : 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
