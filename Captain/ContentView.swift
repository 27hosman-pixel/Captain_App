//
//  ContentView.swift
//  Captain
//
//  Created by Hana Osman on 3/4/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var router = AppRouter()
    @StateObject private var previewStore = PreviewStore()
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var feedFilters = FeedFilters()
    @EnvironmentObject var authStore: AuthStore

    // Tab selection
    private enum Tab: Hashable {
        case home, profile, log, stats, settings
    }
    @State private var selectedTab: Tab = .home

    // Per-tab navigation paths
    @State private var homePath = NavigationPath()
    @State private var profilePath = NavigationPath()
    @State private var logPath = NavigationPath()
    @State private var statsPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    var body: some View {
        ZStack {
            if !authStore.isAuthenticated {
                landingView
            } else if authStore.isAuthenticated && !authStore.hasCompletedProfile {
                NavigationStack {
                    BuildProfileView()
                }
                .environmentObject(authStore)
            } else {
                TabView(selection: $selectedTab) {
                    // Home tab
                    NavigationStack(path: $homePath) {
                        HomeView()
                            .environmentObject(sessionStore)
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
                            .environmentObject(sessionStore)
                            .environmentObject(feedFilters)
                            .navigationDestination(for: Destination.self) { dest in
                                destinationView(for: dest)
                            }
                    }
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .tag(Tab.profile)

                    // Log tab (hub -> practice/game/workout/preview)
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
                            .environmentObject(sessionStore)
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
                .onAppear { routeForAuthState() }
                .onChange(of: authStore.isAuthenticated) { _, _ in routeForAuthState() }
                .onChange(of: authStore.hasCompletedProfile) { _, _ in routeForAuthState() }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToBuildProfile"))) { _ in
                    selectedTab = .profile
                    clearAllPaths()
                    authToBuildProfile()
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToProfile"))) { _ in
                    selectedTab = .profile
                    clearAllPaths()
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
            }
        }
        .environmentObject(router)
        .environmentObject(previewStore)
        .environmentObject(sessionStore)
        .environmentObject(feedFilters)
        .environmentObject(authStore)
    }

    // MARK: - Landing

    private var landingView: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.white.ignoresSafeArea()
                VStack {
                    VStack {
                        Text("CAPTAIN")
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.top, 48)
                            .frame(maxWidth: .infinity, alignment: .center)

                        Spacer(minLength: 8)

                        Image("CaptainLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 350)
                            .padding(.bottom, 64)

                        Spacer().frame(height: 12)

                        VStack(spacing: 18) {
                            NavigationStack {
                                VStack(spacing: 18) {
                                    Button(action: {
                                        // Present login inline
                                        router.current = .login
                                    }) {
                                        Text("LOG IN")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.78, green: 0.94, blue: 0.99), Color(red: 0.68, green: 0.91, blue: 0.98)], foreground: .black))

                                    Button(action: {
                                        router.current = .signup
                                    }) {
                                        Text("SIGN UP")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.84, green: 0.87, blue: 0.98), Color(red: 0.72, green: 0.79, blue: 0.96)], foreground: .black))
                                }
                                .padding(.horizontal, 36)
                                .padding(.bottom, 67)
                                .navigationDestination(isPresented: Binding(get: { router.current == .login }, set: { shown in
                                    if !shown { router.current = nil }
                                })) {
                                    LoginView()
                                }
                                .navigationDestination(isPresented: Binding(get: { router.current == .signup }, set: { shown in
                                    if !shown { router.current = nil }
                                })) {
                                    SignUpView()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func destinationView(for dest: Destination) -> some View {
        Group {
            switch dest {
            case .home:
                HomeView()
            case .login:
                LoginView()
            case .signup:
                SignUpView()
            case .buildProfile:
                BuildProfileView()
            case .profile:
                ProfileView().environmentObject(sessionStore)
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
            // maintain router.current for any code relying on it
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

    private func authToBuildProfile() {
        // When invoked, we’re authenticated but profile incomplete.
        // Show BuildProfile by selecting any tab and pushing it, or by replacing with a dedicated stack.
        selectedTab = .profile
        profilePath.append(Destination.buildProfile)
    }

    private func routeForAuthState() {
        if authStore.isAuthenticated {
            if authStore.hasCompletedProfile {
                selectedTab = .profile
            } else {
                authToBuildProfile()
            }
        } else {
            // no-op; landingView is shown
        }
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
        .environmentObject(AuthStore())
}
