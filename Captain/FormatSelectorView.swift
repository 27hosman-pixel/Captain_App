import SwiftUI

/// Pill-style selector for choosing stat card format
/// Shows format name, icon, and platform hints
struct FormatSelectorView: View {
    @Binding var selectedFormat: StatCardFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Format")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            HStack(spacing: 12) {
                ForEach(StatCardFormat.allCases) { format in
                    FormatPill(
                        format: format,
                        isSelected: selectedFormat == format
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFormat = format
                        }
                    }
                }
            }
            
            // Platform hint
            Text(selectedFormat.platformHint)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Format Pill

private struct FormatPill: View {
    let format: StatCardFormat
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: format.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
            
            // Label
            Text(format.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.blue : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .shadow(
            color: isSelected ? Color.blue.opacity(0.3) : Color.clear,
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Style Selector (Optional Expansion)

/// Expandable style selector for choosing visual theme
struct StyleSelectorView: View {
    @Binding var selectedStyle: StatCardVisualStyle
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with toggle
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Style")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(selectedStyle.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Expanded style options
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(StatCardVisualStyle.allCases) { style in
                        StyleRow(
                            style: style,
                            isSelected: selectedStyle == style
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedStyle = style
                                isExpanded = false
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Style Row

private struct StyleRow: View {
    let style: StatCardVisualStyle
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: style.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isSelected ? .blue : .secondary)
                .frame(width: 32)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(style.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(style.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Preview

#Preview("Format Selector") {
    VStack(spacing: 20) {
        FormatSelectorView(selectedFormat: .constant(.square))
        
        StyleSelectorView(selectedStyle: .constant(.midnight))
    }
    .padding(.vertical, 40)
}
