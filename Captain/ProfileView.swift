import SwiftUI
import SwiftUI
import UIKit

struct ProfileView: View {
    @StateObject private var store = ProfileStore()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showingGoals: Bool = false
    @State private var showingAboutEditor: Bool = false
    @State private var showingPhotoPicker: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showingImageEditor: Bool = false
    @State private var sessionToDelete: SessionData?
    @State private var showingDeleteConfirmation: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile header section
                VStack(spacing: Theme.Spacing.md) {
                    // Avatar and name row
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        // Avatar
                        Button(action: { showingPhotoPicker = true }) {
                            if let profileImage = store.getProfilePhoto() {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Name and location
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName())
                                .font(.system(size: 24, weight: .bold))
                            
                            if !store.profile.location.isEmpty {
                                Text(store.profile.location)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            
                            if !store.profile.position.isEmpty {
                                Text(store.profile.position)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                    
                    // Stats row
                    HStack(spacing: 0) {
                        StatColumn(title: "Following", value: "\(store.profile.following)")
                        StatColumn(title: "Followers", value: "\(store.profile.followers)")
                        StatColumn(title: "Activities", value: "\(sessionStore.sessions.count)")
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Action buttons
                    HStack(spacing: Theme.Spacing.sm) {
                        Button(action: {
                            Task { @MainActor in
                                router.navigate(.buildProfile)
                            }
                        }) {
                            Text("Edit Profile")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Theme.Colors.primary, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            shareProfile()
                        }) {
                            Text("Share")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Theme.Colors.primary, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.bottom, Theme.Spacing.lg)

                // Content sections
                VStack(spacing: Theme.Spacing.md) {
                    // Recent activity
                    RecentActivitySection(
                        sessions: sessionStore.sessions,
                        sessionStore: sessionStore,
                        onAdd: { router.navigate(.logSessionChoice) },
                        onDelete: { session in
                            sessionToDelete = session
                            showingDeleteConfirmation = true
                        }
                    )

                    // Goals
                    GoalsRow(
                        day: store.profile.goalsDay,
                        week: store.profile.goalsWeek,
                        season: store.profile.goalsSeason,
                        onEdit: { showingGoals = true }
                    )

                    // About
                    AboutCard(
                        dob: formattedDOB(),
                        age: derivedAge(),
                        school: store.profile.school,
                        grade: store.profile.grade,
                        location: store.profile.location,
                        position: store.profile.position,
                        club: store.profile.clubTeam,
                        onEdit: {
                            showingAboutEditor = true
                        }
                    )

                    Spacer(minLength: Theme.Spacing.lg)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.md)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.load()
        }
        // Goals editor sheet
        .sheet(isPresented: $showingGoals) {
            NavigationView {
                Form {
                    Section(header: Text("Daily Goal")) {
                        TextField("Day goals", text: Binding(get: { store.profile.goalsDay }, set: { store.profile.goalsDay = $0 }))
                    }
                    Section(header: Text("Weekly Goal")) {
                        TextField("Week goals", text: Binding(get: { store.profile.goalsWeek }, set: { store.profile.goalsWeek = $0 }))
                    }
                    Section(header: Text("Season Goal")) {
                        TextField("Season goals", text: Binding(get: { store.profile.goalsSeason }, set: { store.profile.goalsSeason = $0 }))
                    }
                    Section {
                        Button("Save") {
                            store.save()
                            showingGoals = false
                        }
                        Button("Cancel") {
                            showingGoals = false
                        }
                        .foregroundColor(.red)
                    }
                }
                .navigationTitle("Goals")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showingGoals = false }
                    }
                }
            }
        }
        // About editor sheet
        .sheet(isPresented: $showingAboutEditor) {
            NavigationView {
                Form {
                    Section(header: Text("Personal Info")) {
                        DatePicker(
                            "Date of Birth",
                            selection: Binding(
                                get: { store.profile.dob ?? Date() },
                                set: { store.profile.dob = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        
                        TextField(
                            "Age",
                            text: Binding(
                                get: { store.profile.age != nil ? String(store.profile.age!) : "" },
                                set: { store.profile.age = Int($0) }
                            )
                        )
                        .keyboardType(.numberPad)
                    }
                    
                    Section(header: Text("School")) {
                        TextField("School Name", text: Binding(get: { store.profile.school }, set: { store.profile.school = $0 }))
                        
                        TextField(
                            "Grade",
                            text: Binding(
                                get: { store.profile.grade },
                                set: { store.profile.grade = $0 }
                            )
                        )
                    }
                    
                    Section(header: Text("Soccer Info")) {
                        TextField("Location", text: Binding(get: { store.profile.location }, set: { store.profile.location = $0 }))
                        
                        TextField("Position", text: Binding(get: { store.profile.position }, set: { store.profile.position = $0 }))
                        
                        TextField("Club Team", text: Binding(get: { store.profile.clubTeam }, set: { store.profile.clubTeam = $0 }))
                    }
                }
                .navigationTitle("About")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAboutEditor = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            store.save()
                            showingAboutEditor = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker { image in
                if let image {
                    selectedImage = image
                    showingImageEditor = true
                }
            }
        }
        .sheet(isPresented: $showingImageEditor) {
            if let selectedImage {
                ImageCropperView(image: selectedImage) { croppedImage in
                    if let croppedImage {
                        store.setProfilePhoto(croppedImage)
                    }
                    showingImageEditor = false
                }
            }
        }
        // Reserve space above the global bottom bar so content isn't blocked
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 20)
        }
        .alert("Delete Post", isPresented: $showingDeleteConfirmation, presenting: sessionToDelete) { session in
            Button("Delete", role: .destructive) {
                sessionStore.delete(session: session)
                sessionToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        } message: { session in
            Text("Are you sure you want to delete \"\(session.title)\"? This action cannot be undone.")
        }
    }

    // MARK: - Helpers (unchanged)
    private func displayName() -> String {
        let f = store.profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = store.profile.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !f.isEmpty || !l.isEmpty {
            return [f, l].filter { !$0.isEmpty }.joined(separator: " ")
        }
        return "Your Name"
    }

    private func formattedDOB() -> String {
        guard let dob = store.profile.dob else { return "—" }
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: dob)
    }

    private func derivedAge() -> String {
        if let age = store.profile.age, age > 0 {
            return String(age)
        }
        guard let dob = store.profile.dob else { return "—" }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year], from: dob, to: Date())
        if let years = comps.year { return String(years) }
        return "—"
    }

