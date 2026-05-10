# Captain App Theme System Guide

## Overview

The Captain app now features a **unified design system** inspired by Strava's clean, professional aesthetic. This system enforces consistency across all screens through:

- **8pt Grid System**: All spacing uses multiples of 8 (with strategic exceptions)
- **Semantic Typography**: Apple's Dynamic Type with consistent hierarchy
- **Standardized Components**: Reusable cards, buttons, and UI elements
- **Consistent Colors**: Preserved existing blue/green palette

---

## Theme Structure

### 1. Typography (`Theme.Typography`)

**Semantic font styles** that adapt to user accessibility settings:

```swift
Theme.Typography.largeTitle      // Screen titles (e.g., "My Profile", "Stats")
Theme.Typography.headline        // Section headers (e.g., "Goals", "About")
Theme.Typography.title3          // Card titles, stat values
Theme.Typography.subheadline     // Secondary labels, button text
Theme.Typography.caption         // Supporting text, metadata
Theme.Typography.caption2        // Smallest text
Theme.Typography.body            // Standard body text
Theme.Typography.bodyMedium      // Emphasized body text
```

**Example Usage:**
```swift
Text("MY STATS")
    .font(Theme.Typography.headline)

Text("Profile link ready to share")
    .font(Theme.Typography.subheadline)
```

---

### 2. Spacing (`Theme.Spacing`)

**8pt Grid System** for visual rhythm:

```swift
Theme.Spacing.xxs    // 4pt  - Minimal spacing (strategic exception)
Theme.Spacing.xs     // 8pt  - Tight spacing
Theme.Spacing.sm     // 12pt - Small spacing (strategic exception)
Theme.Spacing.md     // 16pt - Standard spacing (most common)
Theme.Spacing.lg     // 24pt - Large spacing
Theme.Spacing.xl     // 32pt - Extra large spacing
Theme.Spacing.xxl    // 40pt - Screen-level spacing
Theme.Spacing.xxxl   // 48pt - Hero spacing
```

**Example Usage:**
```swift
VStack(spacing: Theme.Spacing.md) {
    // Content
}
.padding(.horizontal, Theme.Spacing.md)
```

---

### 3. Corner Radius (`Theme.CornerRadius`)

**Consistent border radius** for cards and containers:

```swift
Theme.CornerRadius.sm     // 8pt  - Tight radius (small elements)
Theme.CornerRadius.md     // 12pt - Standard cards
Theme.CornerRadius.lg     // 16pt - Large containers
Theme.CornerRadius.pill   // 100pt - Capsule/pill shapes
```

**Example Usage:**
```swift
RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
    .fill(Theme.Colors.cardBackground)
```

---

### 4. Icon Sizing (`Theme.IconSize`)

**Standardized SF Symbol sizes:**

```swift
Theme.IconSize.sm    // 16pt - Small inline icons
Theme.IconSize.md    // 20pt - Standard icons
Theme.IconSize.lg    // 24pt - Large icons
Theme.IconSize.xl    // 28pt - Extra large icons
```

**Example Usage:**
```swift
Image(systemName: "chevron.right")
    .font(.system(size: Theme.IconSize.sm, weight: .medium))
```

---

### 5. Colors (`Theme.Colors`)

**Semantic color definitions** (existing palette preserved):

```swift
Theme.Colors.primary           // Blue (existing)
Theme.Colors.success           // Green (existing)
Theme.Colors.text              // Primary text color
Theme.Colors.secondaryText     // Secondary/muted text
Theme.Colors.cardBackground    // Card background
Theme.Colors.surface           // Main background
Theme.Colors.divider           // Separator lines
Theme.Colors.heroBlue          // Hero section gradient start
Theme.Colors.heroBlueLight     // Hero section gradient end
```

**Example Usage:**
```swift
Text("Goals")
    .font(Theme.Typography.headline)
    .foregroundColor(Theme.Colors.text)
```

---

### 6. Shadows (`Theme.Shadow`)

**Subtle depth** for cards and elevated elements:

```swift
Theme.Shadow.sm    // Subtle shadow for cards
Theme.Shadow.md    // Medium shadow for floating elements
Theme.Shadow.lg    // Large shadow for modals
```

**Example Usage:**
```swift
.shadow(
    color: Theme.Shadow.sm.color,
    radius: Theme.Shadow.sm.radius,
    x: Theme.Shadow.sm.x,
    y: Theme.Shadow.sm.y
)
```

---

