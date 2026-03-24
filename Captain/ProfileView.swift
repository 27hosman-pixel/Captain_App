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

                // Big action buttons
                VStack(spacing: 14) {
                    Button(action: { print("About Me tapped") }) {
                        Text("About Me!")
                            .font(.title3).bold()
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(OutlineButtonStyle())

                    Button(action: { print("Season Stats tapped") }) {
                        Text("Season Stats")
                            .font(.title3).bold()
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(OutlineButtonStyle())

                    Button(action: { print("My Log tapped") }) {
                        Text("My Log")
                            .font(.title3).bold()
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(OutlineButtonStyle())

                    Button(action: { print("Share my Profile tapped") }) {
                        Text("Share my Profile")
                            .font(.title3).bold()
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
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
                router.toggleSidebar()
            }) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 8)
            .padding(.leading, 8)
            .accessibilityLabel("Open menu")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    router.toggleSidebar()
                }) {
                    Image(systemName: "line.horizontal.3")
                        .imageScale(.large)
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