    private func shareProfile() {
        let text = "Check out my Captain profile: \(displayName())"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

// MARK: - Subviews

private struct StatColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


private struct GoalsRow: View {
    let day: String
    let week: String
    let season: String
    var onEdit: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Goals")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    ThemeEditButton(action: onEdit)
                }
                
                VStack(spacing: Theme.Spacing.sm) {
                    GoalRow(label: "Day", value: day)
                    GoalRow(label: "Week", value: week)
                    GoalRow(label: "Season", value: season)
                }
            }
        }
    }

    private func GoalRow(label: String, value: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(width: 60, alignment: .leading)
            
            Text(value.isEmpty ? "—" : value)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.Colors.divider, lineWidth: 0.5)
        )
    }
}

private struct AboutCard: View {
    let dob: String
    let age: String
    let school: String
    let grade: String
    let location: String
    let position: String
    let club: String
    var onEdit: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("About")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    ThemeEditButton(action: onEdit)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: Theme.Spacing.sm
                ) {
                    ThemeInfoRow(title: "Date of Birth", value: dob)
                    ThemeInfoRow(title: "Age", value: age)
                    ThemeInfoRow(title: "School", value: school)
                    ThemeInfoRow(title: "Grade", value: grade)
                    ThemeInfoRow(title: "Location", value: location)
                    ThemeInfoRow(title: "Position", value: position)
                    ThemeInfoRow(title: "Club Team", value: club)
                }
            }
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
            Text(value.isEmpty ? "—" : value)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Color(.systemGray6))
        )
    }
}

private struct RecentActivitySection: View {
    let sessions: [SessionData]
    let sessionStore: SessionStore
    var onAdd: () -> Void
    var onDelete: (SessionData) -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Recent Activity")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    NavigationLink("View All", value: Destination.activities)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.primary)
                }

                SparklineView(values: sparkValues)
                    .frame(height: 44)
                    .padding(.vertical, Theme.Spacing.xxs)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        AddTile(action: onAdd)
                        ForEach(Array(sessions.prefix(12).enumerated()), id: \.element.id) { index, session in
                            SessionThumbnail(
                                session: session,
                                sessionStore: sessionStore,
                                onDelete: { onDelete(session) }
                            )
                        }
                    }
                    .padding(.trailing, Theme.Spacing.xxs)
                }
            }
        }
    }
    
    private var sparkValues: [Double] {
        let calendar = Calendar.current
        let days = 7
        var counts = Array(repeating: 0.0, count: days)
        let now = Date()
        for s in sessions {
            let comps = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: s.date))
            if let daysAgo = comps.day {
                let index = days - 1 - daysAgo
                if index >= 0 && index < days {
                    counts[index] += 1.0
                }
            }
        }
        return counts
    }
}

private struct SessionThumbnail: View {
    let session: SessionData
    let sessionStore: SessionStore
    var onDelete: () -> Void
    
