import SwiftUI
import Combine
import UIKit

// A lightweight struct to hold a preview/draft
struct PreviewData: Identifiable, Codable {
    let id: UUID
    var title: String
    var date: Date
    var location: String
    var sessionType: String
    var details: [String: String]
    var imageFileNames: [String]
    var origin: String?
    var isPublic: Bool
    var savedAt: Date
    
    init(id: UUID = UUID(), title: String, date: Date, location: String, sessionType: String, details: [String: String], imageFileNames: [String] = [], origin: String? = nil, isPublic: Bool = false, savedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.sessionType = sessionType
        self.details = details
        self.imageFileNames = imageFileNames
        self.origin = origin
        self.isPublic = isPublic
        self.savedAt = savedAt
    }
}

// A lightweight store to hold a session preview before posting
final class PreviewStore: ObservableObject {
    @Published var title: String = ""
    @Published var date: Date = Date()
    @Published var location: String = ""
    @Published var sessionType: String = ""
    @Published var details: [String: String] = [:]
    @Published var images: [UIImage] = []
    @Published var origin: String? = nil
    @Published var isPublic: Bool = false

    @Published var drafts: [PreviewData] = []
    
    var currentDraftId: UUID? = nil
    
    private let draftsFile = "drafts.json"

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSetPreview(_:)), name: Notification.Name("SetPreview"), object: nil)
        loadDrafts()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleSetPreview(_ note: Notification) {
        guard let userInfo = note.userInfo else { return }
        if let t = userInfo["title"] as? String { title = t }
        if let d = userInfo["date"] as? Date { date = d }
        if let l = userInfo["location"] as? String { location = l }
        if let s = userInfo["type"] as? String { sessionType = s }
        if let det = userInfo["details"] as? [String: String] { details = det }
        if let imgs = userInfo["images"] as? [UIImage] { images = imgs }
        if let o = userInfo["origin"] as? String { origin = o }
        
        currentDraftId = nil
    }

    func setPreview(title: String, date: Date, location: String, sessionType: String, details: [String: String], images: [UIImage], origin: String? = nil) {
        self.title = title
        self.date = date
        self.location = location
        self.sessionType = sessionType
        self.details = details
        self.images = images
        self.origin = origin
        self.isPublic = false
        currentDraftId = nil
    }

    func saveDraft() {
        let draftId = currentDraftId ?? UUID()
        
        if let existingId = currentDraftId {
            if let existing = drafts.first(where: { $0.id == existingId }) {
                deleteDraft(existing)
            }
        }
        
        let imageFileNames = storeDraftImages(images, for: draftId)
        
        let data = PreviewData(
            id: draftId,
            title: title,
            date: date,
            location: location,
            sessionType: sessionType,
            details: details,
            imageFileNames: imageFileNames,
            origin: origin,
            isPublic: false,
            savedAt: Date()
        )
        drafts.insert(data, at: 0)
        currentDraftId = draftId
        saveDrafts()
    }
    
    func loadDraft(_ draft: PreviewData) {
        print("📝 PreviewStore: Loading draft '\(draft.title)'")
        currentDraftId = draft.id
        title = draft.title
        date = draft.date
        location = draft.location
        sessionType = draft.sessionType
        details = draft.details
        origin = draft.origin
        isPublic = false
        
        images = draft.imageFileNames.compactMap { loadDraftImage(fileName: $0) }
        
        print("📝 PreviewStore: Loaded - Title: '\(title)', Type: '\(sessionType)', Details: \(details.count) items")
    }
    
    func deleteDraft(_ draft: PreviewData) {
        for fileName in draft.imageFileNames {
            deleteDraftImage(fileName: fileName)
        }
        
        drafts.removeAll { $0.id == draft.id }
        saveDrafts()
    }
    
    func deleteDraftById(_ id: UUID) {
        if let draft = drafts.first(where: { $0.id == id }) {
            deleteDraft(draft)
        }
    }
    
    /// Clear all drafts and their associated image files
    func clearAllDrafts() {
        // Delete all draft images
        for draft in drafts {
            for fileName in draft.imageFileNames {
                deleteDraftImage(fileName: fileName)
            }
        }
        
        // Clear the drafts array
        drafts.removeAll()
        
        // Save empty array to disk
        saveDrafts()
        
        print("🗑️ PreviewStore: Cleared all drafts and associated images")
    }

    func clear() {
        title = ""
        date = Date()
        location = ""
        sessionType = ""
        details = [:]
        images = []
        origin = nil
        isPublic = false
        currentDraftId = nil
    }
    
    // MARK: - Persistence
    
    private func documentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private func draftsURL() -> URL? {
        documentsDirectory()?.appendingPathComponent(draftsFile)
    }
    
    private func loadDrafts() {
        guard let url = draftsURL(), FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([PreviewData].self, from: data)
            DispatchQueue.main.async {
                self.drafts = decoded.sorted { $0.savedAt > $1.savedAt }
            }
        } catch {
            print("Failed to load drafts:", error)
        }
    }
    
    private func saveDrafts() {
        guard let url = draftsURL() else { return }
        do {
            let data = try JSONEncoder().encode(drafts)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Failed to save drafts:", error)
        }
    }
    
    // Image storage for drafts
    private func storeDraftImages(_ images: [UIImage], for id: UUID) -> [String] {
        guard let docs = documentsDirectory() else { return [] }
        var names: [String] = []
        for (i, img) in images.enumerated() {
            let name = "draft-\(id.uuidString)-img-\(i).jpg"
            let url = docs.appendingPathComponent(name)
            if let data = img.jpegData(compressionQuality: 0.8) {
                do {
                    try data.write(to: url, options: [.atomic])
                    names.append(name)
                } catch {
                    print("Failed to write draft image", error)
                }
            }
        }
        return names
    }
    
    private func loadDraftImage(fileName: String) -> UIImage? {
        guard let docs = documentsDirectory() else { return nil }
        let url = docs.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }
    
    private func deleteDraftImage(fileName: String) {
        guard let docs = documentsDirectory() else { return }
        let url = docs.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Failed to delete draft image \(fileName):", error)
            }
        }
    }
}
