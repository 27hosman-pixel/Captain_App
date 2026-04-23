import SwiftUI

struct MessagingView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("No messages yet")
            }
            .navigationTitle("Messaging")
        }
    }
}

struct MessagingView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingView()
    }
}
