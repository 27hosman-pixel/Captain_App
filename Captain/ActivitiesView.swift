import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var feedFilters: FeedFilters
    @State private var showPostedToast: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            List {
                if sessionStore.sessions.isEmpty {
                    Text("No activities yet")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                } else {
                    ForEach(sessionStore.sessions.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { s in
                        NavigationLink(value: s) {
                            HStack(spacing: Theme.Spacing.sm) {
                                // Thumbnail image or icon
                                if let first = s.imageFileNames.first, 
                                   let img = sessionStore.image(for: first) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(Theme.CornerRadius.sm)
                                } else {
                                    // Show icon based on session type
                                    ZStack {
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                            .fill(iconColor(for: s.sessionType).opacity(0.15))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: iconName(for: s.sessionType))
                                            .font(.system(size: 28, weight: .medium))
                                            .foregroundColor(iconColor(for: s.sessionType))
                                    }
                                }

                                // Session info
                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text(s.title)
                                        .font(Theme.Typography.headline)
                                        .foregroundColor(Theme.Colors.text)
                                    
                                    Text(s.sessionType + " • " + DateFormatter.localizedString(
                                        from: s.date,
                                        dateStyle: .medium,
                                        timeStyle: .short
                                    ))
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                }
                                Spacer()
                            }
                            .padding(.vertical, Theme.Spacing.xs)
                        }
                    }
                }
            }
            .navigationTitle("My Activities")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SessionData.self) { session in
                SessionDetailView(session: session)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: Theme.Spacing.md)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowPostedToast"))) { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showPostedToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut) {
                        showPostedToast = false
                    }
                }
            }

            // Toast notification
            if showPostedToast {
                ActivityToast(text: "Posted!")
                    .padding(.top, Theme.Spacing.xs)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func iconName(for sessionType: String) -> String {
        switch sessionType.lowercased() {
        case "practice":
            return "figure.soccer"
        case "game":
            return "trophy.fill"
        case "training", "workout":
            return "dumbbell.fill"
        default:
            return "sportscourt.fill"
        }
    }
    
    private func iconColor(for sessionType: String) -> Color {
        switch sessionType.lowercased() {
        case "practice":
            return .blue
        case "game":
            return .orange
        case "training", "workout":
            return .green
        default:
            return .purple
        }
    }
}

// MARK: - Supporting Views

private struct ActivityToast: View {
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(text)
                .foregroundColor(.white)
                .font(Theme.Typography.subheadline)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
        .padding(.horizontal, Theme.Spacing.md)
        .shadow(
            color: Theme.Shadow.md.color,
            radius: Theme.Shadow.md.radius,
            x: Theme.Shadow.md.x,
            y: Theme.Shadow.md.y
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

struct ActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesView()
            .environmentObject(SessionStore())
    }
}