## Reusable Components

### ThemeSectionHeader

Section headers with consistent styling:

```swift
ThemeSectionHeader(title: "My Stats")
    .padding(.horizontal, Theme.Spacing.md)
```

### ThemeEditButton

Standard edit button for cards:

```swift
ThemeEditButton(action: {
    // Edit action
})
```

### ThemeStatCard

Stat display card for grids:

```swift
ThemeStatCard(title: "Total Games", value: "12")
```

### ThemeInfoRow

Information display row for About sections:

```swift
ThemeInfoRow(title: "Location", value: "Menlo Park")
```

---

## View Extensions

### Typography Modifiers

Quick text styling:

```swift
Text("Title")
    .largeTitle()

Text("Section Header")
    .sectionHeader()

Text("Supporting text")
    .subtitle()

Text("Metadata")
    .caption()
```

### Component Styling

Apply consistent card/tile styling:

```swift
VStack {
    // Content
}
.cardStyle()              // Standard card with padding
.statTileStyle()          // Stat tile for grids
```

---

## Migration Guide

### Before (Old Code):
```swift
Text("MY STATS")
    .font(.title2)
    .bold()

VStack(spacing: 16) {
    // Content
}
.padding(.horizontal, 16)

RoundedRectangle(cornerRadius: 12)
    .fill(Color(.secondarySystemBackground))
```

### After (Theme System):
```swift
ThemeSectionHeader(title: "My Stats")

VStack(spacing: Theme.Spacing.md) {
    // Content
}
.padding(.horizontal, Theme.Spacing.md)

RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
    .fill(Theme.Colors.cardBackground)
```

---

## Best Practices

### ✅ DO

- Use semantic spacing constants (`Theme.Spacing.md` instead of `16`)
- Use semantic typography (`Theme.Typography.headline` instead of `.font(.headline)`)
- Use theme colors (`Theme.Colors.text` instead of `.primary`)
- Leverage reusable components (`ThemeEditButton`, `ThemeStatCard`)
- Maintain 8pt grid alignment (prefer `.md`, `.lg`, `.xl`)

### ❌ DON'T

- Hardcode spacing values (`16`, `24`, etc.)
- Use random font sizes (`.font(.system(size: 18))`)
- Create custom colors without adding them to `Theme.Colors`
- Mix theme constants with hardcoded values
- Create one-off components that duplicate theme components

---

## Strava-Inspired Design Principles

1. **Breathable Layouts**: Use generous spacing (`Theme.Spacing.md` minimum)
2. **Clear Hierarchy**: Section headers → card titles → values → metadata
3. **Subtle Separation**: Thin dividers (0.5pt stroke) instead of heavy borders
4. **Consistent Shadows**: Light shadows for depth without overwhelming
5. **Information Density**: Group related data in cards with clear sections

---

## Files Updated

### Core Theme
- `Theme.swift` - Complete design system definition

### Views Refactored
- `StatisticsView.swift` - Stats screen with themed components
- `LogSessionChoiceView.swift` - Session selection with consistent spacing
- `SettingsView.swift` - Settings with semantic typography
- `ProfileView.swift` - Profile screen with all themed subcomponents

---

## Summary of Changes

| Aspect | Before | After |
|--------|--------|-------|
| **Spacing** | Mixed (12, 14, 16, 20, 24) | 8pt grid (8, 12, 16, 24) |
| **Typography** | Hardcoded sizes/weights | Semantic styles |
| **Corner Radius** | Mixed (10, 12) | Standardized (8, 12) |
| **Colors** | Inline definitions | Centralized constants |
| **Components** | Duplicated code | Reusable theme components |
| **Shadows** | Inconsistent | Standardized presets |

---

## Next Steps

1. **Add Theme.swift** to your Xcode project
2. **Build and run** to verify all screens work correctly
3. **Refactor remaining views** (HomeView, BuildProfileView, etc.) using the same patterns
4. **Extend the theme** as needed (add new colors, spacing values, components)
5. **Document custom components** following this guide's format

---

## Questions?

The theme system is designed to be:
- **Discoverable**: Use Xcode autocomplete to explore `Theme.*`
- **Extensible**: Add new constants as your design evolves
- **Type-safe**: Compile-time checking prevents errors
- **Maintainable**: Change design tokens in one place

**Example:** To adjust all card corner radii, simply change `Theme.CornerRadius.md` from `12` to `16` and rebuild.

---

*Last updated: May 8, 2026*
