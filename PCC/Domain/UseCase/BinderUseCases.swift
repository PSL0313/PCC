import Foundation

final class FetchBindersUseCase {
    private let repository: BinderRepositoryProtocol

    init(repository: BinderRepositoryProtocol) {
        self.repository = repository
    }

    func execute() throws -> [Binder] {
        try repository.fetchBinders()
    }
}

final class FetchBinderUseCase {
    private let repository: BinderRepositoryProtocol

    init(repository: BinderRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: String) throws -> Binder? {
        try repository.fetchBinder(id: id)
    }
}

final class CreateBinderUseCase {
    private let repository: BinderRepositoryProtocol

    init(repository: BinderRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        name: String,
        profileImageID: String?,
        backgroundHex: String,
        categories: [String],
        members: [String]
    ) throws -> Binder {
        try repository.createBinder(
            name: name,
            profileImageID: profileImageID,
            backgroundHex: backgroundHex,
            categories: categories,
            members: members
        )
    }
}

final class UpdateBinderUseCase {
    private let repository: BinderRepositoryProtocol

    init(repository: BinderRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ binder: Binder) throws {
        try repository.updateBinder(binder)
    }
}

final class DeleteBindersUseCase {
    private let repository: BinderRepositoryProtocol
    private let imageStorage: ImageStorageProtocol

    init(
        repository: BinderRepositoryProtocol,
        imageStorage: ImageStorageProtocol
    ) {
        self.repository = repository
        self.imageStorage = imageStorage
    }

    func execute(binderIDs: Set<String>) throws {
        guard !binderIDs.isEmpty else { return }

        let binders = try repository.fetchBinders()
            .filter { binderIDs.contains($0.id) }
        let imageIDs = binders.flatMap { binder -> [String] in
            var ids = binder.photocards.map(\.imageID)
            if let profileImageID = binder.profileImageID {
                ids.append(profileImageID)
            }
            return ids
        }

        for binderID in binderIDs {
            try repository.deleteBinder(id: binderID)
        }
        imageIDs.forEach { try? imageStorage.deleteImageData(id: $0) }
    }
}
