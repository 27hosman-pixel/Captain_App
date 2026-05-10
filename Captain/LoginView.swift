import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authStore: AuthStore
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

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
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.bottom, 8)

                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                Button(action: login) {
                    if isWorking {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isWorking)
                .buttonStyle(PillButtonStyle(colors: [Color(red: 0.57, green: 0.66, blue: 0.98)], foreground: .white))
                .padding(.top, 8)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }

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

    private func login() {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = password
        guard !e.isEmpty && p.count >= 6 else {
            errorMessage = "Enter a valid email and a password of at least 6 characters."
            return
        }
        errorMessage = nil
        isWorking = true
        Task { @MainActor in
            do {
                try await authStore.login(email: e, password: p)
                // Routing is handled by ContentView observing auth state.
            } catch {
                errorMessage = "Login failed. Please try again."
            }
            isWorking = false
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppRouter())
            .environmentObject(AuthStore())
    }
}
