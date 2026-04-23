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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log Game")
                        .font(.largeTitle).bold()
                    Text("Record match stats, health data, media and notes.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    // Title / opponent
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("E.g. Saturday League Match", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("Opponent")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("Opponent Team", text: $opponent)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("Final Score")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("e.g. 3-1", text: $finalScore)
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
                        TextField("Stadium / Field", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Core stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Match Stats")
                            .font(.caption).foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading) {
                                Text("Minutes Played")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("90", text: $minutesPlayedText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            VStack(alignment: .leading) {
                                Text("Goals")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("0", text: $goalsText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            VStack(alignment: .leading) {
                                Text("Assists")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("0", text: $assistsText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            VStack(alignment: .leading) {
                                Text("Tackles")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("0", text: $tacklesText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }

                    // Custom stats
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Text("Custom Stats").font(.caption).foregroundColor(.secondary); Spacer() }

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

                        HStack {
                            TextField("Stat name (e.g. Sprints)", text: $newStatName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Value", text: $newStatValue)
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: {
                                let name = newStatName.trimmingCharacters(in: .whitespacesAndNewlines)
                                let value = newStatValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !name.isEmpty && !value.isEmpty else { return }
                                customStats.append(CustomStat(name: name, value: value))
                                newStatName = ""
                                newStatValue = ""
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

                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 6, matching: .images) {
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
                                    ForEach(selectedImages, id: \.self) { img in
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
                            Text("Preview")
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
        .navigationTitle("Game")
    }

    func saveSession() {
        // Basic validation
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let minutes = Int(minutesPlayedText)
        let goals = Int(goalsText)
        let assists = Int(assistsText)
        let tackles = Int(tacklesText)
        let miles = Double(totalMilesText)
        let hr = Int(avgHeartRateText)

        let session = GameSession(title: trimmedTitle, opponent: opponent, finalScore: finalScore, minutesPlayed: minutes, goals: goals, assists: assists, tackles: tackles, customStats: customStats, date: date, location: location, totalMiles: miles, avgHeartRate: hr, notes: notes)
        print("Saved game session:", session)

        // Build details
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
            NotificationCenter.default.post(name: Notification.Name("SetPreview"), object: nil, userInfo: ["title": trimmedTitle, "date": date, "location": location, "type": "Game", "details": details, "images": selectedImages])
            router.navigate(.preview)
        }
    }
}

struct LogGameView_Previews: PreviewProvider {
    static var previews: some View {
        LogGameView()
            .environmentObject(AppRouter())
    }
}
