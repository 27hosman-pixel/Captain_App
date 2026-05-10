//
//  Theme.swift
//  Captain
//
//  Design system inspired by Strava's clean, professional aesthetic
//  Strict 8pt grid system with semantic typography
//

import SwiftUI

/// Captain app design system
/// Provides standardized spacing, typography, and component styling
struct Theme {
    
    // MARK: - Typography
    
    /// Semantic font styles following Apple's Dynamic Type system
    struct Typography {
        // Screen titles (e.g., "My Profile", "Stats")
        static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
        
        // Section headers (e.g., "MY STATS", "Goals", "About")
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        
        // Card titles, primary labels
        static let title3 = Font.system(.title3, design: .default, weight: .bold)
        
        // Secondary labels, button text
        static let subheadline = Font.system(.subheadline, design: .default, weight: .medium)
        
        // Supporting text, metadata
        static let caption = Font.system(.caption, design: .default, weight: .regular)
        static let caption2 = Font.system(.caption2, design: .default, weight: .regular)
        
        // Body text
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let bodyMedium = Font.system(.body, design: .default, weight: .medium)
    }
    
    // MARK: - Spacing (8pt Grid System)
    
    /// All spacing follows 8pt increments for visual consistency
    struct Spacing {
        static let xxs: CGFloat = 4      // Minimal spacing (exception to 8pt rule)
        static let xs: CGFloat = 8       // Tight spacing
        static let sm: CGFloat = 12      // Small spacing (exception for specific needs)
        static let md: CGFloat = 16      // Standard spacing
        static let lg: CGFloat = 24      // Large spacing
        static let xl: CGFloat = 32      // Extra large spacing
        static let xxl: CGFloat = 40     // Screen-level spacing
        static let xxxl: CGFloat = 48    // Hero spacing
    }
    
    // MARK: - Corner Radius
    
    /// Consistent border radius for cards and containers
    struct CornerRadius {
        static let sm: CGFloat = 8       // Tight radius
        static let md: CGFloat = 12      // Standard cards
        static let lg: CGFloat = 16      // Large containers
        static let pill: CGFloat = 100   // Capsule/pill shapes
    }
    
    // MARK: - Icon Sizing
    
    /// Standardized icon sizes for SF Symbols
    struct IconSize {
        static let sm: CGFloat = 16      // Small inline icons
        static let md: CGFloat = 20      // Standard icons
        static let lg: CGFloat = 24      // Large icons
        static let xl: CGFloat = 28      // Extra large icons
    }
    
    // MARK: - Colors
    
    /// Semantic color definitions (preserving existing palette)
    struct Colors {
        // Primary colors (existing)
        static let primary = Color.blue
        static let success = Color.green
        static let text = Color.primary
        static let secondaryText = Color.secondary
        
        // Background colors
        static let cardBackground = Color(.secondarySystemBackground)
        static let surface = Color(.systemBackground)
        static let divider = Color(.separator)
        
        // Accent for hero sections
        static let heroBlue = Color.blue.opacity(0.85)
        static let heroBlueLight = Color.blue.opacity(0.55)
    }
    
    // MARK: - Shadows
    
    /// Subtle shadow definitions for depth
    struct Shadow {
        static let sm = (color: Color.black.opacity(0.03), radius: 4.0, x: 0.0, y: 2.0)
        static let md = (color: Color.black.opacity(0.05), radius: 8.0, x: 0.0, y: 4.0)
        static let lg = (color: Color.black.opacity(0.08), radius: 12.0, x: 0.0, y: 6.0)
    }
}

// MARK: - View Extensions for Easy Application

extension View {
    
    // MARK: Typography Modifiers
    
    func largeTitle() -> some View {
        self.font(Theme.Typography.largeTitle)
    }
    
    func sectionHeader() -> some View {
        self.font(Theme.Typography.headline)
    }
    
    func cardTitle() -> some View {
        self.font(Theme.Typography.title3)
    }
    
    func subtitle() -> some View {
        self.font(Theme.Typography.subheadline)
            .foregroundColor(Theme.Colors.secondaryText)
    }
    
    func caption() -> some View {
        self.font(Theme.Typography.caption)
            .foregroundColor(Theme.Colors.secondaryText)
    }
    
    // MARK: Card Styling
    
    /// Standard card container with consistent styling
    func cardStyle(padding: CGFloat = Theme.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.divider, lineWidth: 0.5)
            )
            .shadow(
                color: Theme.Shadow.sm.color,
                radius: Theme.Shadow.sm.radius,
                x: Theme.Shadow.sm.x,
                y: Theme.Shadow.sm.y
            )
    }
    
    /// Stat tile styling (used in grids)
    func statTileStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.divider, lineWidth: 0.5)
            )
    }
}

// MARK: - Standardized Components

/// Section divider with consistent spacing
struct ThemeDivider: View {
    var body: some View {
        Divider()
            .padding(.vertical, Theme.Spacing.xs)
    }
}

/// Section header with consistent styling
struct ThemeSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(Theme.Typography.headline)
            .foregroundColor(Theme.Colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xs)
    }
}

/// Edit button component (reusable across Profile, Goals, About)
struct ThemeEditButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label("Edit", systemImage: "pencil")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.text)
                .padding(.vertical, Theme.Spacing.xs)
                .padding(.horizontal, Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
}

/// Stat card for grid layouts
struct ThemeStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(value)
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.text)
        }
        .statTileStyle()
    }
}

/// Info row for About section grids
struct ThemeInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text(value.isEmpty ? "—" : value)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Button Styles

/// Primary action button style
struct ThemePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.subheadline)
            .foregroundColor(.white)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.primary)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Secondary action button style
struct ThemeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.subheadline)
            .foregroundColor(Theme.Colors.text)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.divider, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
