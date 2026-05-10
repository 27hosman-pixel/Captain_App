import SwiftUI
import Combine
import UIKit

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
    
    func setProfilePhoto(_ image: UIImage) {
        // Delete old photo if exists
        if let oldFilename = profile.profilePhotoFilename {
            deleteProfilePhoto(filename: oldFilename)
        }
        
        // Save new photo
        let filename = "profile_\(UUID().uuidString).jpg"
        if saveProfilePhoto(image, filename: filename) {
            profile.profilePhotoFilename = filename
            save()
        }
    }
    
    func getProfilePhoto() -> UIImage? {
        guard let filename = profile.profilePhotoFilename else { return nil }
        return loadProfilePhoto(filename: filename)
    }
    
    private func saveProfilePhoto(_ image: UIImage, filename: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let url = profilePhotoURL(filename: filename)
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Failed to save profile photo: \(error)")
            return false
        }
    }
    
    private func loadProfilePhoto(filename: String) -> UIImage? {
        let url = profilePhotoURL(filename: filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    private func deleteProfilePhoto(filename: String) {
        let url = profilePhotoURL(filename: filename)
        try? FileManager.default.removeItem(at: url)
    }
    
    private func profilePhotoURL(filename: String) -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDir.appendingPathComponent(filename)
    }
}

struct BuildProfileView: View {
    @StateObject private var store = ProfileStore()
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        Form {
            Section(header: Text("Personal")) {
                // Name fields
                TextField("First name", text: Binding(get: { store.profile.firstName }, set: { store.profile.firstName = $0 }))
                TextField("Last name", text: Binding(get: { store.profile.lastName }, set: { store.profile.lastName = $0 }))

                DatePicker("Date of Birth", selection: Binding(get: {
                    store.profile.dob ?? Date()
                }, set: { newVal in
                    store.profile.dob = newVal
                    store.profile.age = calculateAge(from: newVal)
                }), displayedComponents: .date)

                HStack {
                    Text("Age")
                    Spacer()
                    Text(store.profile.age.map { String($0) } ?? "—")
                        .foregroundColor(.secondary)
                }

                TextField("School", text: Binding(get: { store.profile.school }, set: { store.profile.school = $0 }))
                TextField("Grade", text: Binding(get: { store.profile.grade }, set: { store.profile.grade = $0 }))
                TextField("Location (City)", text: Binding(get: { store.profile.location }, set: { store.profile.location = $0 }))
            }

            Section(header: Text("Soccer")) {
                TextField("Position", text: Binding(get: { store.profile.position }, set: { store.profile.position = $0 }))
                TextField("Club Team", text: Binding(get: { store.profile.clubTeam }, set: { store.profile.clubTeam = $0 }))
            }

            Section {
                Button("Save") {
                    store.save()
                    authStore.markProfileCompleted()
                    // Post a notification; ContentView listens and navigates safely
                    NotificationCenter.default.post(name: Notification.Name("NavigateToProfile"), object: nil)
                }
                Button("Clear") {
                    store.clear()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Build Your Profile")
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
        BuildProfileView()
            .environmentObject(AuthStore())
    }
}
