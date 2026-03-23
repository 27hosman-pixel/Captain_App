import SwiftUI
import Combine

enum Destination: Hashable {
    case home
    case login
    case signup
    case buildProfile
    case profile
    case logSession
    case settings
}

final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var current: Destination?

    func navigate(_ destination: Destination) {
        // Avoid pushing duplicate destination when already at the same destination
        if current == destination {
            return
        }
        path.append(destination)
        current = destination
    }

    func popToRoot() {
        path.removeLast(path.count)
        current = nil
    }
}
