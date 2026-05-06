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
            VStack(spacing: 0) {
                LogHeroHeader(
                    title: "Log Game",
                    subtitle: "Record match stats, health data, media and notes."
                )

                VStack(spacing: 16) {
                    // Core info
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Match")

                            Group {
                                LabeledField(label: "Title") {
                                    TextField("E.g. Saturday League Match", text: $title)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                LabeledField(label: "Opponent") {
                                    TextField("Opponent Team", text: $opponent)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                LabeledField(label: "Final Score") {
                                    TextField("e.g. 3-1", text: $finalScore)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading) {
                                    Text("Date & Time").font(.caption).foregroundColor(.secondary)
                                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                }
                                Spacer()
                            }

                            LabeledField(label: "Location") {
                                TextField("Stadium / Field", text: $location)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Stats
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Match Stats")

                            HStack(spacing: 12) {
                                NumberField(title: "Minutes", text: $minutesPlayedText)
                                NumberField(title: "Goals", text: $goalsText)
                                NumberField(title: "Assists", text: $assistsText)
                                NumberField(title: "Tackles", text: $tacklesText)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Custom stats
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader("Custom Stats")

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
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
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
                                    Image(systemName: "plus.circle.fill").font(.title3)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Health
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
                        }
                    }
                    .padding(.horizontal)

                    // Media
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader("Media")

                            PhotosPicker(selection: $selectedItems, maxSelectionCount: 6, matching: .images) {
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
                                EmptyHint("Add photos or clips from your game.")
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Notes + footer actions
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
        .navigationTitle("Game")
    }

    private func saveSession() {
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

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("SetPreview"), object: nil, userInfo: ["title": trimmedTitle, "date": date, "location": location, "type": "Game", "details": details, "images": selectedImages, "isPublic": isPublic])
            router.navigate(.preview)
        }
    }
}

// MARK: - Shared styling components (copied here so this file builds standalone)

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

struct LogGameView_Previews: PreviewProvider {
    static var previews: some View {
        LogGameView()
            .environmentObject(AppRouter())
    }
}
