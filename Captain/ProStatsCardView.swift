import SwiftUI

import SwiftUI

/// Clean, professional stat card with data-focused design
/// Optimized for formal sharing and coaching reviews
struct ProStatsCardView: View {
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
                // Hero photo background with clean white overlay
                heroPhotoBackground(image: heroImage)
            } else {
                // Original clean white background (no photo)
                Color.white
            }
            
            // Content layer
            contentLayer
        }
        .frame(width: format.size.width, height: format.size.height)
    }
    
    // MARK: - Background Layers
    
    /// Hero photo with professional clean overlay
    @ViewBuilder
    private func heroPhotoBackground(image: UIImage) -> some View {
        ZStack {
            // Photo background
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: format.size.width, height: format.size.height)
                .clipped()
                .opacity(0.25) // Very subtle - keep it professional
            
            // White overlay with gradient for readability
            LinearGradient(
                colors: [
                    Color.white.opacity(0.85),
                    Color.white.opacity(0.92),
                    Color.white.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Content Layer
    
    @ViewBuilder
    private var contentLayer: some View {
            VStack(spacing: format == .story ? 40 : 28) {
                // Header
                VStack(spacing: 16) {
                    // Logo/Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "007AFF").opacity(0.1))
                            .frame(width: iconCircleSize, height: iconCircleSize)
                        
                        Image(systemName: sessionTypeIcon)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundColor(Color(hex: "007AFF"))
                    }
                    
                    // Title
                    Text(title)
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundColor(Color(hex: "1C1C1E"))
                        .multilineTextAlignment(.center)
                        .lineLimit(format == .wide ? 1 : 2)
                        .padding(.horizontal, horizontalPadding)
                    
                    // Session type
                    Text(sessionType.uppercased())
                        .font(.system(size: subtitleSize, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color(hex: "007AFF"))
                }
                .padding(.top, format == .story ? 60 : 40)
                
                // Divider
                Rectangle()
                    .fill(Color(hex: "E5E5EA"))
                    .frame(height: 2)
                    .frame(maxWidth: format == .story ? 400 : 600)
                
                // Stats grid (table-like layout)
                statsGrid
                    .padding(.horizontal, horizontalPadding)
                
                // Divider
                Rectangle()
                    .fill(Color(hex: "E5E5EA"))
                    .frame(height: 2)
                    .frame(maxWidth: format == .story ? 400 : 600)
                
                Spacer()
                
                // Metadata
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: metadataIconSize, weight: .medium))
                        Text(formattedDate)
                            .font(.system(size: metadataSize, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "3A3A3C"))
                    
                    if !location.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: metadataIconSize, weight: .medium))
                            Text(location)
                                .font(.system(size: metadataSize, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "3A3A3C"))
                    }
                }
                
                // Branding (subtle)
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: brandingIconSize))
                        .foregroundColor(Color(hex: "007AFF"))
                    Text("Captain")
                        .font(.system(size: brandingTextSize, weight: .semibold))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .padding(.bottom, format == .story ? 60 : 40)
            }
    }
    
    // MARK: - Stats Grid
    
    @ViewBuilder
    private var statsGrid: some View {
        let displayStats = Array(stats.prefix(format == .story ? 6 : 9))
        let columns = format == .story ? 2 : 3
        
        VStack(spacing: 1) {
            ForEach(Array(stride(from: 0, to: displayStats.count, by: columns)), id: \.self) { rowIndex in
                HStack(spacing: 1) {
                    ForEach(0..<columns, id: \.self) { colIndex in
                        let index = rowIndex + colIndex
                        if index < displayStats.count {
                            let stat = displayStats[index]
                            statCell(label: stat.label, value: stat.value)
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
        .background(Color(hex: "E5E5EA"))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: statValueSize, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "1C1C1E"))
            
            Text(label)
                .font(.system(size: statLabelSize, weight: .medium))
                .foregroundColor(Color(hex: "3A3A3C"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, cellPadding)
        .background(Color.white)
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
    
    private var iconCircleSize: CGFloat {
        switch format {
        case .story: return 80
        case .square: return 64
        case .wide: return 72
        }
    }
    
    private var iconSize: CGFloat {
        switch format {
        case .story: return 40
        case .square: return 32
        case .wide: return 36
        }
    }
    
    private var titleSize: CGFloat {
        switch format {
        case .story: return 44
        case .square: return 36
        case .wide: return 40
        }
    }
    
    private var subtitleSize: CGFloat {
        format == .story ? 16 : 14
    }
    
    private var statValueSize: CGFloat {
        switch format {
        case .story: return 36
        case .square: return 32
        case .wide: return 34
        }
    }
    
    private var statLabelSize: CGFloat {
        switch format {
        case .story: return 14
        case .square: return 12
        case .wide: return 13
        }
    }
    
    private var cellPadding: CGFloat {
        format == .story ? 20 : 16
    }
    
    private var metadataSize: CGFloat {
        format == .story ? 18 : 16
    }
    
    private var metadataIconSize: CGFloat {
        format == .story ? 16 : 14
    }
    
    private var brandingIconSize: CGFloat {
        format == .story ? 18 : 16
    }
    
    private var brandingTextSize: CGFloat {
        format == .story ? 16 : 14
    }
    
    private var horizontalPadding: CGFloat {
        switch format {
        case .story: return 60
        case .square: return 40
        case .wide: return 80
        }
    }
}

// MARK: - Preview

#Preview("Pro Stats - Square") {
    ProStatsCardView(
        title: "Championship Game",
        sessionType: "Game",
        date: Date(),
        location: "National Stadium",
        stats: [
            ("Goals", "2"),
            ("Assists", "1"),
            ("Minutes", "90"),
            ("Tackles", "8"),
            ("Passes", "42"),
            ("Accuracy", "87%"),
            ("Distance", "6.2 km"),
            ("Sprints", "23"),
            ("Fouls", "1")
        ],
        format: .square,
        heroImage: nil
    )
}

#Preview("Pro Stats - Story") {
    ProStatsCardView(
        title: "Training Session",
        sessionType: "Practice",
        date: Date(),
        location: "Training Ground",
        stats: [
            ("Goals", "8"),
            ("Minutes", "75"),
            ("Drills", "15"),
            ("Sprints", "20"),
            ("Distance", "4.5 km"),
            ("Heart Rate", "145 bpm")
        ],
        format: .story,
        heroImage: nil
    )
}
