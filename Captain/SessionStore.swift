import SwiftUI
import Combine

struct SessionData: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var location: String
    var sessionType: String
    var details: [String: String]
    var imageFileNames: [String]
    var origin: String?

    init(id: UUID = UUID(), title: String, date: Date, location: String, sessionType: String, details: [String: String], imageFileNames: [String] = [], origin: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.sessionType = sessionType
        self.details = details
        self.imageFileNames = imageFileNames
        self.origin = origin
    }
}

final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [SessionData] = []

    private let sessionsFile = "sessions.json"

    init() {
        load()
    }

    private func documentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private func sessionsURL() -> URL? {
        documentsDirectory()?.appendingPathComponent(sessionsFile)
    }

    func load() {
        guard let url = sessionsURL(), FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([SessionData].self, from: data)
            DispatchQueue.main.async {
                self.sessions = decoded
            }
        } catch {
            print("Failed to load sessions:", error)
        }
    }

    func save() {
        guard let url = sessionsURL() else { return }
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Failed to save sessions:", error)
        }
    }

    // Save images to documents and return filenames
    private func store(images: [UIImage], for id: UUID) -> [String] {
        guard let docs = documentsDirectory() else { return [] }
        var names: [String] = []
        for (i, img) in images.enumerated() {
            let name = "session-\(id.uuidString)-img-\(i).jpg"
            let url = docs.appendingPathComponent(name)
            if let data = img.jpegData(compressionQuality: 0.8) {
                do {
                    try data.write(to: url, options: [.atomic])
                    names.append(name)
                } catch {
                    print("Failed to write image", error)
                }
            }
        }
        return names
    }

    func addSession(title: String, date: Date, location: String, sessionType: String, details: [String: String], images: [UIImage] = [], origin: String? = nil) {
        let id = UUID()
        let imageFileNames = store(images: images, for: id)
        let s = SessionData(id: id, title: title, date: date, location: location, sessionType: sessionType, details: details, imageFileNames: imageFileNames, origin: origin)
        sessions.insert(s, at: 0)
        save()
    }

    func image(for fileName: String) -> UIImage? {
        guard let docs = documentsDirectory() else { return nil }
        let url = docs.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    func clearAll() {
        sessions = []
        save()
    }
}
