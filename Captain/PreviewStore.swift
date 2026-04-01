import SwiftUI
import Combine
import UIKit

// A lightweight store to hold a session preview before posting
final class PreviewStore: ObservableObject {
    @Published var title: String = ""
    @Published var date: Date = Date()
    @Published var location: String = ""
    @Published var sessionType: String = ""
    @Published var details: [String: String] = [:] // arbitrary key-value pairs (goals, stats, etc)
    @Published var images: [UIImage] = []

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
    }

    func setPreview(title: String, date: Date, location: String, sessionType: String, details: [String: String], images: [UIImage]) {
        self.title = title
        self.date = date
        self.location = location
        self.sessionType = sessionType
        self.details = details
        self.images = images
    }

    func clear() {
        title = ""
        date = Date()
        location = ""
        sessionType = ""
        details = [:]
        images = []
    }
}
