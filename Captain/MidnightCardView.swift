import SwiftUI

/// Dark gradient stat card with neon accents
/// Optimized for social media sharing with high visual impact
struct MidnightCardView: View {
    let title: String
    let sessionType: String
    let date: Date
    let location: String
    let stats: [(label: String, value: String)]
    let format: StatCardFormat
    
    var body: some View {
        ZStack {
            // Background gradient - deep purples and blues
            LinearGradient(
                colors: [
                    Color(hex: "0f0c29"),
                    Color(hex: "302b63"),
                    Color(hex: "24243e")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle grid pattern overlay
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 40
                    // Vertical lines
                    for i in stride(from: 0, to: geo.size.width, by: spacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i, y: geo.size.height))
                    }
                    // Horizontal lines
                    for i in stride(from: 0, to: geo.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: i))
                        path.addLine(to: CGPoint(x: geo.size.width, y: i))
                    }
                }
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
            }
            
            // Content
            VStack(spacing: format == .story ? 48 : 32) {
                Spacer()
                
                // Title
                Text(title)
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(format == .wide ? 1 : 3)
                    .padding(.horizontal, horizontalPadding)
                
                // Session type badge
                HStack(spacing: 8) {
                    Image(systemName: sessionTypeIcon)
                        .font(.system(size: badgeIconSize, weight: .semibold))
                    Text(sessionType.uppercased())
                        .font(.system(size: badgeTextSize, weight: .bold, design: .rounded))
                        .tracking(2)
                }
                .foregroundColor(Color(hex: "00f2fe"))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "00f2fe").opacity(0.3), lineWidth: 2)
                        )
                )
                
                // Stats grid
                statsGrid
                    .padding(.horizontal, horizontalPadding)
                
                // Date and location
                VStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.system(size: metadataSize, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    if !location.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: metadataSize - 2))
                            Text(location)
                                .font(.system(size: metadataSize, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Branding
                HStack(spacing: 12) {
                    Text("⚽")
                        .font(.system(size: brandingEmojiSize))
                    Text("Logged with Captain")
                        .font(.system(size: brandingTextSize, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, format == .story ? 40 : 20)
            }
        }
        .frame(width: format.size.width, height: format.size.height)
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
                        .font(.system(size: statValueSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(stat.label.uppercased())
                        .font(.system(size: statLabelSize, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "00f2fe").opacity(0.8))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private var sessionTypeIcon: String {
        switch sessionType.lowercased() {
        case "game": return "sportscourt.fill"
        case "practice": return "figure.run"
        case "training", "workout": return "dumbbell.fill"
        default: return "sportscourt.fill"
        }
    }
    
    // MARK: - Dynamic Sizing
    
    private var titleSize: CGFloat {
        switch format {
        case .story: return 56
        case .square: return 48
        case .wide: return 52
        }
    }
    
    private var badgeIconSize: CGFloat {
        format == .story ? 20 : 18
    }
    
    private var badgeTextSize: CGFloat {
        format == .story ? 16 : 14
    }
    
    private var statValueSize: CGFloat {
        switch format {
        case .story: return 40
        case .square: return 36
        case .wide: return 38
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
        format == .story ? 20 : 18
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

#Preview("Midnight - Square") {
    MidnightCardView(
        title: "Saturday League Match",
        sessionType: "Game",
        date: Date(),
        location: "Riverside Stadium",
        stats: [
            ("Goals", "2"),
            ("Assists", "1"),
            ("Minutes", "90"),
            ("Tackles", "8"),
            ("Shots", "5"),
            ("Passes", "42")
        ],
        format: .square
    )
}

#Preview("Midnight - Story") {
    MidnightCardView(
        title: "Weekend Training",
        sessionType: "Practice",
        date: Date(),
        location: "City Park",
        stats: [
            ("Goals", "5"),
            ("Minutes", "60"),
            ("Drills", "12"),
            ("Distance", "3.2 mi")
        ],
        format: .story
    )
}
