import SwiftUI

import SwiftUI

/// Light, vibrant stat card with warm gradients
/// Optimized for positive, motivational sharing
struct SunriseCardView: View {
    let title: String
    let sessionType: String
    let date: Date
    let location: String
    let stats: [(label: String, value: String)]
    let format: StatCardFormat
    let heroImage: UIImage?
    
    var body: some View {
        ZStack {
            if let heroImage = heroImage {
                // Hero photo background with warm gradient overlay
                heroPhotoBackground(image: heroImage)
            } else {
                // Original warm gradient background (no photo)
                originalGradientBackground
            }
            
            // Content layer
            contentLayer
        }
        .frame(width: format.size.width, height: format.size.height)
    }
    
    // MARK: - Background Layers
    
    /// Hero photo with warm, vibrant gradient overlay
    @ViewBuilder
    private func heroPhotoBackground(image: UIImage) -> some View {
        ZStack {
            // Photo background
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: format.size.width, height: format.size.height)
                .clipped()
                .opacity(0.6) // Keep photo more visible for vibrant style
            
            // Warm gradient overlay (lighter than Midnight)
            LinearGradient(
                colors: [
                    Color(hex: "FFE66D").opacity(0.3),
                    Color(hex: "FFA07A").opacity(0.6),
                    Color(hex: "FF6B6B").opacity(0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Decorative circles
            decorativeCircles
        }
    }
    
    /// Original gradient background (when no photo)
    @ViewBuilder
    private var originalGradientBackground: some View {
        ZStack {
            // Warm gradient background
            LinearGradient(
                colors: [
                    Color(hex: "FFE66D"),
                    Color(hex: "FF6B6B"),
                    Color(hex: "FFA07A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative circles
            decorativeCircles
        }
    }
    
    /// Decorative circles overlay
    @ViewBuilder
    private var decorativeCircles: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -100)
            
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: geo.size.width - 100, y: geo.size.height - 100)
        }
    }
    
    // MARK: - Content Layer
    
    @ViewBuilder
    private var contentLayer: some View {
            VStack(spacing: format == .story ? 48 : 32) {
                Spacer()
                
                // Emoji for session type (playful)
                Text(sessionTypeEmoji)
                    .font(.system(size: emojiSize))
                
                // Title
                Text(title)
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "2D3436"))
                    .multilineTextAlignment(.center)
                    .lineLimit(format == .wide ? 1 : 3)
                    .padding(.horizontal, horizontalPadding)
                
                // Session type badge
                Text(sessionType.uppercased())
                    .font(.system(size: badgeTextSize, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color(hex: "2D3436"))
                    )
                
                // Stats grid
                statsGrid
                    .padding(.horizontal, horizontalPadding)
                
                // Date and location
                VStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.system(size: metadataSize, weight: .bold))
                        .foregroundColor(Color(hex: "2D3436").opacity(0.8))
                    
                    if !location.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: metadataSize))
                            Text(location)
                                .font(.system(size: metadataSize, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "2D3436").opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Branding
                HStack(spacing: 10) {
                    Text("🔥")
                        .font(.system(size: brandingEmojiSize))
                    Text("Logged with Captain")
                        .font(.system(size: brandingTextSize, weight: .bold))
                        .foregroundColor(Color(hex: "2D3436").opacity(0.6))
                }
                .padding(.bottom, format == .story ? 40 : 20)
            }
    }
    
    // MARK: - Stats Grid
    
    @ViewBuilder
    private var statsGrid: some View {
        let columns = format == .story ? 2 : 3
        let displayStats = Array(stats.prefix(format == .story ? 4 : 6))
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: columns), spacing: gridSpacing) {
            ForEach(Array(displayStats.enumerated()), id: \.offset) { _, stat in
                VStack(spacing: 8) {
                    Text(stat.value)
                        .font(.system(size: statValueSize, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "2D3436"))
                    
                    Text(stat.label.uppercased())
                        .font(.system(size: statLabelSize, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "2D3436").opacity(0.7))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.4))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private var sessionTypeEmoji: String {
        switch sessionType.lowercased() {
        case "game": return "⚽"
        case "practice": return "🏃"
        case "training", "workout": return "💪"
        default: return "⚽"
        }
    }
    
    // MARK: - Dynamic Sizing
    
    private var emojiSize: CGFloat {
        switch format {
        case .story: return 80
        case .square: return 64
        case .wide: return 72
        }
    }
    
    private var titleSize: CGFloat {
        switch format {
        case .story: return 52
        case .square: return 44
        case .wide: return 48
        }
    }
    
    private var badgeTextSize: CGFloat {
        format == .story ? 16 : 14
    }
    
    private var statValueSize: CGFloat {
        switch format {
        case .story: return 44
        case .square: return 38
        case .wide: return 40
        }
    }
    
    private var statLabelSize: CGFloat {
        switch format {
        case .story: return 14
        case .square: return 12
        case .wide: return 13
        }
    }
    
    private var metadataSize: CGFloat {
        format == .story ? 18 : 16
    }
    
    private var brandingEmojiSize: CGFloat {
        format == .story ? 28 : 24
    }
    
    private var brandingTextSize: CGFloat {
        format == .story ? 18 : 16
    }
    
    private var horizontalPadding: CGFloat {
        switch format {
        case .story: return 60
        case .square: return 40
        case .wide: return 80
        }
    }
    
    private var gridSpacing: CGFloat {
        format == .story ? 16 : 12
    }
}

// MARK: - Preview

#Preview("Sunrise - Square") {
    SunriseCardView(
        title: "Morning Training Session",
        sessionType: "Practice",
        date: Date(),
        location: "City Park",
        stats: [
            ("Goals", "5"),
            ("Minutes", "60"),
            ("Drills", "12"),
            ("Sprints", "15"),
            ("Passes", "82"),
            ("Saves", "7")
        ],
        format: .square,
        heroImage: nil
    )
}

#Preview("Sunrise - Story") {
    SunriseCardView(
        title: "Great Game! 🎉",
        sessionType: "Game",
        date: Date(),
        location: "Riverside Stadium",
        stats: [
            ("Goals", "3"),
            ("Assists", "2"),
            ("Minutes", "90"),
            ("Shots", "8")
        ],
        format: .story,
        heroImage: nil
    )
}
