import SwiftUI
import UIKit
import Combine

struct PlayerProfile: Codable {
    var firstName: String = ""
    var lastName: String = ""
    var dob: Date?
    var school: String = ""
    var grade: String = ""
    var age: Int?
    var location: String = ""
    var position: String = ""
    var clubTeam: String = ""
    // persisted follower/following counts
    var followers: Int = 0
    var following: Int = 0
    // simple goals fields (editable from ProfileView)
    var goalsDay: String = ""
    var goalsWeek: String = ""
    var goalsSeason: String = ""
    // profile photo filename
    var profilePhotoFilename: String?
}

final class ProfileStore: ObservableObject {
    @Published var profile: PlayerProfile = PlayerProfile()
    private let key = "player_profile_v1"
    
    /// Check if user has completed their profile (minimum required fields)
    var hasProfile: Bool {
        !profile.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !profile.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            profile = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clear() {
        // Delete profile photo if exists
        if let filename = profile.profilePhotoFilename {
            deleteProfilePhoto(filename: filename)
        }
        profile = PlayerProfile()
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - Profile Photo Management
    
    /// Set profile photo - performs file I/O on background thread to avoid blocking main thread
    @MainActor
    func setProfilePhoto(_ image: UIImage) async {
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            // Delete old photo on background thread
            if let oldFilename = await self.profile.profilePhotoFilename {
                self.deleteProfilePhoto(filename: oldFilename)
            }
            
            // Save new photo on background thread
            let filename = "profile_\(UUID().uuidString).jpg"
            if self.saveProfilePhoto(image, filename: filename) {
                // Update UI on main thread
                await MainActor.run {
                    self.profile.profilePhotoFilename = filename
                    self.save()
                }
            }
        }.value
    }
    
    /// Get profile photo - loads from disk synchronously (acceptable for display)
    func getProfilePhoto() -> UIImage? {
        guard let filename = profile.profilePhotoFilename else { return nil }
        return loadProfilePhoto(filename: filename)
    }
    
    private func saveProfilePhoto(_ image: UIImage, filename: String) -> Bool {
        // JPEG compression happens on background thread - safe!
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let url = profilePhotoURL(filename: filename)
        do {
            // File write happens on background thread - safe!
            try data.write(to: url)
            return true
        } catch {
            print("Failed to save profile photo: \(error)")
            return false
        }
    }
    
    private func loadProfilePhoto(filename: String) -> UIImage? {
        let url = profilePhotoURL(filename: filename)
        // File read happens on background thread when called from async method
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    private func deleteProfilePhoto(filename: String) {
        let url = profilePhotoURL(filename: filename)
        // File delete happens on background thread when called from async method
        try? FileManager.default.removeItem(at: url)
    }
    
    private func profilePhotoURL(filename: String) -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDir.appendingPathComponent(filename)
    }
}

struct BuildProfileView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss
    
    // Local state for editing - prevents live updates to shared store
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var dob: Date?
    @State private var school: String = ""
    @State private var grade: String = ""
    @State private var age: Int?
    @State private var location: String = ""
    @State private var position: String = ""
    @State private var clubTeam: String = ""
    
    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(header: Text("Personal")) {
                // Name fields
                TextField("First name", text: $firstName)
                TextField("Last name", text: $lastName)

                DatePicker("Date of Birth", selection: Binding(
                    get: { dob ?? Date() },
                    set: { newVal in
                        dob = newVal
                        age = calculateAge(from: newVal)
                    }
                ), displayedComponents: .date)

                HStack {
                    Text("Age")
                    Spacer()
                    Text(age.map { String($0) } ?? "—")
                        .foregroundColor(.secondary)
                }

                TextField("School", text: $school)
                TextField("Grade", text: $grade)
                TextField("Location (City)", text: $location)
            }

            Section(header: Text("Soccer")) {
                TextField("Position", text: $position)
                TextField("Club Team", text: $clubTeam)
            }

            Section {
                Button("Save Profile") {
                    saveProfile()
                }
                .disabled(!canSave)
                
                if !canSave {
                    Text("Please enter at least your first and last name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Build Your Profile")
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    private func loadCurrentProfile() {
        // Pre-fill with existing data if editing
        firstName = profileStore.profile.firstName
        lastName = profileStore.profile.lastName
        dob = profileStore.profile.dob
        school = profileStore.profile.school
        grade = profileStore.profile.grade
        age = profileStore.profile.age
        location = profileStore.profile.location
        position = profileStore.profile.position
        clubTeam = profileStore.profile.clubTeam
    }
    
    private func saveProfile() {
        // Update the shared store only when saving
        profileStore.profile.firstName = firstName
        profileStore.profile.lastName = lastName
        profileStore.profile.dob = dob
        profileStore.profile.school = school
        profileStore.profile.grade = grade
        profileStore.profile.age = age
        profileStore.profile.location = location
        profileStore.profile.position = position
        profileStore.profile.clubTeam = clubTeam
        
        profileStore.save()
        
        // Notify ContentView that profile is complete
        NotificationCenter.default.post(name: Notification.Name("ProfileCompleted"), object: nil)
    }

    func calculateAge(from dob: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dob, to: now)
        return ageComponents.year ?? 0
    }
}

struct BuildProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BuildProfileView()
                .environmentObject(ProfileStore())
        }
    }
}
