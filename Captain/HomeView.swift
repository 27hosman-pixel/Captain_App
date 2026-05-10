import SwiftUI
import Combine

struct Post: Identifiable, Hashable {
    let id = UUID()
    let author: String
    let timeAgo: String
    let title: String
    let imageNames: [String] // local asset names; if empty we'll show placeholder boxes
    let goals: Int
    let assists: Int
    let minutesPlayed: Int
    var likes: Int = 0
    var comments: Int = 0
}

final class FeedStore: ObservableObject {
    @Published var posts: [Post] = []

    func loadSample() {
        posts = [
            Post(author: "riya_tad", timeAgo: "3:47 pm", title: "Game vs. Hinsdale Central (3-1 W)", imageNames: [], goals: 3, assists: 1, minutesPlayed: 90, likes: 12, comments: 3),
            Post(author: "coach_mike", timeAgo: "Yesterday", title: "Practice: Small-sided drills", imageNames: [], goals: 0, assists: 2, minutesPlayed: 60, likes: 4, comments: 1)
        ]
    }

    func clear() {
        posts = []
    }
}

struct HomeView: View {
    @StateObject private var store = FeedStore()
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var feedFilters: FeedFilters
    @EnvironmentObject var router: AppRouter

    @State private var goToMessages = false
    @State private var goToNotifications = false
    @State private var showFilterSheet = false

    var body: some View {
        // Remove the overlayed bottom bar here; the global bar in ContentView will handle it.
        ZStack {
            NavigationLink(isActive: $goToMessages) {
                MessagingView()
            } label: { EmptyView() }
            .hidden()

            NavigationLink(isActive: $goToNotifications) {
                NotificationsView()
            } label: { EmptyView() }
            .hidden()

            ScrollView {
                VStack(spacing: 0) {
                    HomeHeroHeader(
                        onMessages: { goToMessages = true },
                        onNotifications: { goToNotifications = true }
                    )

                    // apply consistent content inset to avoid leading clipping
                    VStack(spacing: 16) {
                        // Check BOTH sample posts and real sessions
                        if filteredSessions.isEmpty && store.posts.isEmpty {
                            EmptyFeedCard(
                                onFindFriends: { print("Find Friends tapped") },
                                onLogSession: {
                                    Task { @MainActor in
                                        router.navigate(.logSession)
                                    }
                                }
                            )
                        } else {
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

                            VStack(spacing: 12) {
                                // FIRST: Show real user sessions from SessionStore (filter out empty/invalid ones)
                                ForEach(filteredSessions) { session in
                                    Card {
                                        SessionCardView(session: session, sessionStore: sessionStore)
                                    }
                                }
                                
                                // THEN: Show sample posts from FeedStore
                                ForEach(store.posts, id: \.id) { post in
                                    Card {
                                        PostCardView(post: post)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16) // inset all feed content
                    .padding(.top, 12)
                    // Add bottom padding to ensure last content is not obscured by the global bottom bar.
                    .padding(.bottom, 120)
                }
            }
            .onAppear {
                store.loadSample()
            }
        }
        .navigationTitle("Home")
        .toolbar { }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(filters: feedFilters)
        }
    }
    
    // MARK: - Filtered Sessions
    
    /// Apply all active filters to the session list
    private var filteredSessions: [SessionData] {
        sessionStore.sessions
            .filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .filter { feedFilters.matches(session: $0) }
    }
}

// MARK: - Restored subviews needed by HomeView

private struct HomeHeroHeader: View {
    var onMessages: () -> Void
    var onNotifications: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.blue.opacity(0.85), Color.blue.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 140)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.08), Color.clear], startPoint: .top, endPoint: .bottom))
            )

            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 10) {
                        HeaderIconButton(systemName: "bubble.left.and.bubble.right", action: onMessages)
                        HeaderIconButton(systemName: "bell", action: onNotifications)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Captain")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)

                    Text("See updates from you and your teammates")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                .padding(.leading, 0)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
        }
    }
}

private struct HeaderIconButton: View {
    let systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(systemName == "bell" ? "Notifications" : "Messages")
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator).opacity(0.5), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Session Card for Real User Sessions (Strava-inspired design)

