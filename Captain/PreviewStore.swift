import SwiftUI
import Combine
import UIKit

// A lightweight struct to hold a preview/draft
struct PreviewData: Identifiable {
    let id = UUID()
    var title: String
    var date: Date
    var location: String
    var sessionType: String
    var details: [String: String]
    var images: [UIImage]
    var origin: String?
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

    @Published var drafts: [PreviewData] = []

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSetPreview(_:)), name: Notification.Name("SetPreview"), object: nil)
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
    }

    func setPreview(title: String, date: Date, location: String, sessionType: String, details: [String: String], images: [UIImage], origin: String? = nil) {
        self.title = title
        self.date = date
        self.location = location
        self.sessionType = sessionType
        self.details = details
        self.images = images
        self.origin = origin
    }

    func saveDraft() {
        let data = PreviewData(title: title, date: date, location: location, sessionType: sessionType, details: details, images: images, origin: origin)
        drafts.append(data)
        // Optionally clear current preview
        clear()
    }

    func clear() {
        title = ""
        date = Date()
        location = ""
        sessionType = ""
        details = [:]
        images = []
        origin = nil
    }
}
