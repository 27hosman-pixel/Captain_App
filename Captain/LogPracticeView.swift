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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log Practice")
                        .font(.largeTitle).bold()
                    Text("Record team or individual practice details, drills, health data and media.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding(.horizontal)

                // Form container
                VStack(spacing: 12) {
                    // Session type
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Type")
                            .font(.caption).foregroundColor(.secondary)
                        Picker("Type", selection: $sessionType) {
                            Text("Team").tag("Team")
                            Text("Individual").tag("Individual")
                        }
                        .pickerStyle(.segmented)
                    }

                    // Title & date
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("E.g. Wednesday Evening Practice", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Date & Time")
                                    .font(.caption).foregroundColor(.secondary)
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }
                            Spacer()
                        }

                        Text("Location")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("Stadium / Field / Park", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Drills / Goals section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text("Drills / Goals").font(.caption).foregroundColor(.secondary); Spacer() }

                        ForEach(Array(drills.enumerated()), id: \ .offset) { index, drill in
                            HStack {
                                Text(drill)
                                    .lineLimit(1)
                                Spacer()
                                Button(role: .destructive) {
                                    drills.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }

                        HStack {
                            TextField("Add drill or goal", text: $newDrill)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                let trimmed = newDrill.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                drills.append(trimmed)
                                newDrill = ""
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    // Health data
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Data")
                            .font(.caption).foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading) {
                                Text("Total Miles")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("e.g. 5.2", text: $totalMilesText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            VStack(alignment: .leading) {
                                Text("Avg Heart Rate")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("e.g. 142", text: $avgHeartRateText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        Text("Tip: If you enable health sync later, these fields can be pre-filled automatically.")
                            .font(.caption2).foregroundColor(.secondary)
                    }

                    // Media
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Media")
                            .font(.caption).foregroundColor(.secondary)

                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Add Photos/Videos")
                                Spacer()
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                        }
                        .onChange(of: selectedItems) { _, newItems in
                            Task {
                                selectedImages = []
                                for item in newItems {
                                    if let data = try? await item.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                                        selectedImages.append(ui)
                                    }
                                }
                            }
                        }

                        if !selectedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedImages, id: \ .self) { img in
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 96, height: 96)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 120)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
                    }

                    // Save/Cancel
                    HStack(spacing: 12) {
                        Button(action: {
                            router.hideSidebar()
                            router.popToRoot()
                        }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
                        }

                        Button(action: saveSession) {
                            Text("Save Practice")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Practice")
    }

    func saveSession() {
        // Basic validation
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            // Could present an alert; for now just return
            return
        }

        let miles = Double(totalMilesText)
        let hr = Int(avgHeartRateText)

        let session = PracticeSession(title: trimmedTitle, sessionType: sessionType, date: date, location: location, drills: drills, totalMiles: miles, avgHeartRate: hr, notes: notes)
        // TODO: persist session to store or backend. For now, print to console.
        print("Saved session:", session)

        // Prepare preview
        let details: [String: String] = [
            "Type": session.sessionType,
            "Drills": drills.joined(separator: ", "),
            "Miles": miles != nil ? String(format: "%.2f", miles!) : "",
            "Avg HR": hr != nil ? "\(hr!)" : "",
            "Notes": notes
        ]

        // set preview store
        if let preview = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController as? UIViewController {
            // noop to keep previews quiet in SwiftUI canvas
        }

        // Use environment object injection at call site — instead we'll post a notification that PreviewStore can listen to, but simpler: navigate and rely on global PreviewStore injected in ContentView
        DispatchQueue.main.async {
            // populate shared PreviewStore (retrieved from environment in ContentView)
            NotificationCenter.default.post(name: Notification.Name("SetPreview"), object: nil, userInfo: ["title": trimmedTitle, "date": date, "location": location, "type": session.sessionType, "details": details, "images": selectedImages])
            router.navigate(.preview)
        }
    }
}

struct LogPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        LogPracticeView()
            .environmentObject(AppRouter())
    }
}
