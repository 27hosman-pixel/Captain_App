// AuthStore.swift
import Foundation
import SwiftUI
import Combine

struct AuthSession: Codable, Equatable {
    var userId: String
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var userId: String?
    @AppStorage("has_completed_profile") var hasCompletedProfile: Bool = false

    private let keychainService = "com.captain.auth"
    private let keychainAccount = "current_user_id"

    init() {
        loadFromKeychain()
    }

    private func loadFromKeychain() {
        if let stored = KeychainHelper.read(service: keychainService, account: keychainAccount) {
            userId = stored
            isAuthenticated = true
        } else {
            userId = nil
            isAuthenticated = false
        }
    }

    private func persist(userId: String) {
        if KeychainHelper.save(userId, service: keychainService, account: keychainAccount) {
            self.userId = userId
            self.isAuthenticated = true
        } else {
            // If save fails, keep unauthenticated
            self.userId = nil
            self.isAuthenticated = false
        }
    }

    func login(email: String, password: String) async throws {
        // TODO: Replace with real API call. For now, fake a userId derived from email.
        try await Task.sleep(nanoseconds: 200_000_000) // simulate latency
        let fakeUserId = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        persist(userId: fakeUserId)
        // hasCompletedProfile remains whatever it was last time; leave as-is
    }

    func signup(firstName: String, lastName: String, email: String, password: String) async throws {
        // TODO: Replace with real API call. For now, fake a new userId.
        try await Task.sleep(nanoseconds: 250_000_000)
        let fakeUserId = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        persist(userId: fakeUserId)
        hasCompletedProfile = false
    }

    func logout() {
        KeychainHelper.delete(service: keychainService, account: keychainAccount)
        userId = nil
        isAuthenticated = false
        hasCompletedProfile = false
    }

    func markProfileCompleted() {
        hasCompletedProfile = true
    }
}