struct SessionCardView: View {
    let session: SessionData
    let sessionStore: SessionStore
    @State private var isLiked: Bool = false
    @State private var likeCount: Int = 0
    @State private var commentCount: Int = 0
    @State private var showCommentSheet: Bool = false
    @State private var newComment: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header Section
            HStack(alignment: .center, spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    // Name and timestamp
                    HStack(spacing: 8) {
                        Text("You")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if !session.isPublic {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(timeAgo(from: session.date))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    // Metadata line (date • location)
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
            
            // MARK: - Title
            Text(session.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .padding(.bottom, 8)
            
            // MARK: - Description/Notes (if available)
            if let notes = session.details["Notes"], !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.bottom, 16)
            }
            
            // MARK: - Stats Grid (Strava-style)
            statsGrid
                .padding(.bottom, 16)
            
            // MARK: - Media Gallery
            if !session.imageFileNames.isEmpty {
                mediaGallery
                    .padding(.bottom, 12)
            }
            
            // MARK: - Engagement Bar
            Divider()
                .padding(.vertical, 8)
            
            HStack(spacing: 0) {
                // Kudos (Likes)
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                    Text("\(likeCount) gave kudos")
                        .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Comments
                Text("\(commentCount) comment\(commentCount == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 12)
            
            // MARK: - Action Buttons
            HStack(spacing: 40) {
                Button(action: {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 24))
                            .foregroundColor(isLiked ? .orange : .secondary)
                        Text("Kudos")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                
                Button(action: { showCommentSheet = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("Comment")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showCommentSheet) {
            NavigationView {
                VStack {
                    List {
                        TextField("Add a comment...", text: $newComment)
                    }
                    HStack {
                        Button("Cancel") { showCommentSheet = false }
                        Spacer()
                        Button("Post") {
                            commentCount += 1
                            newComment = ""
                            showCommentSheet = false
                        }
                    }
                    .padding()
                }
                .navigationTitle("Comments")
            }
        }
    }
    
    // MARK: - Stats Grid (inspired by Strava's Distance/Pace/Time layout)
    
    private var statsGrid: some View {
        HStack(spacing: 0) {
            ForEach(Array(topStats.enumerated()), id: \.offset) { index, stat in
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
    }
    
    // MARK: - Media Gallery
    
    private var mediaGallery: some View {
        let imageCount = session.imageFileNames.count
        
        return Group {
            if imageCount == 1 {
                // Single large image
                singleImage(session.imageFileNames[0])
            } else if imageCount == 2 {
                // Two images side by side
                HStack(spacing: 4) {
                    ForEach(session.imageFileNames.prefix(2), id: \.self) { fileName in
                        gridImage(fileName)
                    }
                }
            } else if imageCount >= 3 {
                // Grid layout (first image large, others smaller)
                HStack(spacing: 4) {
                    singleImage(session.imageFileNames[0])
                        .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        ForEach(session.imageFileNames.prefix(3).dropFirst(), id: \.self) { fileName in
                            gridImage(fileName)
                                .frame(height: 120)
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
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 240)
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
                Rectangle()
                    .fill(Color(.systemGray6))
            }
        }
    }
    
    // MARK: - Helpers
    
    private var topStats: [(label: String, value: String)] {
        var stats: [(label: String, value: String)] = []
        
        // Map session details to Strava-style labels
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
            
            if stats.count >= 3 { break } // Max 3 stats like Strava
        }
        
        return stats
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 1 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days)d ago" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Sample Post Card

struct PostCardView: View {
    let post: Post
    @State private var isLiked: Bool = false
    @State private var likeCount: Int = 0
    @State private var commentCount: Int = 0
    @State private var showCommentSheet: Bool = false
    @State private var newComment: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(post.author)
                            .font(.subheadline).bold()
                        Spacer()
                        Text(post.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(post.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            }

            // Media area
            MediaRow(imageNames: post.imageNames)

            // Stats row
            HStack(spacing: 16) {
                StatChip(icon: "target", text: "\(post.goals) G")
                StatChip(icon: "bolt.fill", text: "\(post.assists) A")
                StatChip(icon: "clock", text: "\(post.minutesPlayed) min")
                Spacer()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Divider()

            // Action bar
            HStack(spacing: 12) {
                Button(action: {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        Text("\(likeCount)")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Color(.systemGray6)))
                }
                .foregroundColor(isLiked ? .blue : .primary)

                Button(action: { showCommentSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                        Text("\(commentCount)")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Color(.systemGray6)))
                    .foregroundColor(.primary)
                }

                Spacer()

                Button(action: {
                    print("Share tapped for \(post.title)")
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .padding(8)
                }
            }
            .font(.subheadline)
        }
        .onAppear {
            likeCount = post.likes
            commentCount = post.comments
        }
        .sheet(isPresented: $showCommentSheet) {
            NavigationView {
                VStack {
                    List {
                        TextField("Add a comment...", text: $newComment)
                    }
                    HStack {
                        Button("Cancel") { showCommentSheet = false }
                        Spacer()
                        Button("Post") {
                            commentCount += 1
                            newComment = ""
                            showCommentSheet = false
                        }
                    }
                    .padding()
                }
                .navigationTitle("Comments")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct MediaRow: View {
    let imageNames: [String]
    var body: some View {
        HStack(spacing: 12) {
            if imageNames.isEmpty {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(width: 160, height: 120)
                    .cornerRadius(10)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "photo")
                            Text("No Media")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    )

                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 120)
                    .cornerRadius(10)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "map")
                            Text("Location")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    )
            } else {
                ForEach(imageNames.prefix(2), id: \.self) { name in
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
                }
            }
        }
    }
}

private struct StatChip: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Capsule().fill(Color(.systemBackground)))
        .overlay(Capsule().stroke(Color(.separator)))
    }
}

// A themed empty card to match other screens
private struct EmptyFeedCard: View {
    var onFindFriends: () -> Void
    var onLogSession: () -> Void

    var body: some View {
        Card {
            VStack(spacing: 16) {
                HStack {
                    Text("Your Feed")
                        .font(.headline)
                    Spacer()
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Follow teammates and log your sessions to see updates here.")
                            .foregroundColor(.secondary)

                        HStack(spacing: 10) {
                            Button(action: onFindFriends) {
                                Label("Find Friends", systemImage: "person.crop.circle.badge.plus")
                                    .font(.subheadline.bold())
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                            }
                            .buttonStyle(.plain)

                            Button(action: onLogSession) {
                                Label("Log Session", systemImage: "plus")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
