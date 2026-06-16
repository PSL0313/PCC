import Foundation

struct Binder: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var profileImageID: String?
    var backgroundHex: String
    var categories: [String]
    var members: [String]
    var photocards: [Photocard]
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Int

    var appearance: BinderAppearance {
        BinderAppearance(
            binderID: id,
            name: name,
            profileImageID: profileImageID,
            backgroundHex: backgroundHex
        )
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        profileImageID: String? = nil,
        backgroundHex: String = "#F2F4F8",
        categories: [String] = [],
        members: [String] = [],
        photocards: [Photocard] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.profileImageID = profileImageID
        self.backgroundHex = backgroundHex
        self.categories = categories
        self.members = members
        self.photocards = photocards
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortIndex = sortIndex
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case profileImageID
        case backgroundHex
        case categories
        case members
        case photocards
        case createdAt
        case updatedAt
        case sortIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        profileImageID = try container.decodeIfPresent(String.self, forKey: .profileImageID)
        backgroundHex = try container.decode(String.self, forKey: .backgroundHex)
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
        members = try container.decodeIfPresent([String].self, forKey: .members) ?? []
        photocards = try container.decode([Photocard].self, forKey: .photocards)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        sortIndex = try container.decode(Int.self, forKey: .sortIndex)
    }
}

struct BinderAppearance: Codable, Equatable {
    let binderID: String
    var name: String
    var profileImageID: String?
    var backgroundHex: String
}
