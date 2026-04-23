import SwiftUI

struct SessionPreviewView: View {
    @EnvironmentObject var previewStore: PreviewStore
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(previewStore.title)
                    .font(.largeTitle).bold()
                    .padding(.top)

                HStack {
                    Text(previewStore.sessionType)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(previewStore.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                if !previewStore.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(previewStore.images.enumerated()), id: \.0) { index, img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 120)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    ForEach(previewStore.details.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key + ":")
                                .font(.subheadline).bold()
                            Text(value)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal)

                // Actions
                HStack(spacing: 12) {
                    Button(action: {
                        // Persist session using SessionStore
                        sessionStore.addSession(title: previewStore.title, date: previewStore.date, location: previewStore.location, sessionType: previewStore.sessionType, details: previewStore.details, images: previewStore.images, origin: previewStore.origin)
                        previewStore.clear()
                        router.popToRoot()
                    }) {
                        Text("Post")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                    }

                    Button(action: {
                        // Save draft
                        previewStore.saveDraft()
                        previewStore.clear()
                        router.popToRoot()
                    }) {
                        Text("Save Draft")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
                    }

                    Button(action: {
                        // Edit: go back to the last screen to adjust
                        router.popToRoot()
                    }) {
                        Text("Edit")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Preview")
    }
}

struct SessionPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        SessionPreviewView()
            .environmentObject(PreviewStore())
            .environmentObject(AppRouter())
            .environmentObject(SessionStore())
    }
}
