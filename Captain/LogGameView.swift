import SwiftUI
import PhotosUI

struct GameSession: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var opponent: String
    var finalScore: String
    var minutesPlayed: Int?
    var goals: Int?
    var assists: Int?
    var tackles: Int?
    var customStats: [CustomStat]
    var date: Date
    var location: String
    var totalMiles: Double?
    var avgHeartRate: Int?
    var notes: String
}

struct LogGameView: View {
    @EnvironmentObject var router: AppRouter

    @State private var title: String = ""
    @State private var opponent: String = ""
    @State private var finalScore: String = ""
    @State private var minutesPlayedText: String = ""
    @State private var goalsText: String = ""
    @State private var assistsText: String = ""
    @State private var tacklesText: String = ""

    @State private var customStats: [CustomStat] = []
    @State private var newStatName: String = ""
    @State private var newStatValue: String = ""

    @State private var date: Date = Date()
    @State private var location: String = ""

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
            VStack(spacing: 24) {
                // Core info
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Match")

                    VStack(spacing: 12) {
                        ModernField(label: "Title") {
                            TextField("E.g. Saturday League Match", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        ModernField(label: "Opponent") {
                            TextField("Opponent Team", text: $opponent)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        ModernField(label: "Final Score") {
                            TextField("e.g. 3-1", text: $finalScore)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        ModernField(label: "Date & Time") {
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }

                        ModernField(label: "Location") {
                            TextField("Stadium / Field", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding(.horizontal)

                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Match Stats")

                    HStack(spacing: 12) {
                        NumberField(title: "Minutes", text: $minutesPlayedText)
                        NumberField(title: "Goals", text: $goalsText)
                        NumberField(title: "Assists", text: $assistsText)
                        NumberField(title: "Tackles", text: $tacklesText)
                    }
                }
                .padding(.horizontal)

                // Custom stats
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Custom Stats")

                    VStack(spacing: 10) {
                        if customStats.isEmpty {
                            EmptyHint("Add any stat you want to track.")
                        } else {
                            ForEach(Array(customStats.enumerated()), id: \.offset) { index, stat in
                                HStack {
                                    Text(stat.name)
                                    Spacer()
                                    Text(stat.value)
                                    Button(role: .destructive) {
                                        customStats.remove(at: index)
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
                            TextField("Stat name (e.g. Sprints)", text: $newStatName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Value", text: $newStatValue)
                                .frame(width: 90)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button {
                                let name = newStatName.trimmingCharacters(in: .whitespacesAndNewlines)
                                let value = newStatValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !name.isEmpty && !value.isEmpty else { return }
                                customStats.append(CustomStat(name: name, value: value))
                                newStatName = ""
                                newStatValue = ""
                            } label: {
                                Image(systemName: "plus.circle.fill").font(.title2)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .padding(.horizontal)

                // Health
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
                    }
                }
                .padding(.horizontal)

                // Media
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Media")

                    VStack(spacing: 12) {
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 6, matching: .images) {
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
                        Text("Save Game")
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
        .navigationTitle("Log Game")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isPublic = defaultSessionPublic
        }
    }

    private func saveSession() {
        // Dismiss keyboard so the tap isn't blocked and UI updates proceed
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let minutes = Int(minutesPlayedText)
        let goals = Int(goalsText)
        let assists = Int(assistsText)
        let tackles = Int(tacklesText)
        let miles = Double(totalMilesText)
        let hr = Int(avgHeartRateText)

        let _ = GameSession(title: trimmedTitle, opponent: opponent, finalScore: finalScore, minutesPlayed: minutes, goals: goals, assists: assists, tackles: tackles, customStats: customStats, date: date, location: location, totalMiles: miles, avgHeartRate: hr, notes: notes)

        var details: [String: String] = [
            "Opponent": opponent,
            "Final Score": finalScore,
            "Minutes": minutes != nil ? "\(minutes!)" : "",
            "Goals": goals != nil ? "\(goals!)" : "",
            "Assists": assists != nil ? "\(assists!)" : "",
            "Tackles": tackles != nil ? "\(tackles!)" : "",
            "Notes": notes
        ]
        for s in customStats { details[s.name] = s.value }

        NotificationCenter.default.post(
            name: Notification.Name("SetPreview"),
            object: nil,
            userInfo: ["title": trimmedTitle, "date": date, "location": location, "type": "Game", "details": details, "images": selectedImages, "isPublic": isPublic]
        )

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

private struct NumberField: View {
    let title: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption2).foregroundColor(.secondary)
            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
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

struct LogGameView_Previews: PreviewProvider {
    static var previews: some View {
        LogGameView()
            .environmentObject(AppRouter())
    }
}
