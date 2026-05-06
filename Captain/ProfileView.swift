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

                    // Content card stack
                    VStack(spacing: 16) {
                        // Overlapping avatar
                        AvatarView()
                            .offset(y: -48)
                            .padding(.bottom, -48)

                        // Stat cards
                        StatCardsRow(
                            followers: store.profile.followers,
                            activities: sessionStore.sessions.count,
                            following: store.profile.following,
                            onActivitiesTap: { router.navigate(.activities) }
                        )
                        .padding(.horizontal)

                        // Goals summary row
                        GoalsRow(
                            day: store.profile.goalsDay,
                            week: store.profile.goalsWeek,
                            season: store.profile.goalsSeason,
                            onEdit: { showingGoals = true }
                        )
                        .padding(.horizontal)

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
                        .padding(.horizontal)

                        // Recent activity
                        RecentActivitySection(
                            sparkValues: recentSessionCounts(),
                            images: recentImages(),
                            onViewAll: { router.navigate(.activities) },
                            onAdd: { router.navigate(.logSession) }
                        )
                        .padding(.horizontal)

                        // Quick actions
                        QuickActions(
                            onActivities: { router.navigate(.activities) },
                            onGoals: { showingGoals = true },
                            onShare: {
                                shareProfile()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showShareToast = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                    withAnimation(.easeInOut) { showShareToast = false }
                                }
                            }
                        )
                        .padding(.horizontal)

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("My Profile")
            .onAppear {
                store.load()
            }

            // Always-visible floating hamburger button in top-left (in-content)
            Button(action: {
                NotificationCenter.default.post(name: Notification.Name("ToggleSidebar"), object: nil)
            }) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 8)
            .padding(.leading, 8)
            .accessibilityLabel("Open menu")

            // Bottom bar overlay
            VStack {
                Spacer()
                BottomBarView()
                    .environmentObject(router)
                    .padding(.bottom, 0)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("ToggleSidebar"), object: nil)
                }) {
                    Image(systemName: "line.horizontal.3")
                        .imageScale(.large)
                }
            }
        }
        // Goals editor sheet (kept from your original)
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
    }

    // MARK: - Existing helpers preserved

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

// MARK: - Subviews

private struct HeroHeader: View {
    let name: String
    let position: String
    let location: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.blue.opacity(0.85), Color.blue.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 160)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.08), Color.clear], startPoint: .top, endPoint: .bottom))
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)

                HStack(spacing: 8) {
                    if !position.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Chip(text: position, systemName: "figure.soccer")
                    }
                    if !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Chip(text: location, systemName: "mappin.and.ellipse")
                    }
                }
            }
            .padding(.leading, 24)
            .padding(.bottom, 16)
        }
    }
}

private struct AvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 168, height: 168)
                .overlay(
                    Circle()
                        .stroke(LinearGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)

            Circle()
                .strokeBorder(Color.black.opacity(0.85), lineWidth: 5)
                .frame(width: 156, height: 156)
                .overlay(Image(systemName: "person.fill").font(.system(size: 64)).foregroundColor(.black))
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Profile picture")
    }
}

private struct StatCardsRow: View {
    let followers: Int
    let activities: Int
    let following: Int
    var onActivitiesTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            StatCard(icon: "person.2.fill", title: "Followers", value: followers)
            Button(action: onActivitiesTap) {
                StatCard(icon: "list.bullet.rectangle", title: "Activities", value: activities)
            }
            .buttonStyle(.plain)
            StatCard(icon: "person.crop.circle.badge.plus", title: "Following", value: following)
        }
    }
}

private struct StatCard: View {
    let icon: String
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(value)")
                    .font(.title2).bold()
                Spacer()
            }
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

private struct GoalsRow: View {
    let day: String
    let week: String
    let season: String
    var onEdit: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Goals")
                    .font(.headline)
                Spacer()
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline.bold())
                }
            }

            HStack(spacing: 8) {
                GoalPill(title: "Day", value: day)
                GoalPill(title: "Week", value: week)
                GoalPill(title: "Season", value: season)
                Spacer()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
    }
}

