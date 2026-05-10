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
    var imageFileNames: [String]  // Changed from UIImage to filenames for persistence
    var origin: String?
    var isPublic: Bool
    var savedAt: Date  // Track when draft was saved
    
    init(id: UUID = UUID(), title: String, date: Date, location: String, sessionType: String, details: [String: String], imageFileNames: [String] = [], origin: String? = nil, isPublic: Bool = true, savedAt: Date = Date()) {
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
    @Published var details: [String: String] = [:] // arbitrary key-value pairs (goals, stats, etc)
    @Published var images: [UIImage] = []
    @Published var origin: String? = nil
    @Published var isPublic: Bool = true

    @Published var drafts: [PreviewData] = []
    
    // Track if current preview is from a draft (so we can delete it when posted)
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
        if let p = userInfo["isPublic"] as? Bool { isPublic = p }
        
        // This is a new preview from an editing form, not from a draft
        currentDraftId = nil
    }

    func setPreview(title: String, date: Date, location: String, sessionType: String, details: [String: String], images: [UIImage], origin: String? = nil, isPublic: Bool = true) {
        self.title = title
        self.date = date
        self.location = location
        self.sessionType = sessionType
        self.details = details
        self.images = images
        self.origin = origin
        self.isPublic = isPublic
        currentDraftId = nil  // This is a new session, not from a draft
    }

    func saveDraft() {
        // If we're updating an existing draft, use its ID; otherwise create new
        let draftId = currentDraftId ?? UUID()
        
        // If updating existing draft, remove the old one first
        if let existingId = currentDraftId {
            if let existing = drafts.first(where: { $0.id == existingId }) {
                deleteDraft(existing)
            }
        }
        
        // Save images to disk
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
            isPublic: isPublic,
            savedAt: Date()
        )
        drafts.insert(data, at: 0)  // Insert at beginning so newest drafts appear first
        currentDraftId = draftId  // Track this draft
        saveDrafts()
    }
    
    func loadDraft(_ draft: PreviewData) {
        print("📝 PreviewStore: Loading draft '\(draft.title)'")
        currentDraftId = draft.id  // Track which draft we're editing
        title = draft.title
        date = draft.date
        location = draft.location
        sessionType = draft.sessionType
        details = draft.details
        origin = draft.origin
        isPublic = draft.isPublic
        
        // Load images from disk
        images = draft.imageFileNames.compactMap { loadDraftImage(fileName: $0) }
        
        print("📝 PreviewStore: Loaded - Title: '\(title)', Type: '\(sessionType)', Details: \(details.count) items")
    }
    
    func deleteDraft(_ draft: PreviewData) {
        // Delete associated images
        for fileName in draft.imageFileNames {
            deleteDraftImage(fileName: fileName)
        }
        
        // Remove from array
        drafts.removeAll { $0.id == draft.id }
        saveDrafts()
    }
    
    func deleteDraftById(_ id: UUID) {
        if let draft = drafts.first(where: { $0.id == id }) {
            deleteDraft(draft)
        }
    }

    func clear() {
        title = ""
        date = Date()
        location = ""
        sessionType = ""
        details = [:]
        images = []
        origin = nil
        isPublic = true
        currentDraftId = nil  // Clear the draft tracking
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
