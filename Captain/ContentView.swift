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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main navigation area
            NavigationStack(path: $router.path) {
                ZStack {
                    Color.white
                        .ignoresSafeArea()

                    VStack {
                        // Landing content only shows when stack is empty
                        if router.path.count == 0 {
                            VStack {
                                Text("CAPTAIN") .font(.system(size: 56, weight: .bold, design: .monospaced))
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
                                    Button(action: { router.navigate(.login) }) {
                                        Text("LOG IN")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.78, green: 0.94, blue: 0.99), Color(red: 0.68, green: 0.91, blue: 0.98)], foreground: .black))

                                    Button(action: { router.navigate(.signup) }) {
                                        Text("SIGN UP")
                                            .font(.headline)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.84, green: 0.87, blue: 0.98), Color(red: 0.72, green: 0.79, blue: 0.96)], foreground: .black))
                                }
                                .padding(.horizontal, 36)
                                .padding(.bottom, 67)
                            }
                        }
                    }
                }
                .navigationBarHidden(router.path.count == 0)
                .navigationDestination(for: Destination.self) { dest in
                    switch dest {
                    case .home:
                        HomeView()
                            .onAppear { router.current = .home }
                    case .login:
                        LoginView()
                            .onAppear { router.current = .login }
                    case .signup:
                        SignUpView()
                            .onAppear { router.current = .signup }
                    case .buildProfile:
                        BuildProfileView()
                            .onAppear { router.current = .buildProfile }
                    case .profile:
                        ProfileView()
                            .environmentObject(sessionStore)
                            .onAppear { router.current = .profile }
                    case .logSession:
                        LogSessionChoiceView()
                            .onAppear { router.current = .logSession }
                    case .logPractice:
                        LogPracticeView()
                            .onAppear { router.current = .logPractice }
                    case .logGame:
                        LogGameView()
                            .onAppear { router.current = .logGame }
                    case .logWorkout:
                        LogWorkoutView()
                            .onAppear { router.current = .logWorkout }
                    case .preview:
                        SessionPreviewView()
                            .onAppear { router.current = .preview }
                    case .activities:
                        ActivitiesView()
                            .onAppear { router.current = .activities }
                    case .statistics:
                        StatisticsView()
                            .onAppear { router.current = .statistics }
                    case .settings:
                        SettingsView()
                            .onAppear { router.current = .settings }
                    case .messaging:
                        MessagingView()
                            .onAppear { router.current = .messaging }
                    case .notifications:
                        NotificationsView()
                            .onAppear { router.current = .notifications }
                    }
                }
                .environmentObject(router)
                .environmentObject(previewStore)
                .environmentObject(sessionStore)
                .onChange(of: router.current) { _, new in
                    print("[Router] current -> \(String(describing: new))")
                }
                .onChange(of: router.path.count) { _, newCount in
                    print("[Router] path.count -> \(newCount)")
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToBuildProfile"))) { _ in
                    Task { @MainActor in
                        router.replaceWith(.buildProfile)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToProfile"))) { _ in
                    Task { @MainActor in
                        router.replaceWith(.profile)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenMessaging"))) { _ in
                    Task { @MainActor in
                        router.navigate(.messaging)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenNotifications"))) { _ in
                    Task { @MainActor in
                        router.navigate(.notifications)
                    }
                }
            }

            // Bottom bar sits outside the NavigationStack so it remains visible for pushed screens
            if shouldShowBottomBar() {
                BottomBarView()
                    .environmentObject(router)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                    .zIndex(1)
            }
        }
        // debug overlay showing current destination (temporary)
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing) {
                Text("current: \(String(describing: router.current))")
                    .font(.caption2)
                    .padding(6)
                    .background(Color.black.opacity(0.06))
                    .cornerRadius(8)
                    .padding()
                Spacer()
            }
        }
    }

    private func shouldShowBottomBar() -> Bool {
        // show when there's a pushed view and we're not on login/signup or buildProfile
        if router.path.count == 0 { return false }
        if let current = router.current {
            return current != .login && current != .signup && current != .buildProfile
        }
        // fallback: show when path has elements
        return router.path.count > 0
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

                    // soft inner highlight
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

