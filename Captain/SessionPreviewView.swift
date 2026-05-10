import SwiftUI

struct SessionPreviewView: View {
    @EnvironmentObject var previewStore: PreviewStore
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Title
                Text(previewStore.title)
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.text)
                    .padding(.top, Theme.Spacing.md)

                // Metadata row
                HStack {
                    Text(previewStore.sessionType)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text(previewStore.date, style: .date)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(.horizontal, Theme.Spacing.md)

                // Image carousel
                if !previewStore.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(Array(previewStore.images.enumerated()), id: \.0) { index, img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 120)
                                    .clipped()
                                    .cornerRadius(Theme.CornerRadius.sm)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                }

                // Details card
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Details")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    ForEach(previewStore.details.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key + ":")
                                .font(Theme.Typography.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.Colors.text)
                            Text(value)
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.text)
                            Spacer()
                        }
                        .padding(.vertical, Theme.Spacing.xxs)
                    }
                }
                .cardStyle()
                .padding(.horizontal, Theme.Spacing.md)

                // Visibility toggle
                HStack {
                    Text("Visibility")
                        .font(Theme.Typography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    Picker("Visibility", selection: $previewStore.isPublic) {
                        Text("Public").tag(true)
                        Text("Private").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                .padding(.horizontal, Theme.Spacing.md)

                // Actions
                VStack(spacing: Theme.Spacing.sm) {
                    // Post button (primary)
                    Button(action: {
                        sessionStore.addSession(
                            title: previewStore.title,
                            date: previewStore.date,
                            location: previewStore.location,
                            sessionType: previewStore.sessionType,
                            details: previewStore.details,
                            images: previewStore.images,
                            origin: previewStore.origin,
                            isPublic: previewStore.isPublic
                        )
                        previewStore.clear()
                        router.replaceWith(.activities)
                        NotificationCenter.default.post(
                            name: Notification.Name("ShowPostedToast"),
                            object: nil
                        )
                    }) {
                        Text("Post")
                    }
                    .buttonStyle(ThemePrimaryButtonStyle())

                    // Secondary actions
                    HStack(spacing: Theme.Spacing.sm) {
                        Button(action: {
                            previewStore.saveDraft()
                            previewStore.clear()
                            router.popToRoot()
                        }) {
                            Text("Save Draft")
                        }
                        .buttonStyle(ThemeSecondaryButtonStyle())

                        Button(action: {
                            router.popToRoot()
                        }) {
                            Text("Edit")
                        }
                        .buttonStyle(ThemeSecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.lg)
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

