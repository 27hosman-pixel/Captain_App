//
//  FilterSheetView.swift
//  Captain
//
//  Bottom sheet for filtering the activity feed
//

import SwiftUI

struct FilterSheetView: View {
    @ObservedObject var filters: FeedFilters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Activity Type Section
                    FilterSection(title: "Activity Type") {
                        VStack(spacing: 12) {
                            ForEach(ActivityTypeFilter.allCases, id: \.self) { type in
                                FilterOptionRow(
                                    icon: type.icon,
                                    title: type.displayName,
                                    isSelected: filters.activityTypes.contains(type)
                                ) {
                                    filters.toggleActivityType(type)
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, Theme.Spacing.lg)
                    
                    // Date Range Section
                    FilterSection(title: "Date Range") {
                        VStack(spacing: 12) {
                            ForEach(DateRangeFilter.allCases, id: \.self) { range in
                                FilterOptionRow(
                                    icon: "calendar",
                                    title: range.displayName,
                                    isSelected: filters.dateRange == range
                                ) {
                                    filters.setDateRange(range)
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, Theme.Spacing.lg)
                    
                    // Source Section
                    FilterSection(title: "Show") {
                        VStack(spacing: 12) {
                            ForEach(SourceFilter.allCases, id: \.self) { source in
                                FilterOptionRow(
                                    icon: source.icon,
                                    title: source.displayName,
                                    isSelected: filters.source == source
                                ) {
                                    filters.setSource(source)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if filters.hasActiveFilters {
                        Button(action: { filters.clearAll() }) {
                            Text("Clear All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Filter Section

private struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            content
        }
    }
}

// MARK: - Filter Option Row

private struct FilterOptionRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 28)
                
                // Title
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.3))
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct FilterSheetView_Previews: PreviewProvider {
    static var previews: some View {
        FilterSheetView(filters: FeedFilters())
    }
}
