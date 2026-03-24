import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var router: AppRouter
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    // added validation alert state
    @State private var showValidationAlert: Bool = false
    @State private var alertMessage: String = ""

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

                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }

                Button(action: {
                    // simple validation before navigating
                    let f = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let l = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let e = email.trimmingCharacters(in: .whitespacesAndNewlines)

                    if f.isEmpty || l.isEmpty || e.isEmpty || password.count < 6 {
                        alertMessage = "Please enter your full name, a valid email, and a password of at least 6 characters."
                        showValidationAlert = true
                        return
                    }

                    // TODO: perform real sign-up logic here (network request, validation, etc.)
                    print("Sign up", firstName, lastName, email)

                    if runningInPreview {
                        print("Preview: skipping navigation to Build Profile")
                    } else {
                        DispatchQueue.main.async {
                            router.navigate(.buildProfile)
                        }
                    }
                }) {
                    Text("Sign up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(colors: [Color(red: 0.57, green: 0.66, blue: 0.98)], foreground: .white))
                .padding(.top, 8)
                .alert(alertMessage, isPresented: $showValidationAlert) {
                    Button("OK", role: .cancel) { }
                }

                // Link to build profile
                Button(action: {
                    if runningInPreview {
                        print("Preview: skipping navigation to Build Profile")
                    } else {
                        DispatchQueue.main.async {
                            router.navigate(.buildProfile)
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

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AppRouter())
    }
}
