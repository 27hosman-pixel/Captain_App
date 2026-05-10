import SwiftUI

// MARK: - Visual Styles

/// Visual design styles for stat cards
/// Each style has a distinct aesthetic optimized for different sharing contexts
enum StatCardVisualStyle: String, CaseIterable, Identifiable {
    case midnight = "Midnight"
    case sunrise = "Sunrise"
    case proStats = "Pro Stats"
    
    var id: String { rawValue }
    
    /// SF Symbol icon representing the style
    var icon: String {
        switch self {
        case .midnight: return "moon.stars.fill"
        case .sunrise: return "sun.max.fill"
        case .proStats: return "chart.bar.fill"
        }
    }
    
    /// Short description of the style's aesthetic
    var description: String {
        switch self {
        case .midnight: return "Dark & Bold"
        case .sunrise: return "Light & Vibrant"
        case .proStats: return "Clean & Professional"
        }
    }
}

// MARK: - Format Sizes

/// Aspect ratios and sizes optimized for different social media platforms
enum StatCardFormat: String, CaseIterable, Identifiable {
    case story = "Story"        // 9:16 - Instagram/Snapchat Stories
    case square = "Square"      // 1:1 - Instagram Feed
    case wide = "Wide"          // 16:9 - Messages/Twitter
    
    var id: String { rawValue }
    
    /// Aspect ratio as CGFloat
    var aspectRatio: CGFloat {
        switch self {
        case .story: return 9.0 / 16.0
        case .square: return 1.0
        case .wide: return 16.0 / 9.0
        }
    }
    
    /// Pixel dimensions for high-quality export
    /// Using standard social media recommended sizes
    var size: CGSize {
        switch self {
        case .story: return CGSize(width: 1080, height: 1920)
        case .square: return CGSize(width: 1080, height: 1080)
        case .wide: return CGSize(width: 1920, height: 1080)
        }
    }
    
    /// Platform recommendations for this format
    var platformHint: String {
        switch self {
        case .story: return "Instagram & Snapchat Stories"
        case .square: return "Instagram Feed"
        case .wide: return "Messages & Twitter"
        }
    }
    
    /// SF Symbol icon representing the format
    var icon: String {
        switch self {
        case .story: return "rectangle.portrait"
        case .square: return "square"
        case .wide: return "rectangle"
        }
    }
}

// MARK: - Helper Extensions

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (e.g., "FF5733" or "#FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
