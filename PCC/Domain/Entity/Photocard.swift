import Foundation

struct Photocard: Codable, Equatable, Identifiable {
    let id: String
    var title: String
    var memberName: String
    var category: String
    var imageID: String
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Int
    var classification: PhotocardClassification?

    init(
        id: String = UUID().uuidString,
        title: String,
        memberName: String = "",
        category: String = L10n.text(.uncategorized),
        imageID: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortIndex: Int,
        classification: PhotocardClassification? = nil
    ) {
        self.id = id
        self.title = title
        self.memberName = memberName
        self.category = category
        self.imageID = imageID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortIndex = sortIndex
        self.classification = classification
    }
}

struct PhotocardClassification: Codable, Equatable {
    let label: String
    let confidence: Double
    let modelIdentifier: String?
}
