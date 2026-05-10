import SwiftUI
import PhotosUI
import Photos

/// Full-screen interface for previewing and sharing stat cards
/// Allows users to choose format, style, and export destination
struct ShareCardView: View {
    let previewStore: PreviewStore
    
    @State private var selectedFormat: StatCardFormat = .square
    @State private var selectedStyle: StatCardVisualStyle = .midnight
    @State private var renderedImage: UIImage?
    @State private var isRendering: Bool = false
    @State private var showingSaveConfirmation: Bool = false
    @State private var showingPermissionAlert: Bool = false
    @State private var showingShareSheet: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Format selector
                    FormatSelectorView(selectedFormat: $selectedFormat)
                        .padding(.top, 8)
                    
                    // Live preview
                    previewSection
                    
                    // Style selector (collapsible)
                    StyleSelectorView(selectedStyle: $selectedStyle)
                    
                    // Actions
                    actionsSection
                        .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Share Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task(id: selectedFormat) {
                await renderCard()
            }
            .task(id: selectedStyle) {
                await renderCard()
            }
            .alert("Saved to Photos", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your stat card has been saved to your photo library.")
            }
            .alert("Photo Access Required", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) { }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please allow Captain to access your photos in Settings to save stat cards.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = renderedImage {
                    ActivityViewController(activityItems: [image])
                }
            }
        }
    }
    
    // MARK: - Preview Section
    
    @ViewBuilder
    private var previewSection: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            ZStack {
                if isRendering {
                    // Loading state
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray6))
                        .aspectRatio(selectedFormat.aspectRatio, contentMode: .fit)
                        .overlay {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Generating preview...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                } else if let image = renderedImage {
                    // Rendered preview
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                } else {
                    // Error state
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray6))
                        .aspectRatio(selectedFormat.aspectRatio, contentMode: .fit)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.orange)
                                Text("Preview unavailable")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Actions Section
    
    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Primary: Share
            Button(action: { showingShareSheet = true }) {
                Label("Share to...", systemImage: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(renderedImage == nil)
            
            // Secondary: Save to Photos
            Button(action: saveToPhotos) {
                Label("Save to Photos", systemImage: "arrow.down.circle")
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.bordered)
            .disabled(renderedImage == nil)
        }
    }
    
    // MARK: - Actions
    
    /// Render the stat card with current settings
    @MainActor
    private func renderCard() async {
        isRendering = true
        
        // Small delay to show loading state
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        renderedImage = await StatCardRenderer.render(
            from: previewStore,
            style: selectedStyle,
            format: selectedFormat
        )
        
        isRendering = false
    }
    
    /// Save the rendered image to Photos with proper permission handling
    private func saveToPhotos() {
        guard let image = renderedImage else { return }
        
        // Request permission first, then save
        requestPhotoLibraryPermission { granted in
            if granted {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                
                // Show confirmation
                DispatchQueue.main.async {
                    showingSaveConfirmation = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } else {
                // Permission denied - show alert
                DispatchQueue.main.async {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    /// Request photo library permission
    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        // For iOS 14+, we request "add only" permission (safer, less intrusive)
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                completion(status == .authorized || status == .limited)
            }
        } else {
            // iOS 13 and earlier
            PHPhotoLibrary.requestAuthorization { status in
                completion(status == .authorized)
            }
        }
    }
}

// MARK: - UIActivityViewController Wrapper

/// SwiftUI wrapper for UIActivityViewController (share sheet)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview("Share Card View") {
    let previewStore = PreviewStore()
    previewStore.title = "Championship Game"
    previewStore.sessionType = "Game"
    previewStore.date = Date()
    previewStore.location = "National Stadium"
    previewStore.details = [
        "Goals": "2",
        "Assists": "1",
        "Minutes": "90",
        "Tackles": "8",
        "Shots": "5"
    ]
    
    return ShareCardView(previewStore: previewStore)
}
