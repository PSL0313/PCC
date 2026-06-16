import Foundation

final class BinderRepositoryImpl: BinderRepositoryProtocol {
    private let dataSource: LocalBinderDataSourceProtocol

    init(dataSource: LocalBinderDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchBinders() throws -> [Binder] {
        try dataSource.loadBinders()
            .sorted {
                if $0.sortIndex == $1.sortIndex {
                    return $0.createdAt < $1.createdAt
                }
                return $0.sortIndex < $1.sortIndex
            }
    }

    func fetchBinder(id: String) throws -> Binder? {
        try dataSource.loadBinders().first { $0.id == id }
    }

    func createBinder(
        name: String,
        profileImageID: String?,
        backgroundHex: String,
        categories: [String],
        members: [String]
    ) throws -> Binder {
        var binders = try dataSource.loadBinders()
        let binder = Binder(
            name: name,
            profileImageID: profileImageID,
            backgroundHex: backgroundHex,
            categories: categories,
            members: members,
            sortIndex: binders.count
        )
        binders.append(binder)
        try dataSource.saveBinders(binders)
        return binder
    }

    func updateBinder(_ binder: Binder) throws {
        var binders = try dataSource.loadBinders()
        guard let index = binders.firstIndex(where: { $0.id == binder.id }) else {
            return
        }

        var updatedBinder = binder
        updatedBinder.updatedAt = Date()
        binders[index] = updatedBinder
        try dataSource.saveBinders(binders)
    }

    func deleteBinder(id: String) throws {
        var binders = try dataSource.loadBinders()
        binders.removeAll { $0.id == id }
        try dataSource.saveBinders(binders)
    }

    func addPhotocards(_ photocards: [Photocard], to binderID: String) throws {
        var binders = try dataSource.loadBinders()
        guard let index = binders.firstIndex(where: { $0.id == binderID }) else {
            return
        }

        var binder = binders[index]
        let currentCount = binder.photocards.count
        let indexedCards = photocards.enumerated().map { offset, card -> Photocard in
            var newCard = card
            newCard.sortIndex = currentCount + offset
            return newCard
        }

        binder.photocards.append(contentsOf: indexedCards)
        binder.updatedAt = Date()
        binders[index] = binder
        try dataSource.saveBinders(binders)
    }

    func updatePhotocard(_ photocard: Photocard, in binderID: String) throws {
        var binders = try dataSource.loadBinders()
        guard let binderIndex = binders.firstIndex(where: { $0.id == binderID }),
              let photocardIndex = binders[binderIndex].photocards.firstIndex(where: { $0.id == photocard.id }) else {
            return
        }

        var updatedPhotocard = photocard
        updatedPhotocard.updatedAt = Date()
        binders[binderIndex].photocards[photocardIndex] = updatedPhotocard
        binders[binderIndex].updatedAt = Date()
        try dataSource.saveBinders(binders)
    }

    func removePhotocard(id: String, from binderID: String) throws {
        try removePhotocards(ids: [id], from: binderID)
    }

    func removePhotocards(ids: Set<String>, from binderID: String) throws {
        var binders = try dataSource.loadBinders()
        guard let index = binders.firstIndex(where: { $0.id == binderID }) else {
            return
        }

        binders[index].photocards.removeAll { ids.contains($0.id) }
        binders[index].updatedAt = Date()
        try dataSource.saveBinders(binders)
    }
}
