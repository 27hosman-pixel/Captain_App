import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: AppRouter
    @State private var email: String = ""
    @State private var password: String = ""

    // helper to detect previews
    private var runningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Log In")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 24)

                Group {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("you@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .padding(.bottom, 8)

                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                Button(action: {
                    // TODO: implement login action
                    print("Log in with", email)
                    // simulate success -> navigate to Profile (deferred to avoid navigation-time crash)
                    if runningInPreview {
                        print("Preview: skipping navigation to Profile")
                    } else {
                        DispatchQueue.main.async {
                            router.replaceWith(.profile)
                        }
                    }
                }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(colors: [Color(red: 0.57, green: 0.66, blue: 0.98)], foreground: .white))
                .padding(.top, 8)

                Button(action: {
                    if runningInPreview {
                        print("Preview: skipping navigation to Build Profile")
                    } else {
                        DispatchQueue.main.async {
                            router.replaceWith(.buildProfile)
                        }
                    }
                }) {
                    Text("Build your profile")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding([.horizontal, .bottom], 24)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppRouter())
    }
}
