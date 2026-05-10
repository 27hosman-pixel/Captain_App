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

    // Visibility default from Settings
    @AppStorage("default_session_public") private var defaultSessionPublic: Bool = true
    @State private var isPublic: Bool = true

    let focusOptions = ["Legs", "Arms", "Back", "Core", "Full Body"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Workout card
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Workout")

                    VStack(spacing: 12) {
                        ModernField(label: "Title") {
                            TextField("E.g. Gym Session - Legs", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type").font(.subheadline).foregroundColor(.secondary)
                            Picker("Type", selection: $workoutType) {
                                Text("Strength").tag("Strength")
                                Text("Agility").tag("Agility")
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Focus Area").font(.subheadline).foregroundColor(.secondary)
                            Picker("Focus", selection: $focusArea) {
                                ForEach(focusOptions, id: \.self) { area in
                                    Text(area).tag(area)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        ModernField(label: "Date & Time") {
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }

                        ModernField(label: "Duration (minutes)") {
                            TextField("e.g. 45", text: $durationText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding(.horizontal)

                // Performance metrics card
                VStack(alignment: .leading, spacing: 16) {
                    ModernSectionHeader("Performance Metrics")

                    HStack(spacing: 12) {
                        NumberField(title: "Sprints", text: $sprintsText)
                        NumberField(title: "Peak HR", text: $peakHRText)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Total Miles").font(.caption2).foregroundColor(.secondary)
                            TextField("e.g. 3.2", text: $totalMilesText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .padding(.horizontal)

                // Custom stats card
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

                        HStack {
                            TextField("Stat name (e.g. Power)", text: $newStatName)
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

                // Media card
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
                        Text("Save Workout")
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
        .navigationTitle("Log Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // initialize visibility from Settings
            isPublic = defaultSessionPublic
        }
    }

    private func saveSession() {
        // Dismiss keyboard so the tap isn't blocked and UI updates proceed
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let duration = Int(durationText)
        let sprints = Int(sprintsText)
        let peak = Int(peakHRText)
        let miles = Double(totalMilesText)

        let _ = WorkoutSession(
            title: trimmedTitle,
            workoutType: workoutType,
            focusArea: focusArea,
            date: date,
            durationMinutes: duration,
            sprints: sprints,
            peakHeartRate: peak,
            customStats: customStats,
            totalMiles: miles,
            notes: notes
        )

        var details: [String: String] = [
            "Type": workoutType,
            "Focus": focusArea,
            "Duration": duration != nil ? "\(duration!)" : "",
            "Sprints": sprints != nil ? "\(sprints!)" : "",
            "PeakHR": peak != nil ? "\(peak!)" : "",
            "TotalMiles": miles != nil ? String(format: "%.2f", miles!) : "",
            "Notes": notes
        ]
        for s in customStats { details[s.name] = s.value }

        NotificationCenter.default.post(
            name: Notification.Name("SetPreview"),
            object: nil,
            userInfo: [
                "title": trimmedTitle,
                "date": date,
                "location": "",
                "type": "Workout",
                "details": details,
                "images": selectedImages,
                "origin": "workout",
                "isPublic": isPublic
            ]
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

struct LogWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogWorkoutView()
            .environmentObject(AppRouter())
    }
}
