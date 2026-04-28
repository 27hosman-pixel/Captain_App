import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        List {
            if sessionStore.sessions.isEmpty {
                Text("No activities yet")
            } else {
                ForEach(sessionStore.sessions) { s in
                    NavigationLink(value: s) {
                        HStack(spacing: 12) {
                            if let first = s.imageFileNames.first, let img = sessionStore.image(for: first) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            }

                            VStack(alignment: .leading) {
                                Text(s.title)
                                    .font(.headline)
                                Text(s.sessionType + " • " + DateFormatter.localizedString(from: s.date, dateStyle: .medium, timeStyle: .short))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Activities")
        .navigationDestination(for: SessionData.self) { session in
            SessionDetailView(session: session)
        }
    }
}

struct ActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        ActivitiesView()
            .environmentObject(SessionStore())
    }
}
