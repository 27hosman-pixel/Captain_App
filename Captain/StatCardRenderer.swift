import SwiftUI
import UIKit

/// Utility for rendering SwiftUI stat card views to UIImage using ImageRenderer
/// Handles conversion from session data to shareable images
@MainActor
struct StatCardRenderer {
    
    /// Render a stat card from PreviewStore data
    /// - Parameters:
    ///   - previewStore: The preview store containing session data
    ///   - style: Visual style for the card
    ///   - format: Size/aspect ratio format
    /// - Returns: Rendered UIImage, or nil if rendering fails
    static func render(
        from previewStore: PreviewStore,
        style: StatCardVisualStyle,
        format: StatCardFormat
    ) async -> UIImage? {
        let stats = extractStats(from: previewStore.details)
        let heroImage = previewStore.images.first // Use first image as hero photo
        
        // Debug logging
        print("📸 StatCardRenderer: Rendering card with \(previewStore.images.count) images available")
        if let image = heroImage {
            print("📸 StatCardRenderer: Using hero image with size \(image.size)")
        } else {
            print("📸 StatCardRenderer: No hero image available")
        }
        
        return await renderCard(
            title: previewStore.title,
            sessionType: previewStore.sessionType,
            date: previewStore.date,
            location: previewStore.location,
            stats: stats,
            style: style,
            format: format,
            heroImage: heroImage
        )
    }
    
    /// Render a stat card from SessionData (for saved sessions)
    /// - Parameters:
    ///   - sessionData: The session data to render
    ///   - style: Visual style for the card
    ///   - format: Size/aspect ratio format
    /// - Returns: Rendered UIImage, or nil if rendering fails
    static func render(
        from sessionData: SessionData,
        style: StatCardVisualStyle,
        format: StatCardFormat
    ) async -> UIImage? {
        let stats = extractStats(from: sessionData.details)
        
        // Load first image from disk if available
        let heroImage = loadSessionImage(fileName: sessionData.imageFileNames.first)
        
        return await renderCard(
            title: sessionData.title,
            sessionType: sessionData.sessionType,
            date: sessionData.date,
            location: sessionData.location,
            stats: stats,
            style: style,
            format: format,
            heroImage: heroImage
        )
    }
    
    // MARK: - Private Rendering
    
    /// Core rendering function that creates the actual image
    private static func renderCard(
        title: String,
        sessionType: String,
        date: Date,
        location: String,
        stats: [(label: String, value: String)],
        style: StatCardVisualStyle,
        format: StatCardFormat,
        heroImage: UIImage?
    ) async -> UIImage? {
        // Create the appropriate card view based on style
        let cardView = createCardView(
            title: title,
            sessionType: sessionType,
            date: date,
            location: location,
            stats: stats,
            style: style,
            format: format,
            heroImage: heroImage
        )
        
        // Use ImageRenderer to convert SwiftUI view to UIImage
        let renderer = ImageRenderer(content: cardView)
        
        // Set scale for high quality - use windowScene scale
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            renderer.scale = windowScene.screen.scale
        } else {
            // Fallback to 3x scale (standard for modern devices)
            renderer.scale = 3.0
        }
        
        // Render the image
        // This happens synchronously but we're already on MainActor
        return renderer.uiImage
    }
    
    /// Factory method to create the correct card view based on style
    @ViewBuilder
    private static func createCardView(
        title: String,
        sessionType: String,
        date: Date,
        location: String,
        stats: [(label: String, value: String)],
        style: StatCardVisualStyle,
        format: StatCardFormat,
        heroImage: UIImage?
    ) -> some View {
        switch style {
        case .midnight:
            MidnightCardView(
                title: title,
                sessionType: sessionType,
                date: date,
                location: location,
                stats: stats,
                format: format,
                heroImage: heroImage
            )
        case .sunrise:
            SunriseCardView(
                title: title,
                sessionType: sessionType,
                date: date,
                location: location,
                stats: stats,
                format: format,
                heroImage: heroImage
            )
        case .proStats:
            ProStatsCardView(
                title: title,
                sessionType: sessionType,
                date: date,
                location: location,
                stats: stats,
                format: format,
                heroImage: heroImage
            )
        }
    }
    
    // MARK: - Data Extraction
    
    /// Load image from SessionData filename
    private static func loadSessionImage(fileName: String?) -> UIImage? {
        guard let fileName = fileName,
              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// Extract and format stats from session details dictionary
    /// Prioritizes key stats and formats them nicely
    private static func extractStats(from details: [String: String]) -> [(label: String, value: String)] {
        var stats: [(label: String, value: String)] = []
        
        // Priority order for common stats
        let priorityKeys = [
            "Goals", "Assists", "Minutes", "Tackles", "Shots", "Saves",
            "Passes", "Distance", "TotalMiles", "Avg HR", "Heart Rate",
            "Sprints", "Drills", "Opponent", "Final Score"
        ]
        
        // Add priority stats first
        for key in priorityKeys {
            if let value = details[key], !value.isEmpty, value != "0" {
                stats.append((label: formatLabel(key), value: value))
            }
        }
        
        // Add remaining stats (excluding notes and empty values)
        for (key, value) in details.sorted(by: { $0.key < $1.key }) {
            guard !priorityKeys.contains(key),
                  !value.isEmpty,
                  value != "0",
                  key.lowercased() != "notes" else { continue }
            
            stats.append((label: formatLabel(key), value: value))
        }
        
        return stats
    }
    
    /// Format stat labels for display (convert "TotalMiles" to "Miles", etc.)
    private static func formatLabel(_ key: String) -> String {
        switch key {
        case "TotalMiles": return "Miles"
        case "Avg HR": return "Avg HR"
        case "Final Score": return "Score"
        default: return key
        }
    }
}

// MARK: - SessionData Protocol Conformance Helper

/// Since we don't have access to the full SessionData definition,
/// we create a minimal protocol that both PreviewStore and SessionData can conform to
protocol ShareableSession {
    var title: String { get }
    var sessionType: String { get }
    var date: Date { get }
    var location: String { get }
    var details: [String: String] { get }
}

// PreviewStore already has these properties via @Published
// SessionData should also have these (based on usage in your codebase)
