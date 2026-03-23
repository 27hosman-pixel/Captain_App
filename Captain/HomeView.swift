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
}

final class FeedStore: ObservableObject {
    @Published var posts: [Post] = []

    // Sample loader for previews and quick testing
    func loadSample() {
        posts = [
            Post(author: "riya_tad", timeAgo: "3:47 pm", title: "Game vs. Hinsdale Central (3-1 W)", imageNames: [], goals: 3, assists: 1, minutesPlayed: 90),
            Post(author: "coach_mike", timeAgo: "Yesterday", title: "Practice: Small-sided drills", imageNames: [], goals: 0, assists: 0, minutesPlayed: 60)
        ]
    }

    func clear() {
        posts = []
    }
}

struct HomeView: View {
    @StateObject private var store = FeedStore()

    var body: some View {
        Group {
            if store.posts.isEmpty {
                EmptyFeedView(onFindFriends: findFriends, onLogSession: logFirstSession)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 20, pinnedViews: []) {
                        ForEach(store.posts) { post in
                            PostCardView(post: post)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationTitle("Home")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .onAppear {
            // For now load sample posts in preview or quick demo; in production, replace with network/db load
            if store.posts.isEmpty {
                store.loadSample()
            }
        }
    }

    // MARK: - Actions
    private func findFriends() {
        // placeholder - wire to recruiter/search flow
        print("Find friends tapped")
    }

    private func logFirstSession() {
        // placeholder - open Log New Session flow
        print("Log first session tapped")
    }
}

struct PostCardView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
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
                }
            }

            // Images (placeholder boxes if no assets)
            if post.imageNames.isEmpty {
                HStack(spacing: 12) {
                    ForEach(0..<min(2, 3), id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 120)
                            .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                            .cornerRadius(8)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                }
            } else {
                // If images provided, show up to 3 thumbnails
                HStack(spacing: 12) {
                    ForEach(post.imageNames.prefix(3), id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                }
            }

            // Big stats row
            HStack(alignment: .firstTextBaseline) {
                Text("Stats: \(post.goals) G, \(post.assists) A, \(post.minutesPlayed) MP")
                    .font(.system(size: 26, weight: .bold))
                Spacer()
            }
            .padding(.top, 6)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
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
    }
}
