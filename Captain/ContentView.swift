
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
            // Profile was saved - ProfileStore is already updated via @EnvironmentObject
            // Just reset the showingBuildProfile flag to ensure clean state
            showingBuildProfile = false
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
                // Gradient background matching stats/log pages
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.15),
                        Color.purple.opacity(0.10),
                        Color.cyan.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and branding with modern styling
                    VStack(spacing: 20) {
                        // App title with modern gradient using overlay
                        Text("CAPTAIN")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .mask(
                                Text("CAPTAIN")
                                    .font(.system(size: 52, weight: .bold, design: .rounded))
                            )

                        // Logo with enhanced shadow and border
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white, Color.blue.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 320, height: 320)
                                .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image("CaptainLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                    
                    // Call to action with enhanced styling
                    VStack(spacing: 16) {
                        Text("Track Your Soccer Journey")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [Color.primary, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .mask(
                                Text("Track Your Soccer Journey")
                                    .font(.system(size: 26, weight: .bold))
                            )
                        
                        Text("Log sessions, track progress, reach your goals")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)
                    
                    // Get Started button with modern gradient
                    Button(action: {
                        showingBuildProfile = true
                    }) {
                        HStack(spacing: 12) {
                            Text("GET STARTED")
                                .font(.system(size: 18, weight: .bold))
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(
                        colors: [Color.blue, Color.cyan],
                        foreground: Color.white
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
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        .blendMode(.overlay)
                        .padding(0.5)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: colors.first?.opacity(configuration.isPressed ? 0.3 : 0.5) ?? Color.black.opacity(0.2),
                radius: configuration.isPressed ? 8 : 16,
                x: 0,
                y: configuration.isPressed ? 4 : 8
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
