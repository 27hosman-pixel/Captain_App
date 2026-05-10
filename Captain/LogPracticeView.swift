import SwiftUI
import PhotosUI

struct PracticeSession: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var sessionType: String
    var date: Date
    var location: String
    var drills: [String]
    var totalMiles: Double?
    var avgHeartRate: Int?
    var notes: String
}

struct LogPracticeView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var previewStore: PreviewStore

    @State private var sessionType: String = "Team"
    @State private var title: String = ""
    @State private var date = Date()
    @State private var location: String = ""

    @State private var drills: [String] = []
    @State private var newDrill: String = ""

    @State private var totalMilesText: String = ""
    @State private var avgHeartRateText: String = ""

    @State private var notes: String = ""

    // Photos
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    // Visibility default from Settings
    @AppStorage("default_session_public") private var defaultSessionPublic: Bool = true
    @State private var isPublic: Bool = true
    
    // Track the last loaded draft ID to prevent double-loading the same draft
    @State private var loadedDraftId: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Session card
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Session Details")
                    
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Type").font(.subheadline).foregroundColor(.secondary)
                            Picker("Type", selection: $sessionType) {
                                Text("Team").tag("Team")
                                Text("Individual").tag("Individual")
                            }
                            .pickerStyle(.segmented)
                        }

                        ModernField(label: "Title") {
                            TextField("E.g. Wednesday Evening Practice", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        ModernField(label: "Date & Time") {
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }

                        ModernField(label: "Location") {
                            TextField("Stadium / Field / Park", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding(.horizontal)

                // Drills / Goals
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Drills / Goals")
                    
                    VStack(spacing: 10) {
                        if drills.isEmpty {
                            EmptyHint("Add drills or goals you focused on.")
                        } else {
                            ForEach(Array(drills.enumerated()), id: \.offset) { index, drill in
                                HStack {
                                    Text(drill).lineLimit(1)
                                    Spacer()
                                    Button(role: .destructive) {
                                        drills.remove(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }

                        HStack(spacing: 8) {
                            TextField("Add drill or goal", text: $newDrill)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button {
                                let trimmed = newDrill.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                drills.append(trimmed)
                                newDrill = ""
                            } label: {
                                Image(systemName: "plus.circle.fill").font(.title2)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding(.horizontal)

                // Health data
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Health Data")
                    
                    VStack(spacing: 12) {
                        ModernField(label: "Total Miles") {
                            TextField("e.g. 5.2", text: $totalMilesText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        ModernField(label: "Avg Heart Rate") {
                            TextField("e.g. 142", text: $avgHeartRateText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Text("Tip: If you enable health sync later, these fields can be pre-filled automatically.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Media
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Media")
                    
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                            ModernMediaButton()
                        }
                        .onChange(of: selectedItems) { _, newItems in
                            Task {
                                selectedImages = []
                                for item in newItems {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let ui = UIImage(data: data) {
                                        selectedImages.append(ui)
                                    }
                                }
                            }
                        }

                        if !selectedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(selectedImages, id: \.self) { img in
                                        MediaThumb(image: img)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Notes
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Notes")
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4)))
                }
                .padding(.horizontal)
                
                // Footer actions
                VStack(spacing: 12) {
                    Toggle(isOn: $isPublic) {
                        HStack {
                            Image(systemName: isPublic ? "globe" : "lock.fill")
                            Text(isPublic ? "Public" : "Private")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button(action: saveSession) {
                        Text("Save Practice")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        router.hideSidebar()
                        router.popToRoot()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        .navigationTitle("Log Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isPublic = defaultSessionPublic
            loadDraftIfNeeded()
        }
    }
    
    private func loadDraftIfNeeded() {
        print("🏈 LogPracticeView: loadDraftIfNeeded called")
        print("🏈 loadedDraftId: \(String(describing: loadedDraftId))")
        print("🏈 previewStore.currentDraftId: \(String(describing: previewStore.currentDraftId))")
        print("🏈 previewStore.title: '\(previewStore.title)'")
        print("🏈 previewStore.sessionType: '\(previewStore.sessionType)'")
        print("🏈 previewStore.details: \(previewStore.details)")
        
        // Check if we have draft data AND we haven't loaded THIS specific draft yet
        guard let draftId = previewStore.currentDraftId,
              loadedDraftId != draftId,
              !previewStore.title.isEmpty else {
            print("🏈 LogPracticeView: Skipping draft load")
            print("   - Has currentDraftId: \(previewStore.currentDraftId != nil)")
            print("   - Already loaded this draft: \(loadedDraftId == previewStore.currentDraftId)")
            print("   - Has title: \(!previewStore.title.isEmpty)")
            return
        }
        
        print("🏈 LogPracticeView: ✅ Loading draft data...")
        
        // Load data from PreviewStore (from a resumed draft)
        title = previewStore.title
        date = previewStore.date
        location = previewStore.location
        isPublic = previewStore.isPublic
        selectedImages = previewStore.images
        
        print("🏈 Set title to: '\(title)'")
        print("🏈 Set location to: '\(location)'")
        print("🏈 Set images count: \(selectedImages.count)")
        
        // Parse details
        if let type = previewStore.details["Type"] {
            sessionType = type
            print("🏈 Loaded session type: \(type)")
        }
        
        if let drillsStr = previewStore.details["Drills"], !drillsStr.isEmpty {
            drills = drillsStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            print("🏈 Loaded drills: \(drills)")
        }
        
        if let milesStr = previewStore.details["TotalMiles"], !milesStr.isEmpty {
            totalMilesText = milesStr
            print("🏈 Loaded miles: \(milesStr)")
        }
        
        if let hrStr = previewStore.details["Avg HR"], !hrStr.isEmpty {
            avgHeartRateText = hrStr
            print("🏈 Loaded HR: \(hrStr)")
        }
        
        if let notesStr = previewStore.details["Notes"] {
            notes = notesStr
            print("🏈 Loaded notes: \(notesStr)")
        }
        
        // Mark this draft as loaded
        loadedDraftId = draftId
        print("🏈 LogPracticeView: ✅ Draft loaded successfully! Marked as loaded: \(draftId)")
    }

    private func saveSession() {
        // Dismiss keyboard so the tap isn’t blocked and UI updates proceed
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let miles = Double(totalMilesText)
        let hr = Int(avgHeartRateText)

        let _ = PracticeSession(title: trimmedTitle, sessionType: sessionType, date: date, location: location, drills: drills, totalMiles: miles, avgHeartRate: hr, notes: notes)

        let details: [String: String] = [
            "Type": sessionType,
            "Drills": drills.joined(separator: ", "),
            "TotalMiles": miles != nil ? String(format: "%.2f", miles!) : "",
            "Avg HR": hr != nil ? "\(hr!)" : "",
            "Notes": notes
        ]

        NotificationCenter.default.post(
            name: Notification.Name("SetPreview"),
            object: nil,
            userInfo: ["title": trimmedTitle, "date": date, "location": location, "type": "Practice", "details": details, "images": selectedImages, "origin": "practice", "isPublic": isPublic]
        )

        // Belt-and-suspenders: also signal ContentView to navigate
        NotificationCenter.default.post(name: Notification.Name("NavigateToPreview"), object: nil)

        Task { @MainActor in
            router.navigate(.preview)
        }
    }
}

// MARK: - Modern Styling Components

private struct ModernSectionHeader: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.primary)
    }
}

private struct ModernField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            content
        }
    }
}

private struct ModernMediaButton: View {
    var body: some View {
        HStack {
            Image(systemName: "photo")
                .font(.system(size: 28))
            Text("Add Photos/Video")
                .font(.headline)
            Spacer()
        }
        .foregroundColor(.white)
        .padding(20)
        .background(Color(.systemGray4))
        .cornerRadius(12)
    }
}

private struct MediaThumb: View {
    let image: UIImage
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 96, height: 96)
            .clipped()
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator)))
    }
}

private struct EmptyHint: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            Text(text)
                .foregroundColor(.secondary)
            Spacer()
        }
        .font(.caption)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}

struct LogPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        LogPracticeView()
            .environmentObject(AppRouter())
    }
}
