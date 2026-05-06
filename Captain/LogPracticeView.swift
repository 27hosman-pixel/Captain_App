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

    // Visibility default from Settings
    @AppStorage("default_session_public") private var defaultSessionPublic: Bool = true
    @State private var isPublic: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header to match ProfileView
                LogHeroHeader(
                    title: "Log Practice",
                    subtitle: "Record team or individual practice details, drills, health data and media."
                )

                // Cards stack
                VStack(spacing: 16) {
                    // Session card
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Session")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Session Type").font(.caption).foregroundColor(.secondary)
                                Picker("Type", selection: $sessionType) {
                                    Text("Team").tag("Team")
                                    Text("Individual").tag("Individual")
                                }
                                .pickerStyle(.segmented)
                            }

                            LabeledField(label: "Title") {
                                TextField("E.g. Wednesday Evening Practice", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Date & Time").font(.caption).foregroundColor(.secondary)
                                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                }
                                Spacer()
                            }

                            LabeledField(label: "Location") {
                                TextField("Stadium / Field / Park", text: $location)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Drills / Goals
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader("Drills / Goals")

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
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
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
                                    Image(systemName: "plus.circle.fill").font(.title3)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Health data
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader("Health Data")

                            HStack(spacing: 12) {
                                VStack(alignment: .leading) {
                                    Text("Total Miles").font(.caption2).foregroundColor(.secondary)
                                    TextField("e.g. 5.2", text: $totalMilesText)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }

                                VStack(alignment: .leading) {
                                    Text("Avg Heart Rate").font(.caption2).foregroundColor(.secondary)
                                    TextField("e.g. 142", text: $avgHeartRateText)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }

                            Text("Tip: If you enable health sync later, these fields can be pre-filled automatically.")
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Media
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader("Media")

                            PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                                AddMediaButton()
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
                                    .padding(.vertical, 4)
                                }
                            } else {
                                EmptyHint("Add photos or short clips from your practice.")
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Notes + footer
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Notes")
                            TextEditor(text: $notes)
                                .frame(minHeight: 120)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))

                            Divider().padding(.vertical, 4)

                            FooterActions(isPublic: $isPublic, onCancel: {
                                router.hideSidebar()
                                router.popToRoot()
                            }, onPreview: saveSession)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 24)
                }
                .padding(.top, 12)
            }
        }
        .onAppear {
            isPublic = defaultSessionPublic
        }
        .navigationTitle("Practice")
    }

    private func saveSession() {
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

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("SetPreview"),
                object: nil,
                userInfo: ["title": trimmedTitle, "date": date, "location": location, "type": "Practice", "details": details, "images": selectedImages, "origin": "practice", "isPublic": isPublic]
            )
            router.navigate(.preview)
        }
    }
}

// MARK: - Shared styling components (matching ProfileView)

private struct LogHeroHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.blue.opacity(0.85), Color.blue.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 140)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.08), Color.clear], startPoint: .top, endPoint: .bottom))
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .padding(.leading, 20)
            .padding(.bottom, 14)
        }
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 4)
    }
}

private struct SectionHeader: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.headline)
    }
}

private struct LabeledField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            content
        }
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
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
    }
}

private struct AddMediaButton: View {
    var body: some View {
        HStack {
            Image(systemName: "photo.on.rectangle")
            Text("Add Photos/Videos")
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
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

private struct FooterActions: View {
    @Binding var isPublic: Bool
    var onCancel: () -> Void
    var onPreview: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
            }

            VStack(spacing: 8) {
                Toggle(isOn: $isPublic) {
                    Text(isPublic ? "Public" : "Private")
                        .font(.caption)
                }
                .toggleStyle(.switch)

                Button(action: onPreview) {
                    Text("Preview")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                }
            }
        }
    }
}

struct LogPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        LogPracticeView()
            .environmentObject(AppRouter())
    }
}
