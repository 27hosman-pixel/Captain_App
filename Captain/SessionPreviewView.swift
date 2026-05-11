import SwiftUI

/// Preview screen shown after logging a session
/// Allows users to review, share, save, or edit before finalizing
/// This is the bridge between logging forms (LogGameView, etc.) and session storage
struct SessionPreviewView: View {
    @EnvironmentObject var previewStore: PreviewStore
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    
    @State private var showShareSheet = false
    @State private var isSaving = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                // Preview content card
                previewContentCard
                    .padding(.horizontal, 16)
                
                // Divider
                Divider()
                    .padding(.vertical, 8)
                
                // Action buttons
                actionButtons
                    .padding(.horizontal, 16)
                
                Spacer(minLength: 60)
            }
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareCardView(previewStore: previewStore)
                .interactiveDismissDisabled(false)
        }
    }
    
    // MARK: - Preview Content Card
    
    @ViewBuilder
    private var previewContentCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with metadata
            VStack(alignment: .leading, spacing: 8) {
                // Session type badge
                HStack(spacing: 8) {
                    Image(systemName: sessionTypeIcon)
                        .font(.system(size: 16, weight: .semibold))
                    Text(previewStore.sessionType)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
                
                // Title
                Text(previewStore.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                // Date and location
                HStack(spacing: 16) {
                    Label(formattedDate, systemImage: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    if !previewStore.location.isEmpty {
                        Label(previewStore.location, systemImage: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            // Images preview
            if !previewStore.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(previewStore.images.indices, id: \.self) { index in
                            Image(uiImage: previewStore.images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 140)
                                .clipped()
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Stats/Details
            if !relevantDetails.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stats")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 12
                    ) {
                        ForEach(Array(relevantDetails.enumerated()), id: \.offset) { _, detail in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(detail.key)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Text(detail.value)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // PRIMARY CTA: Save to My Activities
            Button(action: saveSession) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Save to My Activities")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving)
            
            // Secondary: Share to Social Media (saves first, then shares)
            Button(action: saveAndShare) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Share to Social Media")
                        .font(.system(size: 17, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.bordered)
            .disabled(isSaving)
            
            // Secondary actions
            HStack(spacing: 12) {
                // Save as draft
                Button(action: saveDraft) {
                    Label("Save Draft", systemImage: "archivebox")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.bordered)
                
                // Edit
                Button(action: editSession) {
                    Label("Edit", systemImage: "pencil")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Actions
    
    /// Save session to SessionStore and navigate away
    private func saveSession() {
        guard !isSaving else { return }
        isSaving = true
        
        print("💾 SessionPreviewView: Starting save process...")
        print("💾 SessionPreviewView: Title: '\(previewStore.title)'")
        print("💾 SessionPreviewView: Type: '\(previewStore.sessionType)'")
        print("💾 SessionPreviewView: Images: \(previewStore.images.count)")
        
        // Save images to persistent storage and get filenames
        let imageFileNames = storeImages()
        print("💾 SessionPreviewView: Saved \(imageFileNames.count) image files")
        
        // Create SessionData from PreviewStore
        let sessionData = SessionData(
            id: UUID(),
            title: previewStore.title,
            date: previewStore.date,
            location: previewStore.location,
            sessionType: previewStore.sessionType,
            details: previewStore.details,
            imageFileNames: imageFileNames,
            origin: nil,
            isPublic: false
        )
        
        print("💾 SessionPreviewView: Posting SaveNewSession notification...")
        
        NotificationCenter.default.post(
            name: Notification.Name("SaveNewSession"),
            object: nil,
            userInfo: ["sessionData": sessionData]
        )
        
        print("💾 SessionPreviewView: Notification posted")
        
        if let draftId = previewStore.currentDraftId {
            previewStore.deleteDraftById(draftId)
        }
        
        previewStore.clear()
        
        NotificationCenter.default.post(name: Notification.Name("ShowPostedToast"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("NavigateToHome"), object: nil)
        
        print("💾 SessionPreviewView: Save complete, navigating to home")
        
        isSaving = false
    }
    
    /// Save current state as a draft, then go to Drafts screen
    private func saveDraft() {
        previewStore.saveDraft()
        
        // Haptic confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Navigate to Drafts
        NotificationCenter.default.post(name: Notification.Name("NavigateToDrafts"), object: nil)
    }
    
    /// Navigate back to the logging form — mimic the system Back button
    private func editSession() {
        dismiss()
    }
    
    /// Save session first, then show share sheet
    private func saveAndShare() {
        guard !isSaving else { return }
        isSaving = true
        
        print("💾 SessionPreviewView: Save and share - starting save...")
        
        // Save images to persistent storage and get filenames
        let imageFileNames = storeImages()
        
        // Create SessionData from PreviewStore
        let sessionData = SessionData(
            id: UUID(),
            title: previewStore.title,
            date: previewStore.date,
            location: previewStore.location,
            sessionType: previewStore.sessionType,
            details: previewStore.details,
            imageFileNames: imageFileNames,
            origin: nil,
            isPublic: false
        )
        
        // Save the session
        NotificationCenter.default.post(
            name: Notification.Name("SaveNewSession"),
            object: nil,
            userInfo: ["sessionData": sessionData]
        )
        
        // Delete draft if editing one
        if let draftId = previewStore.currentDraftId {
            previewStore.deleteDraftById(draftId)
        }
        
        print("💾 SessionPreviewView: Session saved, now showing share sheet")
        
        // Show share sheet
        showShareSheet = true
        
        isSaving = false
    }
    
    // MARK: - Helpers
    
    /// Store images from PreviewStore to persistent storage
    /// Returns array of filenames
    private func storeImages() -> [String] {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        var filenames: [String] = []
        let sessionId = UUID().uuidString
        
        for (index, image) in previewStore.images.enumerated() {
            let filename = "session-\(sessionId)-\(index).jpg"
            let fileURL = docs.appendingPathComponent(filename)
            
            if let data = image.jpegData(compressionQuality: 0.8) {
                do {
                    try data.write(to: fileURL, options: [.atomic])
                    filenames.append(filename)
                } catch {
                    print("❌ Failed to save image \(filename): \(error)")
                }
            }
        }
        
        return filenames
    }
    
    /// Filter out empty and notes from details for display
    private var relevantDetails: [(key: String, value: String)] {
        previewStore.details
            .filter { !$0.value.isEmpty && $0.value != "0" && $0.key.lowercased() != "notes" }
            .sorted { $0.key < $1.key }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: previewStore.date)
    }
    
    private var sessionTypeIcon: String {
        switch previewStore.sessionType.lowercased() {
        case "game": return "sportscourt.fill"
        case "practice": return "figure.run"
        case "training", "workout": return "dumbbell.fill"
        default: return "sportscourt.fill"
        }
    }
}

// MARK: - Preview

#Preview("Session Preview") {
    let previewStore = PreviewStore()
    previewStore.title = "Championship Match"
    previewStore.sessionType = "Game"
    previewStore.date = Date()
    previewStore.location = "National Stadium"
    previewStore.details = [
        "Goals": "2",
        "Assists": "1",
        "Minutes": "90",
        "Tackles": "8"
    ]
    
    return NavigationStack {
        SessionPreviewView()
            .environmentObject(previewStore)
            .environmentObject(SessionStore())
            .environmentObject(AppRouter())
    }
}
