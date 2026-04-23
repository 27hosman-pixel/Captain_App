import SwiftUI

struct ProfileView: View {
    @StateObject private var store = ProfileStore()
    @EnvironmentObject var router: AppRouter

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

                Spacer().frame(height: 8)

                // Profile details card (replaces About Me button)
                VStack(spacing: 12) {
                    HStack {
                        Text("About")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            NotificationCenter.default.post(name: Notification.Name("NavigateToBuildProfile"), object: nil)
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
    }
}
