import SwiftUI

struct ProfileView: View {
    @StateObject private var store = ProfileStore()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showingGoals: Bool = false
    @State private var showShareToast: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero header
                    HeroHeader(
                        name: displayName(),
                        position: store.profile.position,
                        location: store.profile.location
                    )
                    .padding(.top, 6)

                    // Content card stack
                    VStack(spacing: Theme.Spacing.md) {
                        // Overlapping avatar
                        AvatarView()
                            .offset(y: -48)
                            .padding(.bottom, -48)

                        // Stat cards
                        StatCardsRow(
                            followers: store.profile.followers,
                            activities: sessionStore.sessions.count,
                            following: store.profile.following
                        )

                        // Goals summary row
                        GoalsRow(
                            day: store.profile.goalsDay,
                            week: store.profile.goalsWeek,
                            season: store.profile.goalsSeason,
                            onEdit: { showingGoals = true }
                        )

                        // About grid
                        AboutCard(
                            dob: formattedDOB(),
                            age: derivedAge(),
                            school: store.profile.school,
                            grade: store.profile.grade,
                            location: store.profile.location,
                            position: store.profile.position,
                            club: store.profile.clubTeam,
                            onEdit: {
                                Task { @MainActor in
                                    router.navigate(.buildProfile)
                                }
                            }
                        )

                        // Recent activity
                        RecentActivitySection(
                            sparkValues: recentSessionCounts(),
                            images: recentImages(),
                            onAdd: { router.navigate(.logSession) }
                        )

                        // Quick actions
                        HStack(spacing: Theme.Spacing.sm) {
                            // Activities - use NavigationLink for tab navigation
                            NavigationLink(value: Destination.activities) {
                                ActionTileContent(title: "Activities", system: "list.bullet.rectangle")
                            }
                            .buttonStyle(.plain)
                            
                            // Goals - uses local state
                            Button(action: { showingGoals = true }) {
                                ActionTileContent(title: "Goals", system: "target")
                            }
                            .buttonStyle(.plain)
                            
                            // Share - uses action
                            Button(action: {
                                shareProfile()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showShareToast = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                    withAnimation(.easeInOut) { showShareToast = false }
                                }
                            }) {
                                ActionTileContent(title: "Share", system: "square.and.arrow.up")
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: Theme.Spacing.lg)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.md)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.load()
            }
        }
        // Goals editor sheet
        .sheet(isPresented: $showingGoals) {
            NavigationView {
                Form {
                    Section(header: Text("Daily Goal")) {
                        TextField("Day goals", text: Binding(get: { store.profile.goalsDay }, set: { store.profile.goalsDay = $0 }))
                    }
                    Section(header: Text("Weekly Goal")) {
                        TextField("Week goals", text: Binding(get: { store.profile.goalsWeek }, set: { store.profile.goalsWeek = $0 }))
                    }
                    Section(header: Text("Season Goal")) {
                        TextField("Season goals", text: Binding(get: { store.profile.goalsSeason }, set: { store.profile.goalsSeason = $0 }))
                    }
                    Section {
                        Button("Save") {
                            store.save()
                            showingGoals = false
                        }
                        Button("Cancel") {
                            showingGoals = false
                        }
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Goals")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showingGoals = false }
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            if showShareToast {
                ToastView(text: "Profile link ready to share")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        // Reserve space above the global bottom bar so content isn't blocked
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 20)
        }
    }

    // MARK: - Helpers (unchanged)
    private func displayName() -> String {
        let f = store.profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = store.profile.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !f.isEmpty || !l.isEmpty {
            return [f, l].filter { !$0.isEmpty }.joined(separator: " ")
        }
        return "Your Name"
    }

    private func formattedDOB() -> String {
        guard let dob = store.profile.dob else { return "—" }
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: dob)
    }

    private func derivedAge() -> String {
        if let age = store.profile.age, age > 0 {
            return String(age)
        }
        guard let dob = store.profile.dob else { return "—" }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year], from: dob, to: Date())
        if let years = comps.year { return String(years) }
        return "—"
    }

    private func recentSessionCounts(days: Int = 7) -> [Double] {
        let calendar = Calendar.current
        var counts = Array(repeating: 0.0, count: days)
        let now = Date()
        for s in sessionStore.sessions {
            let comps = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: s.date))
            if let daysAgo = comps.day {
                let index = days - 1 - daysAgo
                if index >= 0 && index < days {
                    counts[index] += 1.0
                }
            }
        }
        return counts
    }

    private func recentImages(max: Int = 10) -> [UIImage] {
        var imgs: [UIImage] = []
        for s in sessionStore.sessions {
            for name in s.imageFileNames {
                if let img = sessionStore.image(for: name) {
                    imgs.append(img)
                    if imgs.count >= max { return imgs }
                }
            }
        }
        return imgs
    }

    private func shareProfile() {
        let text = "Check out my Captain profile: \(displayName())"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

// MARK: - Subviews (unchanged visuals; layout-safe tweaks inside)

private struct HeroHeader: View {
    let name: String
    let position: String
    let location: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Theme.Colors.heroBlue, Theme.Colors.heroBlueLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)

                HStack(spacing: Theme.Spacing.xs) {
                    if !position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Chip(text: position, systemName: "figure.soccer")
                    }
                    if !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Chip(text: location, systemName: "mappin.and.ellipse")
                    }
                }
            }
            .padding(.leading, Theme.Spacing.lg)
            .padding(.bottom, 64)
        }
    }
}

