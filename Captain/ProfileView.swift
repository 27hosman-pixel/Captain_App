import SwiftUI

struct ProfileView: View {
    @StateObject private var store = ProfileStore()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showingGoals: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                // large avatar
                Circle()
                    .strokeBorder(Color.black, lineWidth: 6)
                    .frame(width: 160, height: 160)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 64)).foregroundColor(.black))

                // name — derive from profile if possible
                Text(displayName())
                    .font(.title)
                    .bold()

                // Counters row: followers / activities / following
                HStack(spacing: 20) {
                    VStack {
                        Text("Followers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(store.profile.followers)")
                            .font(.headline)
                    }
                    VStack {
                        Text("Activities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(sessionStore.sessions.count)")
                            .font(.headline)
                    }
                    VStack {
                        Text("Following")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(store.profile.following)")
                            .font(.headline)
                    }
                }

                Spacer().frame(height: 8)

                // Profile details card (replaces About Me button)
                VStack(spacing: 12) {
                    HStack {
                        Text("About")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            Task { @MainActor in
                                router.navigate(.buildProfile)
                            }
                        }) {
                            Text("Edit")
                                .font(.subheadline).bold()
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text("DOB").foregroundColor(.secondary); Spacer(); Text(formattedDOB()) }
                        HStack { Text("Age").foregroundColor(.secondary); Spacer(); Text(derivedAge()) }
                        HStack { Text("School").foregroundColor(.secondary); Spacer(); Text(store.profile.school.isEmpty ? "—" : store.profile.school) }
                        HStack { Text("Grade").foregroundColor(.secondary); Spacer(); Text(store.profile.grade.isEmpty ? "—" : store.profile.grade) }
                        HStack { Text("Location").foregroundColor(.secondary); Spacer(); Text(store.profile.location.isEmpty ? "—" : store.profile.location) }
                        HStack { Text("Position").foregroundColor(.secondary); Spacer(); Text(store.profile.position.isEmpty ? "—" : store.profile.position) }
                        HStack { Text("Club").foregroundColor(.secondary); Spacer(); Text(store.profile.clubTeam.isEmpty ? "—" : store.profile.clubTeam) }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
                .padding(.horizontal)

                // Quick actions: Activities / Statistics / Share
                HStack(spacing: 12) {
                    Button(action: {
                        Task { @MainActor in router.navigate(.activities) }
                    }) {
                        VStack { Image(systemName: "list.bullet.rectangle"); Text("Activities").font(.caption) }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
                    }

                    Button(action: {
                        // open goals editor sheet
                        showingGoals = true
                    }) {
                        VStack { Image(systemName: "flag"); Text("Goals").font(.caption) }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
                    }

                    Button(action: {
                        shareProfile()
                    }) {
                        VStack { Image(systemName: "square.and.arrow.up"); Text("Share").font(.caption) }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
                    }
                }
                .padding(.horizontal)

                // Mini sparkline and media carousel
                VStack(spacing: 12) {
                    SparklineView(values: recentSessionCounts())
                        .frame(height: 48)
                        .padding(.horizontal)

                    HStack(spacing: 8) {
                        ForEach(Array(recentImages().enumerated()), id: \.0) { _, img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("My Profile")
            .padding()
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

            // Bottom bar overlay: ensure it's visible on ProfileView
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
        // Bottom bar is provided by ContentView; no overlay here.
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
    }

    private func displayName() -> String {
        let f = store.profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = store.profile.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !f.isEmpty || !l.isEmpty {
            return [f, l].filter { !$0.isEmpty }.joined(separator: " ")
        }
        return "Your Name"
    }

    private func formattedDOB() -> String {
        // store.profile.dob is optional; unwrap safely
        guard let dob = store.profile.dob else { return "—" }
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: dob)
    }

    private func derivedAge() -> String {
        // store.profile.age is optional; prefer explicit age if present
        if let age = store.profile.age, age > 0 {
            return String(age)
        }
        // compute from dob if available
        guard let dob = store.profile.dob else { return "—" }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year], from: dob, to: Date())
        if let years = comps.year { return String(years) }
        return "—"
    }

    // MARK: - Helpers for sparkline / images / share
    private func recentSessionCounts(days: Int = 7) -> [Double] {
        // count sessions per day for the last `days` days
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

    private func recentImages(max: Int = 4) -> [UIImage] {
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

// A tiny sparkline view
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

// Simple outline button style matching the rough mock
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