    @State private var showingOptions = false
    
    var body: some View {
        Menu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Post", systemImage: "trash")
            }
        } label: {
            if let firstImageName = session.imageFileNames.first,
               let image = sessionStore.image(for: firstImageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipped()
                    .cornerRadius(Theme.CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .stroke(Theme.Colors.divider, lineWidth: 0.5)
                    )
            } else {
                // Fallback for sessions without images
                VStack(spacing: 4) {
                    Image(systemName: activityIcon)
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.primary)
                    Text(session.sessionType)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(1)
                }
                .frame(width: 96, height: 96)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .stroke(Theme.Colors.divider, lineWidth: 0.5)
                )
            }
        }
    }
    
    private var activityIcon: String {
        switch session.sessionType.lowercased() {
        case "practice": return "figure.soccer"
        case "game": return "trophy.fill"
        case "training": return "dumbbell.fill"
        default: return "sportscourt.fill"
        }
    }
}

private struct AddTile: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: Theme.IconSize.xl))
                    .foregroundColor(Theme.Colors.primary)
                Text("Add")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.text)
            }
            .frame(width: 96, height: 96)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .stroke(Theme.Colors.divider, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SparklineView: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maxVal = max(values.max() ?? 1, 1)
            let stepX = values.count > 1 ? width / CGFloat(values.count - 1) : 0

            Path { path in
                for (i, v) in values.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = height - CGFloat(v / maxVal) * height
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
    }
}

private struct ActionTile: View {
    let title: String
    let system: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ActionTileContent(title: title, system: system)
        }
        .buttonStyle(.plain)
    }
}

private struct ActionTileContent: View {
    let title: String
    let system: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: system)
                .font(.system(size: Theme.IconSize.lg, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.15),
                                    Color.blue.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.divider, lineWidth: 0.5)
        )
    }
}


private struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.divider, lineWidth: 0.5)
            )
            .shadow(
                color: Theme.Shadow.sm.color,
                radius: Theme.Shadow.sm.radius,
                x: Theme.Shadow.sm.x,
                y: Theme.Shadow.sm.y
            )
    }
}

// MARK: - Image Cropper with Zoom/Pan

struct ImageCropperView: View {
    let image: UIImage
    let completion: (UIImage?) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                GeometryReader { geometry in
                    let size = geometry.size
                    let cropSize = min(size.width, size.height) * 0.7
                    
                    ZStack {
                        // Image with zoom and pan
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: size.width, height: size.height)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale *= delta
                                        // Limit scale
                                        scale = min(max(scale, 1.0), 5.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        
                        // Crop overlay
                        ZStack {
                            // Dimmed background
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: size.width, height: size.height)
                                .overlay(
                                    Circle()
                                        .frame(width: cropSize, height: cropSize)
                                        .blendMode(.destinationOut)
                                )
                            
                            // Circle outline
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: cropSize, height: cropSize)
                        }
                        .allowsHitTesting(false)
                        .compositingGroup()
                    }
                    .frame(width: size.width, height: size.height)
                }
            }
            .navigationTitle("Adjust Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        completion(nil)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        cropImage()
                    }
                }
            }
        }
    }
    
    private func cropImage() {
        guard let cgImage = image.cgImage else {
            dismiss()
            completion(nil)
            return
        }
        
        // Calculate crop parameters
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let screenSize = UIScreen.main.bounds.size
        let cropSize = min(screenSize.width, screenSize.height) * 0.7
        
        // Scale factor from screen to image
        let imageScale = max(
            imageSize.width / screenSize.width,
            imageSize.height / screenSize.height
        )
        
        // Apply user's scale
        let totalScale = imageScale / scale
        
        // Calculate crop rect in image coordinates
        let cropSizeInImage = cropSize * totalScale
        
        // Convert offset to image coordinates
        let offsetInImage = CGSize(
            width: -offset.width * imageScale / scale,
            height: -offset.height * imageScale / scale
        )
        
        let cropRect = CGRect(
            x: (imageSize.width - cropSizeInImage) / 2 + offsetInImage.width,
            y: (imageSize.height - cropSizeInImage) / 2 + offsetInImage.height,
            width: cropSizeInImage,
            height: cropSizeInImage
        )
        
        // Crop the image
        if let croppedCGImage = cgImage.cropping(to: cropRect) {
            let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
            dismiss()
            completion(croppedImage)
        } else {
            dismiss()
            completion(nil)
        }
    }
}

// MARK: - PhotoPicker using UIKit

import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    let completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (UIImage?) -> Void
        
        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else {
                completion(nil)
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        self?.completion(image as? UIImage)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AppRouter())
                .environmentObject(SessionStore())
        }
    }
}
