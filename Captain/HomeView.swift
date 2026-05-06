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

    // Sample loader for previews and quick testing
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
    @EnvironmentObject var router: AppRouter

    // Local navigation to concrete views
    @State private var goToMessages = false
    @State private var goToNotifications = false

    var body: some View {
        ZStack {
            // Hidden links to push concrete views
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
                    // Hero header with right-side actions
                    HomeHeroHeader(
                        onMessages: { goToMessages = true },
                        onNotifications: { goToNotifications = true }
                    )

                    // Content stack
                    VStack(spacing: 16) {
                        if store.posts.isEmpty {
                            EmptyFeedCard(
                                onFindFriends: {
                                    // Placeholder action — implement friend search later
                                    print("Find Friends tapped")
                                },
                                onLogSession: {
                                    Task { @MainActor in
                                        router.navigate(.logSession)
                                    }
                                }
                            )
                            .padding(.horizontal)
                        } else {
                            // Optional "Latest" section header
                            HStack {
                                Text("Latest")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    // future filter/sort
                                } label: {
                                    Label("Filters", systemImage: "slider.horizontal.3")
                                        .font(.subheadline.bold())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)

                            VStack(spacing: 12) {
                                ForEach(store.posts, id: \.id) { post in
                                    Card {
                                        PostCardView(post: post)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 12)
                }
            }
            .onAppear {
                store.loadSample()
            }

            // Bottom bar overlay (consistent across app)
            VStack {
                Spacer()
                BottomBarView()
                    .environmentObject(router)
                    .padding(.bottom, 0)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        // Remove toolbar leading menu; not needed anymore
        .navigationTitle("Home")
        .toolbar { }
    }
}

// MARK: - Subviews styled to match Profile/Log

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

            // Title + subtitle + top-right actions
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
                .padding(.leading, 0)   // flush to left edge
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16) // keep overall content inset consistent with system margins
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
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }
}

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
                    // share placeholder
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

struct EmptyFeedView: View {
    var onFindFriends: () -> Void
    var onLogSession: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "person.3.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .foregroundColor(.blue)
                .padding(8)
                .background(Circle().fill(Color.blue.opacity(0.12)))

            Text("Welcome to Captain")
                .font(.title2).bold()

            Text("Your feed will show sessions from you and your friends. Find teammates or log your first session to get started.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button(action: onFindFriends) {
                    Text("Find Friends")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 1))
                }

                Button(action: onLogSession) {
                    Text("Log First Session")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .previewDisplayName("With Sample Posts")

            HomeView()
                .onAppear {
                    // show empty version by clearing store in a real preview scenario
                }
                .previewDisplayName("Empty Feed")
        }
        .environmentObject(AppRouter())
    }
}
