import Foundation

/// Version-aware feature flag system for Captain app
/// Enables clean separation between V1 (external sharing) and V2 (in-app social) features
enum AppVersion: Comparable {
    case v1_0  // Current: External sharing, personal activity tracking
    case v2_0  // Future: In-app social features (kudos, comments, following)
    
    static let current: AppVersion = .v1_0
}

/// Feature flags control which capabilities are available in the app
/// V2 features are implemented but hidden behind flags for easy activation later
struct FeatureFlags {
    
    // MARK: - V2 Features (Social)
    
    /// In-app social features including kudos, comments, and activity feed interactions
    /// When true, enables social engagement on session cards
    static var inAppSocial: Bool {
        AppVersion.current >= .v2_0
    }
    
    /// Kudos (likes) and commenting system on sessions
    /// Requires inAppSocial to be enabled
    static var kudosAndComments: Bool {
        inAppSocial
    }
    
    /// Following/followers system for user profiles
    /// Requires inAppSocial to be enabled
    static var followSystem: Bool {
        inAppSocial
    }
    
    /// Direct messaging between users
    /// Requires inAppSocial to be enabled
    static var messaging: Bool {
        inAppSocial
    }
    
    /// In-app notifications for social interactions
    /// Requires inAppSocial to be enabled
    static var notifications: Bool {
        inAppSocial
    }
    
    // MARK: - V1 Features (Active)
    
    /// External sharing to social media platforms (Instagram, Snapchat, Messages, etc.)
    static let externalSharing = true
    
    /// Generate beautiful stat cards for sharing
    static let statCardGeneration = true
    
    /// Log sessions (practice, games, workouts)
    static let sessionLogging = true
    
    /// Save and manage draft sessions
    static let drafts = true
    
    /// View statistics and analytics
    static let statistics = true
}
