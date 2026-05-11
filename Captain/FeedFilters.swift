//
//  FeedFilters.swift
//  Captain
//
//  Manages filtering state for the activity feed
//

import SwiftUI
import Combine

// MARK: - Filter Types

enum ActivityTypeFilter: String, CaseIterable, Codable {
    case all = "All"
    case game = "Game"
    case practice = "Practice"
    case workout = "Workout"
    
    var displayName: String { rawValue }
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .game: return "sportscourt"
        case .practice: return "figure.run"
        case .workout: return "dumbbell"
        }
    }
}

enum DateRangeFilter: String, CaseIterable, Codable {
    case allTime = "All Time"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case last30Days = "Last 30 Days"
    case thisYear = "This Year"
    
    var displayName: String { rawValue }
    
    func matches(date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .allTime:
            return true
        case .thisWeek:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .last30Days:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return date >= thirtyDaysAgo
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

// MARK: - Feed Filters Store

final class FeedFilters: ObservableObject {
    
    // Published properties for reactive UI
    @Published var activityTypes: Set<ActivityTypeFilter> = [.all]
    @Published var dateRange: DateRangeFilter = .allTime
    
    // Persistence keys
    private let activityTypesKey = "feed_filter_activity_types"
    private let dateRangeKey = "feed_filter_date_range"
    
    init() {
        loadFilters()
    }
    
    // MARK: - Computed Properties
    
    /// Returns the count of active filters (excluding defaults)
    var activeFilterCount: Int {
        var count = 0
        
        // Activity type filter is active if not "All"
        if !activityTypes.contains(.all) {
            count += 1
        }
        
        // Date range is active if not "All Time"
        if dateRange != .allTime {
            count += 1
        }
        
        return count
    }
    
    var hasActiveFilters: Bool {
        activeFilterCount > 0
    }
    
    // MARK: - Filter Actions
    
    func toggleActivityType(_ type: ActivityTypeFilter) {
        if type == .all {
            // If "All" is selected, clear other filters
            activityTypes = [.all]
        } else {
            // Remove "All" if present
            activityTypes.remove(.all)
            
            // Toggle the selected type
            if activityTypes.contains(type) {
                activityTypes.remove(type)
            } else {
                activityTypes.insert(type)
            }
            
            // If no types selected, default back to "All"
            if activityTypes.isEmpty {
                activityTypes = [.all]
            }
        }
        
        saveFilters()
    }
    
    func setDateRange(_ range: DateRangeFilter) {
        dateRange = range
        saveFilters()
    }
    
    func clearAll() {
        activityTypes = [.all]
        dateRange = .allTime
        saveFilters()
    }
    
    // MARK: - Filtering Logic
    
    func matches(session: SessionData) -> Bool {
        // Check activity type
        if !activityTypes.contains(.all) {
            let sessionTypeMatches = activityTypes.contains { filter in
                session.sessionType.lowercased().contains(filter.rawValue.lowercased())
            }
            if !sessionTypeMatches {
                return false
            }
        }
        
        // Check date range
        if !dateRange.matches(date: session.date) {
            return false
        }
        
        // All filters passed
        return true
    }
    
    // MARK: - Persistence
    
    private func saveFilters() {
        // Save activity types
        let activityTypeStrings = activityTypes.map { $0.rawValue }
        UserDefaults.standard.set(activityTypeStrings, forKey: activityTypesKey)
        
        // Save date range
        UserDefaults.standard.set(dateRange.rawValue, forKey: dateRangeKey)
    }
    
    private func loadFilters() {
        // Load activity types
        if let savedTypes = UserDefaults.standard.stringArray(forKey: activityTypesKey) {
            activityTypes = Set(savedTypes.compactMap { ActivityTypeFilter(rawValue: $0) })
            if activityTypes.isEmpty {
                activityTypes = [.all]
            }
        }
        
        // Load date range
        if let savedRange = UserDefaults.standard.string(forKey: dateRangeKey),
           let range = DateRangeFilter(rawValue: savedRange) {
            dateRange = range
        }
    }
}
