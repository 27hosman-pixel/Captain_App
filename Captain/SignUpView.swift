import SwiftUI

struct SignUpView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        NavigationStack {
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
                        // TODO: implement sign up action
                        print("Sign up", firstName, lastName, email)
                    }) {
                        Text("Sign up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.57, green: 0.66, blue: 0.98)], foreground: .white))
                    .padding(.top, 8)

                    // Link to build profile
                    NavigationLink(destination: BuildProfileView()) {
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
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