private struct GoalPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName(for: title))
                .font(.caption)
            Text(title)
                .font(.caption).bold()
            Text(display(value))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Capsule().fill(Color(.systemBackground)))
        .overlay(Capsule().stroke(Color(.separator)))
    }

    private func display(_ v: String) -> String {
        let t = v.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "—" : t
    }

    private func iconName(for title: String) -> String {
        switch title.lowercased() {
        case "day": return "sun.max.fill"
        case "week": return "calendar"
        default: return "flag.fill"
        }
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
        VStack(spacing: 12) {
            HStack {
                Text("About")
                    .font(.headline)
                Spacer()
                Button(action: onEdit) {
                    Label("Edit Profile", systemImage: "square.and.pencil")
                        .font(.subheadline.bold())
                }
            }

            Divider()

            VStack(spacing: 10) {
                InfoRow(icon: "calendar", label: "DOB", value: dob)
                InfoRow(icon: "clock", label: "Age", value: age)
                InfoRow(icon: "building.2", label: "School", value: school)
                InfoRow(icon: "graduationcap", label: "Grade", value: grade)
                InfoRow(icon: "mappin.and.ellipse", label: "Location", value: location)
                InfoRow(icon: "figure.soccer", label: "Position", value: position)
                InfoRow(icon: "person.3", label: "Club", value: club)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.blue)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(display(value))
                .foregroundColor(value.trimmed.isEmpty || value == "—" ? .secondary : .primary)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(display(value))")
    }

    private func display(_ v: String) -> String {
        let t = v.trimmed
        return t.isEmpty ? "—" : t
    }
}

private struct RecentActivitySection: View {
    let sparkValues: [Double]
    let images: [UIImage]
    var onViewAll: () -> Void
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                Button(action: onViewAll) {
                    Text("View All")
                        .font(.subheadline.bold())
                }
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Sessions last 7 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                SparklineView(values: sparkValues)
                    .frame(height: 56)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))

            // Media carousel with leading + tile
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AddTile(action: onAdd)
                    ForEach(Array(images.enumerated()), id: \.0) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipped()
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct AddTile: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.title2)
                Text("Add")
                    .font(.caption)
            }
            .frame(width: 96, height: 96)
            .foregroundColor(.blue)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add new session")
    }
}

private struct QuickActions: View {
    var onActivities: () -> Void
    var onGoals: () -> Void
    var onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ActionTile(systemName: "list.bullet.rectangle", title: "Activities", action: onActivities)
            ActionTile(systemName: "flag", title: "Goals", action: onGoals)
            ActionTile(systemName: "square.and.arrow.up", title: "Share", action: onShare)
        }
    }
}

private struct ActionTile: View {
    let systemName: String
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(.blue)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                    )
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct ToastView: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.8)))
        .padding(.horizontal)
    }
}

// A tiny sparkline view (unchanged)
struct SparklineView: View {
    var values: [Double]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let maxV = (values.max() ?? 1)
            let points: [CGPoint] = values.enumerated().map { i, v in
                let x = w * CGFloat(i) / CGFloat(max(1, values.count - 1))
                let y = h - (h * CGFloat(v) / CGFloat(maxV == 0 ? 1 : maxV))
                return CGPoint(x: x, y: y)
            }
            Path { p in
                guard points.count > 0 else { return }
                p.move(to: points[0])
                for pt in points.dropFirst() { p.addLine(to: pt) }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }
}

// Simple outline button style (kept for backward compatibility if referenced elsewhere)
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color(red: 0.78, green: 0.93, blue: 0.99))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.7), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AppRouter())
            .environmentObject(SessionStore())
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Missing Chip view

private struct Chip: View {
    let text: String
    let systemName: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.caption)
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.caption).bold()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .foregroundColor(.white)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.18))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .accessibilityLabel(text)
    }
}
