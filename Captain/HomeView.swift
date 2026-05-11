import SwiftUI
import Combine

// NOTE: Post struct and FeedStore removed - V1 focuses on personal activity tracking only

struct HomeView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var feedFilters: FeedFilters
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var profileStore: ProfileStore
    
    @State private var showFilterSheet = false
    @State private var sessionToDelete: SessionData?
    @State private var showingDeleteConfirmation = false
    @State private var selectedSession: SessionData?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    // Section header with filter button
                    HStack {
                        Text("Latest")
                            .font(.headline)
                        Spacer()
                        Button {
                            showFilterSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Label("Filters", systemImage: "slider.horizontal.3")
                                    .font(.subheadline.bold())
                                
                                // Badge indicator for active filters
                                if feedFilters.hasActiveFilters {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 20, height: 20)
                                        
                                        Text("\(feedFilters.activeFilterCount)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 8)
                    
                    // Show empty state if no sessions, otherwise show session list
                    if filteredSessions.isEmpty {
                        EmptyActivityCard(onLogSession: {
                            NotificationCenter.default.post(
                                name: Notification.Name("SwitchToLogTab"),
                                object: nil
                            )
                        })
                    } else {
                        VStack(spacing: 12) {
                            ForEach(filteredSessions) { session in
                                SessionCardView(
                                    session: session,
                                    sessionStore: sessionStore,
                                    profileStore: profileStore,
                                    onTap: {
                                        selectedSession = session
                                    },
                                    onDelete: {
                                        sessionToDelete = session
                                        showingDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(filters: feedFilters)
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailEditView(session: session, sessionStore: sessionStore)
        }
        .confirmationDialog(
            "Delete Session",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible,
            presenting: sessionToDelete
        ) { session in
            Button("Delete", role: .destructive) {
                deleteSession(session)
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        } message: { session in
            Text("Are you sure you want to delete '\(session.title)'? This action cannot be undone.")
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 20)
        }
    }
    
    // MARK: - Delete Session
    
    private func deleteSession(_ session: SessionData) {
        sessionStore.delete(session: session)
        sessionToDelete = nil
    }
    
    // MARK: - Filtered Sessions
    
    private var filteredSessions: [SessionData] {
        sessionStore.sessions.filter { session in
            !session.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            feedFilters.matches(session: session)
        }
    }
}

// MARK: - Session Card

private struct SessionCardView: View {
    let session: SessionData
    let sessionStore: SessionStore
    let profileStore: ProfileStore
    var onTap: () -> Void
    var onDelete: () -> Void
    
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with profile photo and delete button
            HStack(alignment: .center, spacing: 12) {
                // Profile Photo Avatar
                if let profileImage = profileStore.getProfilePhoto() {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                        )
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Delete button (trash icon)
                        Button(action: {
                            onDelete()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(8)
                                .background(Circle().fill(Color.red.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Metadata
                    HStack(spacing: 4) {
                        Text(formatDate(session.date))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        if !session.location.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(session.location)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.bottom, 12)
            
            // Tappable content area
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 0) {
                    // Title
                    Text(session.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .padding(.bottom, 8)
                    
                    // Notes (if available)
                    if let notes = session.details["Notes"], !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.bottom, 16)
                    }
                    
                    // Stats Grid
                    if !topStats.isEmpty {
                        HStack(spacing: 0) {
                            ForEach(Array(topStats.enumerated()), id: \.offset) { _, stat in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stat.label)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    Text(stat.value)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Media Gallery
                    if !session.imageFileNames.isEmpty {
                        MediaGalleryView(imageFileNames: session.imageFileNames, sessionStore: sessionStore)
                            .padding(.bottom, 12)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Action Bar with Share button
            Divider()
                .padding(.vertical, 8)
            
            Button(action: { showShareSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                    Text("Share")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.5), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
        .sheet(isPresented: $showShareSheet) {
            ShareCardView(previewStore: sessionDataToPreviewStore(session))
        }
    }
    
    private func sessionDataToPreviewStore(_ session: SessionData) -> PreviewStore {
        let previewStore = PreviewStore()
        previewStore.title = session.title
        previewStore.date = session.date
        previewStore.location = session.location
        previewStore.sessionType = session.sessionType
        previewStore.details = session.details
        previewStore.images = session.imageFileNames.compactMap { fileName in
            sessionStore.image(for: fileName)
        }
        return previewStore
    }
    
    private var displayName: String {
        let firstName = profileStore.profile.firstName
        let lastName = profileStore.profile.lastName
        if !firstName.isEmpty && !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        } else if !firstName.isEmpty {
            return firstName
        } else if !lastName.isEmpty {
            return lastName
        }
        return "You"
    }
    
    private var topStats: [(label: String, value: String)] {
        var stats: [(label: String, value: String)] = []
        let statMappings: [(keys: [String], label: String)] = [
            (["Goals"], "Goals"),
            (["Assists"], "Assists"),
            (["Minutes", "minutesPlayed"], "Time"),
            (["TotalMiles"], "Distance"),
            (["Avg HR"], "Avg HR"),
            (["Type"], "Type"),
            (["Drills"], "Drills")
        ]
        
        for mapping in statMappings {
            for key in mapping.keys {
                if let value = session.details[key], !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    stats.append((label: mapping.label, value: value))
                    break
                }
            }
            if stats.count >= 3 { break }
        }
        return stats
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Media Gallery

private struct MediaGalleryView: View {
    let imageFileNames: [String]
    let sessionStore: SessionStore
    
    var body: some View {
        let imageCount = imageFileNames.count
        
        Group {
            if imageCount == 1 {
                singleImage(imageFileNames[0])
            } else if imageCount == 2 {
                HStack(spacing: 4) {
                    ForEach(imageFileNames.prefix(2), id: \.self) { fileName in
                        gridImage(fileName).frame(height: 120)
                    }
                }
            } else if imageCount >= 3 {
                HStack(spacing: 4) {
                    singleImage(imageFileNames[0]).frame(maxWidth: .infinity)
                    VStack(spacing: 4) {
                        ForEach(imageFileNames.prefix(3).dropFirst(), id: \.self) { fileName in
                            gridImage(fileName).frame(height: 120)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func singleImage(_ fileName: String) -> some View {
        Group {
            if let image = sessionStore.image(for: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .clipped()
            } else {
                Rectangle().fill(Color(.systemGray6)).frame(height: 240)
            }
        }
    }
    
    private func gridImage(_ fileName: String) -> some View {
        Group {
            if let image = sessionStore.image(for: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Rectangle().fill(Color(.systemGray6))
            }
        }
    }
}

// MARK: - Empty State

private struct EmptyActivityCard: View {
    var onLogSession: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Start Your Journey")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Log your first session to start tracking your progress and reaching your goals")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Button(action: onLogSession) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Log Your First Session")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Session Detail Edit View

private struct SessionDetailEditView: View {
    let session: SessionData
    let sessionStore: SessionStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text(session.title)
                        .font(.title.bold())
                    
                    // Metadata
                    HStack {
                        Text(session.sessionType)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        Text(formatDate(session.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Location
                    if !session.location.isEmpty {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.secondary)
                            Text(session.location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Images
                    if !session.imageFileNames.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photos")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(session.imageFileNames, id: \.self) { fileName in
                                        if let image = sessionStore.image(for: fileName) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 200, height: 140)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Stats
                    if !session.details.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline)
                            
                            ForEach(session.details.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                if !value.isEmpty {
                                    HStack {
                                        Text(key)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(value)
                                            .font(.body.bold())
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}
