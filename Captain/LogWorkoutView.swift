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
            VStack(spacing: 0) {
                // Hero header to match ProfileView
                LogHeroHeader(
                    title: "Log Workout",
                    subtitle: "Strength or agility sessions — track sprints, peak HR and custom stats."
                )

                VStack(spacing: 16) {
                    // Workout card
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Workout")

                            LabeledField(label: "Title") {
                                TextField("E.g. Gym Session - Legs", text: $title)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Type").font(.caption).foregroundColor(.secondary)
                                Picker("Type", selection: $workoutType) {
                                    Text("Strength").tag("Strength")
                                    Text("Agility").tag("Agility")
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Focus Area").font(.caption).foregroundColor(.secondary)
                                Picker("Focus", selection: $focusArea) {
                                    ForEach(focusOptions, id: \.self) { area in
                                        Text(area).tag(area)
                                    }
                                }
                                .pickerStyle(.menu)
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Date & Time").font(.caption).foregroundColor(.secondary)
                                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                }
                                Spacer()
                            }

                            LabeledField(label: "Duration (minutes)") {
                                TextField("e.g. 45", text: $durationText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Performance metrics card
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Performance Metrics")

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
                    }
                    .padding(.horizontal)

                    // Custom stats card
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
                                    Image(systemName: "plus.circle.fill").font(.title3)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Media card
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
                                EmptyHint("Add photos or clips from your workout.")
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Notes + footer actions card
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
            // initialize visibility from Settings
            isPublic = defaultSessionPublic
        }
        .navigationTitle("Workout")
    }

    private func saveSession() {
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

        DispatchQueue.main.async {
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
            router.navigate(.preview)
        }
    }
}

// MARK: - Shared styling components (match ProfileView)

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

struct LogWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        LogWorkoutView()
            .environmentObject(AppRouter())
    }
}
