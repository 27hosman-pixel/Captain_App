import SwiftUI
import Combine 

struct SignUpView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authStore: AuthStore
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    @State private var showValidationAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isWorking = false

    private var runningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Create Account")
                    .font(.system(size: 40, weight: .bold))
                    .padding(.top, 24)

                Group {
                    Text("First Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("First name", text: $firstName)
                        .textFieldStyle(.roundedBorder)

                    Text("Last Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Last name", text: $lastName)
                        .textFieldStyle(.roundedBorder)

                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("you@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                Button(action: signup) {
                    if isWorking {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Sign up")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isWorking)
                .buttonStyle(PillButtonStyle(colors: [Color(red: 0.57, green: 0.66, blue: 0.98)], foreground: .white))
                .padding(.top, 8)
                .alert(alertMessage, isPresented: $showValidationAlert) {
                    Button("OK", role: .cancel) { }
                }

                Button(action: {
                    if runningInPreview {
                        print("Preview: skipping navigation to Build Profile")
                    } else {
                        NotificationCenter.default.post(name: Notification.Name("NavigateToBuildProfile"), object: nil)
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

    private func signup() {
        let f = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !f.isEmpty, !l.isEmpty, !e.isEmpty, password.count >= 6 else {
            alertMessage = "Please enter your full name, a valid email, and a password of at least 6 characters."
            showValidationAlert = true
            return
        }

        isWorking = true
        Task { @MainActor in
            do {
                try await authStore.signup(firstName: f, lastName: l, email: e, password: password)
                // ContentView will route to Build Profile automatically since hasCompletedProfile = false after signup.
            } catch {
                alertMessage = "Sign up failed. Please try again."
                showValidationAlert = true
            }
            isWorking = false
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AppRouter())
            .environmentObject(AuthStore())
    }
}
