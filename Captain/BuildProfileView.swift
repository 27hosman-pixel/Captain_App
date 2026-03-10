import SwiftUI
import Combine

struct PlayerProfile: Codable {
    var dob: Date?
    var school: String = ""
    var grade: String = ""
    var age: Int?
    var location: String = ""
    var position: String = ""
    var clubTeam: String = ""
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
        profile = PlayerProfile()
        UserDefaults.standard.removeObject(forKey: key)
    }
}

struct BuildProfileView: View {
    @StateObject private var store = ProfileStore()
    @Environment(
        \.presentationMode
    ) var presentationMode

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal")) {
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

                    TextField("School", text: $store.profile.school)
                    TextField("Grade", text: $store.profile.grade)
                    TextField("Location (City)", text: $store.profile.location)
                }

                Section(header: Text("Soccer")) {
                    TextField("Position", text: $store.profile.position)
                    TextField("Club Team", text: $store.profile.clubTeam)
                }

                Section {
                    Button("Save") {
                        store.save()
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Clear") {
                        store.clear()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Build Your Profile")
        }
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
    }
}
