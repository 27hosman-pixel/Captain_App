import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("My Profile")
                .font(.largeTitle).bold()

            Text("This will show the player's profile (DOB, school, position, club, etc.).")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .navigationTitle("Profile")
        .padding()
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
