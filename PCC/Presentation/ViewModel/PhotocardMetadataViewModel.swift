import Foundation

final class PhotocardMetadataViewModel {
    struct State {
        let title: String
        let categories: [String]
        let members: [String]
        let selectedCategory: String
        let selectedMember: String
        let canSave: Bool
    }

    var onStateChange: ((State) -> Void)?
    var onFinish: (() -> Void)?
    var onDeleted: (() -> Void)?
    var onError: ((String) -> Void)?

    private let binderID: String
    private let photocardID: String
    private let fetchBinderUseCase: FetchBinderUseCase
    private let updatePhotocardUseCase: UpdatePhotocardUseCase
    private let deletePhotocardUseCase: DeletePhotocardUseCase

    private var photocard: Photocard?
    private var categories: [String] = []
    private var members: [String] = []
    private var title = ""
    private var selectedCategory = L10n.uncategorizedStorageValue
    private var selectedMember = ""

    init(
        binderID: String,
        photocardID: String,
        fetchBinderUseCase: FetchBinderUseCase,
        updatePhotocardUseCase: UpdatePhotocardUseCase,
        deletePhotocardUseCase: DeletePhotocardUseCase
    ) {
        self.binderID = binderID
        self.photocardID = photocardID
        self.fetchBinderUseCase = fetchBinderUseCase
        self.updatePhotocardUseCase = updatePhotocardUseCase
        self.deletePhotocardUseCase = deletePhotocardUseCase
    }

    func load() {
        do {
            guard let binder = try fetchBinderUseCase.execute(id: binderID),
                  let photocard = binder.photocards.first(where: { $0.id == photocardID }) else {
                onError?(L10n.text(.photocardNotFound))
                return
            }

            self.photocard = photocard
            categories = binder.categories
            members = binder.members
            title = photocard.title
            selectedCategory = photocard.category
            selectedMember = photocard.memberName
            emitState()
        } catch {
            onError?(L10n.text(.photocardInfoLoadFailed))
        }
    }

    func updateTitle(_ title: String) {
        self.title = title
        emitState()
    }

    func selectCategory(_ category: String) {
        selectedCategory = category
        emitState()
    }

    func selectMember(_ member: String) {
        selectedMember = member
        emitState()
    }

    func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            onError?(L10n.text(.titleRequired))
            return
        }

        guard var photocard else {
            return
        }

        do {
            photocard.title = trimmedTitle
            photocard.category = selectedCategory
            photocard.memberName = selectedMember
            try updatePhotocardUseCase.execute(photocard, in: binderID)
            onFinish?()
        } catch {
            onError?(L10n.text(.photocardSaveFailed))
        }
    }

    func deletePhotocard() {
        do {
            try deletePhotocardUseCase.execute(photocardID: photocardID, from: binderID)
            onDeleted?()
        } catch {
            onError?(L10n.text(.photocardDeleteFailed))
        }
    }

    private func emitState() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        onStateChange?(
            State(
                title: title,
                categories: categories,
                members: members,
                selectedCategory: selectedCategory,
                selectedMember: selectedMember,
                canSave: !trimmedTitle.isEmpty
            )
        )
    }
}
