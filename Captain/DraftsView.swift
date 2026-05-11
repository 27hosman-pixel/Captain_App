import SwiftUI

struct DraftsView: View {
    @EnvironmentObject var previewStore: PreviewStore
    @State private var draftToDelete: PreviewData?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Group {
            if previewStore.drafts.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Drafts")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Your saved drafts will appear here")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(previewStore.drafts) { draft in
                            DraftCard(draft: draft) {
                                // Resume editing this draft
                                previewStore.loadDraft(draft)
                                
                                // Navigate to appropriate Log view using NotificationCenter
                                // (ensures proper cross-tab navigation to Log tab)
                                DispatchQueue.main.async {
                                    switch draft.sessionType.lowercased() {
                                    case "practice":
                                        NotificationCenter.default.post(name: Notification.Name("NavigateToLogPractice"), object: nil)
                                    case "game":
                                        NotificationCenter.default.post(name: Notification.Name("NavigateToLogGame"), object: nil)
                                    case "training", "workout":
                                        NotificationCenter.default.post(name: Notification.Name("NavigateToLogWorkout"), object: nil)
                                    default:
                                        NotificationCenter.default.post(name: Notification.Name("NavigateToLogPractice"), object: nil)
                                    }
                                }
                            } onDelete: {
                                draftToDelete = draft
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
        }
        .navigationTitle("Drafts")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Draft", isPresented: $showingDeleteConfirmation, presenting: draftToDelete) { draft in
            Button("Delete", role: .destructive) {
                previewStore.deleteDraft(draft)
                draftToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                draftToDelete = nil
            }
        } message: { draft in
            Text("Are you sure you want to delete this draft? This action cannot be undone.")
        }
    }
}

private struct DraftCard: View {
    let draft: PreviewData
    var onResume: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.title.isEmpty ? "Untitled" : draft.title)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    HStack {
                        Text(draft.sessionType)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text("•")
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Text(draft.date, style: .date)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    Text("Saved \(timeAgo(from: draft.savedAt))")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .italic()
                }
                
                Spacer()
                
                // Thumbnail or icon
                if !draft.imageFileNames.isEmpty {
                    if let firstImage = loadImage(fileName: draft.imageFileNames[0]) {
                        Image(uiImage: firstImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                    }
                } else {
                    Image(systemName: activityIcon(for: draft.sessionType))
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Color(.systemGray6))
                        )
                }
            }
            
            // Action buttons
            HStack(spacing: Theme.Spacing.sm) {
                Button(action: onResume) {
                    HStack {
                        Spacer()
                        Text("Resume Editing")
                            .font(Theme.Typography.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.CornerRadius.sm)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                        .cornerRadius(Theme.CornerRadius.sm)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.divider, lineWidth: 0.5)
        )
        .shadow(
            color: Theme.Shadow.sm.color,
            radius: Theme.Shadow.sm.radius,
            x: Theme.Shadow.sm.x,
            y: Theme.Shadow.sm.y
        )
    }
    
    private func loadImage(fileName: String) -> UIImage? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = docs.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }
    
    private func activityIcon(for sessionType: String) -> String {
        switch sessionType.lowercased() {
        case "practice": return "figure.soccer"
        case "game": return "trophy.fill"
        case "training": return "dumbbell.fill"
        default: return "sportscourt.fill"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "just now"
        }
    }
}

struct DraftsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DraftsView()
                .environmentObject(PreviewStore())
        }
    }
}
