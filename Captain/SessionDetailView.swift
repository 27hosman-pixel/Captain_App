import SwiftUI

struct SessionDetailView: View {
    let session: SessionData
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(session.title)
                    .font(.title).bold()
                Text(session.sessionType + " • " + DateFormatter.localizedString(from: session.date, dateStyle: .medium, timeStyle: .short))
                    .font(.subheadline).foregroundColor(.secondary)

                if !session.imageFileNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(session.imageFileNames, id: \.self) { name in
                                if let img = sessionStore.image(for: name) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 140)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    ForEach(session.details.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                        HStack {
                            Text(k + ":").bold()
                            Text(v)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Session")
    }
}

struct SessionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let store = SessionStore()
        SessionDetailView(session: SessionData(id: UUID(), title: "Test", date: Date(), location: "Park", sessionType: "Practice", details: ["Goals":"2"], imageFileNames: []))
            .environmentObject(store)
    }
}
