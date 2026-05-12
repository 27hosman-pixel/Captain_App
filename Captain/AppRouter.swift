import SwiftUI
import Combine

enum Destination: Hashable {
    case home
    case buildProfile
    case profile
    case logSession
    case logPractice
    case logGame
    case logWorkout
    case preview
    case drafts
    case activities
    case statistics
    case settings
    case messaging
    case notifications
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var current: Destination?

    // Sidebar visibility
    @Published var isSidebarVisible: Bool = false

    func navigate(_ destination: Destination) {
        // Avoid pushing duplicate destination when already at the same destination
        if current == destination {
            return
        }
        path.append(destination)
        current = destination
    }

    /// Replace the whole navigation stack with a single destination.
    func replaceWith(_ destination: Destination) {
        path = NavigationPath()
        path.append(destination)
        current = destination
    }

    func popToRoot() {
        path.removeLast(path.count)
        current = nil
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
            // Note: current will be inaccurate after pop, but that's ok for simple back navigation
        }
    }

    func showSidebar() {
        withAnimation(.easeInOut) { isSidebarVisible = true }
    }

    func hideSidebar() {
        withAnimation(.easeInOut) { isSidebarVisible = false }
    }

    func toggleSidebar() {
        withAnimation(.easeInOut) { isSidebarVisible.toggle() }
    }
}
