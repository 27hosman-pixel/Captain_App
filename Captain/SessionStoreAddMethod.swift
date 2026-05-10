import Foundation

/// Extension to SessionStore to add a public method for adding sessions
/// This is needed because SessionStore.sessions is read-only from external code
///
/// INSTRUCTIONS:
/// Add this code directly to your SessionStore.swift file, inside the SessionStore class:
///
/// ```swift
/// func add(session: SessionData) {
///     sessions.append(session)
///     save() // If you have a save method to persist
/// }
/// ```
///
/// OR add a notification observer in SessionStore's init():
///
/// ```swift
/// init() {
///     // ... existing init code ...
///     
///     NotificationCenter.default.addObserver(
///         self,
///         selector: #selector(handleAddSession(_:)),
///         name: Notification.Name("AddSession"),
///         object: nil
///     )
/// }
///
/// @objc private func handleAddSession(_ notification: Notification) {
///     guard let session = notification.userInfo?["session"] as? SessionData else { return }
///     sessions.append(session)
///     save() // If you have a save method
/// }
/// ```

// This file is just documentation - the actual code should go in SessionStore.swift
