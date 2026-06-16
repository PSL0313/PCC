import Foundation

enum SortOption: String, Codable, CaseIterable {
    case createdAt
    case titleAscending
    case titleDescending
    case category

    var title: String {
        switch self {
        case .createdAt:
            return L10n.text(.sortByCreatedAt)
        case .titleAscending:
            return L10n.text(.sortByTitleAscending)
        case .titleDescending:
            return L10n.text(.sortByTitleDescending)
        case .category:
            return L10n.text(.categorySort)
        }
    }
}

enum CardColumnCount: Int, Codable, CaseIterable {
    case two = 2
    case three = 3
    case four = 4

    var title: String {
        "\(rawValue)"
    }
}

enum AddPhotocardStep: Equatable {
    case selecting
    case processing(progress: Double, message: String)
    case reviewing
}

enum CancellationOption {
    case cancelAll
    case cancelCurrent
}

enum CardDisplayOption: String, CaseIterable, Hashable {
    case title
    case memberName
    case category

    var title: String {
        switch self {
        case .title:
            return L10n.text(.title)
        case .memberName:
            return L10n.text(.memberNameOption)
        case .category:
            return L10n.text(.category)
        }
    }
}
