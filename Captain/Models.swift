import Foundation

// Shared small models used across logging views
struct CustomStat: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var value: String
}
