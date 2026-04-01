import SwiftUI
import PhotosUI

// Removed duplicate CustomStat — using shared Models.swift

struct WorkoutSession: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var workoutType: String
    var focusArea: String
    var date: Date
    var durationMinutes: Int?
    var sprints: Int?
    var peakHeartRate: Int?
    var customStats: [CustomStat]
    var totalMiles: Double?
    var notes: String
}

struct LogWorkoutView: View {
    @EnvironmentObject var router: AppRouter

    @State private var title: String = ""
    @State private var workoutType: String = "Strength"
    @State private var focusArea: String = "Legs"
    @State private var date: Date = Date()
    @State private var durationText: String = ""
    @State private var sprintsText: String = ""
    @State private var peakHRText: String = ""

    @State private var customStats: [CustomStat] = []
    @State private var newStatName: String = ""
    @State private var newStatValue: String = ""

    @State private var totalMilesText: String = ""
    @State private var notes: String = ""

    // Photos
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    let focusOptions = ["Legs", "Arms", "Back", "Core", "Full Body"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log Workout")
                        .font(.largeTitle).bold()
                    Text("Strength or agility sessions — track sprints, peak HR and custom stats.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("E.g. Gym Session - Legs", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Text("Type")
                            .font(.caption).foregroundColor(.secondary)
                        Picker("Type", selection: $workoutType) {
                            Text("Strength").tag("Strength")
                            Text("Agility").tag("Agility")
                        }
                        .pickerStyle(.segmented)

                        Text("Focus Area")
                            .font(.caption).foregroundColor(.secondary)
                        Picker("Focus", selection: $focusArea) {
                            ForEach(focusOptions, id: \.self) { area in
                                Text(area).tag(area)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Date & Time")
                                    .font(.caption).foregroundColor(.secondary)
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }
                            Spacer()
                        }

                        Text("Duration (minutes)")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("e.g. 45", text: $durationText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Sprint + Peak HR
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Performance Metrics")
                            .font(.caption).foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading) {
                                Text("Sprints")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("# of sprints", text: $sprintsText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            VStack(alignment: .leading) {
                                Text("Peak HR")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("bpm", text: $peakHRText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            VStack(alignment: .leading) {
                                Text("Total Miles")
                                    .font(.caption2).foregroundColor(.secondary)
                                TextField("e.g. 3.2", text: $totalMilesText)
                                    .keyboardType(.decimalPad)
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
                            TextField("Stat name (e.g. Power)", text: $newStatName)
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
                            Text("Save Workout")
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
        .navigationTitle("Workout")
    }

    func saveSession() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let duration = Int(durationText)
        let sprints = Int(sprintsText)
        let peak = Int(peakHRText)
        let miles = Double(totalMilesText)

        let session = WorkoutSession(title: trimmedTitle, workoutType: workoutType, focusArea: focusArea, date: date, durationMinutes: duration, sprints: sprints, peakHeartRate: peak, customStats: customStats, totalMiles: miles, notes: notes)
        print("Saved workout:", session)

        DispatchQueue.main.async {
            router.navigate(.home)
        }
    }
}

struct LogWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogWorkoutView()
            .environmentObject(AppRouter())
    }
}
