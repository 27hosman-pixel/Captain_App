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
            Post(author: "coach_mike", timeAgo: "Yesterday", title: "Practice: Small-sided drills", imageNames: [], goals: 0, assists: 0, minutesPlayed: 60, likes: 4, comments: 1)
        ]
    }

    func clear() {
        posts = []
    }
}

struct HomeView: View {
    @StateObject private var store = FeedStore()
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            // Header + main content
            VStack(spacing: 0) {
                // Top header matching the provided mock
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Text("CAPTAIN")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                            .tracking(1.5)

                        Spacer()

                        HStack(spacing: 10) {
                            Button(action: {
                                Task { @MainActor in
                                    router.navigate(.messaging)
                                }
                            }) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                    .padding(8)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }

                            Button(action: {
                                Task { @MainActor in
                                    router.navigate(.notifications)
                                }
                            }) {
                                Image(systemName: "bell")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                    .padding(8)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // thin divider
                    Divider()
                        .background(Color(.separator))
                }

                // ...existing content... (feed and empty-state)
                VStack {
                    if store.posts.isEmpty {
                        EmptyFeedView(
                            onFindFriends: {
                                // Placeholder action — implement friend search later
                                print("Find Friends tapped")
                            },
                            onLogSession: {
                                // Navigate to the log session choice screen
                                Task { @MainActor in
                                    router.navigate(.logSession)
                                }
                            }
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(store.posts, id: \.id) { post in
                                    PostCardView(post: post)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    store.loadSample()
                }
            }

            // Bottom bar overlay (kept as-is)
            VStack {
                Spacer()
                BottomBarView()
                    .environmentObject(router)
                    .padding(.bottom, 0)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
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
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.blue))

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
            HStack(spacing: 12) {
                if post.imageNames.isEmpty {
                    // two-placeholder layout
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 160, height: 120)
                        .cornerRadius(10)
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))

                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 120)
                        .cornerRadius(10)
                        .overlay(Image(systemName: "map").foregroundColor(.secondary))
                } else {
                    ForEach(post.imageNames.prefix(2), id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
            }

            // Stats row
            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                    Text("\(post.goals) G")
                }
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("\(post.assists) A")
                }
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                    Text("\(post.minutesPlayed) min")
                }
                Spacer()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            // Action bar
            HStack(spacing: 12) {
                Button(action: {
                    // toggle like locally
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        Text("\(likeCount)")
                    }
                    .padding(8)
                    .foregroundColor(isLiked ? .blue : .primary)
                }

                Button(action: {
                    showCommentSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "message")
                        Text("\(commentCount)")
                    }
                    .padding(8)
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
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
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
                            // naive increment
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .previewDisplayName("With Sample Posts")

            HomeView()
                .onAppear {
                    // show empty version
                }
                .previewDisplayName("Empty Feed")
        }
        .environmentObject(AppRouter())
    }
}