private struct Chip: View {
    let text: String
    let systemName: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemName)
                .font(Theme.Typography.caption)
            Text(text)
                .font(Theme.Typography.caption)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(Capsule().fill(Color.white.opacity(0.15)))
        .overlay(Capsule().stroke(Color.white.opacity(0.35)))
        .foregroundColor(.white)
    }
}

private struct AvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.06)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .frame(width: 96, height: 96)
                .overlay(Circle().stroke(Color(.separator)))
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundColor(.blue)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Profile avatar")
    }
}

private struct StatCardsRow: View {
    let followers: Int
    let activities: Int
    let following: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            StatCard(title: "Followers", value: followers)
            
            NavigationLink(value: Destination.activities) {
                StatCard(title: "Activities", value: activities)
            }
            .buttonStyle(.plain)
            
            StatCard(title: "Following", value: following)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func StatCard(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            Text("\(value)")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.text)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.divider, lineWidth: 0.5)
        )
    }
}

private struct GoalsRow: View {
    let day: String
    let week: String
    let season: String
    var onEdit: () -> Void

    var body: some View {
        Card {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Goals")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    HStack(spacing: Theme.Spacing.sm) {
                        GoalPill(label: "Day", value: day)
                        GoalPill(label: "Week", value: week)
                        GoalPill(label: "Season", value: season)
                    }
                }
                Spacer()
                ThemeEditButton(action: onEdit)
            }
        }
    }

    private func GoalPill(label: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundColor(Theme.Colors.secondaryText)
            Text(value.isEmpty ? "—" : value)
                .font(Theme.Typography.caption)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(Capsule().fill(Color(.systemBackground)))
        .overlay(Capsule().stroke(Theme.Colors.divider, lineWidth: 0.5))
    }
}

private struct AboutCard: View {
    let dob: String
    let age: String
    let school: String
    let grade: String
    let location: String
    let position: String
    let club: String
    var onEdit: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("About")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    ThemeEditButton(action: onEdit)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Theme.Spacing.sm
                ) {
                    ThemeInfoRow(title: "Date of Birth", value: dob)
                    ThemeInfoRow(title: "Age", value: age)
                    ThemeInfoRow(title: "School", value: school)
                    ThemeInfoRow(title: "Grade", value: grade)
                    ThemeInfoRow(title: "Location", value: location)
                    ThemeInfoRow(title: "Position", value: position)
                    ThemeInfoRow(title: "Club Team", value: club)
                }
            }
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            Text(value.isEmpty ? "—" : value)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Color(.systemGray6))
        )
    }
}

private struct RecentActivitySection: View {
    let sparkValues: [Double]
    let images: [UIImage]
    var onAdd: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Recent Activity")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    NavigationLink("View All", value: Destination.activities)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.primary)
                }

                SparklineView(values: sparkValues)
                    .frame(height: 44)
                    .padding(.vertical, Theme.Spacing.xxs)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        AddTile(action: onAdd)
                        ForEach(Array(images.prefix(12).enumerated()), id: \.offset) { _, img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipped()
                                .cornerRadius(Theme.CornerRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                        .stroke(Theme.Colors.divider, lineWidth: 0.5)
                                )
                        }
                    }
                    .padding(.trailing, Theme.Spacing.xxs)
                }
            }
        }
    }
}

private struct AddTile: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: Theme.IconSize.xl))
                    .foregroundColor(Theme.Colors.primary)
                Text("Add")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.text)
            }
            .frame(width: 96, height: 96)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .stroke(Theme.Colors.divider, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SparklineView: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maxVal = max(values.max() ?? 1, 1)
            let stepX = values.count > 1 ? width / CGFloat(values.count - 1) : 0

            Path { path in
                for (i, v) in values.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = height - CGFloat(v / maxVal) * height
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
    }
}

private struct ActionTile: View {
    let title: String
    let system: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ActionTileContent(title: title, system: system)
        }
        .buttonStyle(.plain)
    }
}

private struct ActionTileContent: View {
    let title: String
    let system: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: system)
                .font(.system(size: Theme.IconSize.lg, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.15),
                                    Color.blue.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.divider, lineWidth: 0.5)
        )
    }
}

private struct ToastView: View {
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

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.divider, lineWidth: 0.5)
            )
            .shadow(
                color: Theme.Shadow.sm.color,
                radius: Theme.Shadow.sm.radius,
                x: Theme.Shadow.sm.x,
                y: Theme.Shadow.sm.y
            )
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AppRouter())
                .environmentObject(SessionStore())
        }
    }
}
