import Foundation
import UIKit

enum BinderSettingMode {
    case create
    case edit(binderID: String)
}

final class BinderSettingViewModel {
    struct State {
        let title: String
        let name: String
        let profileImageID: String?
        let backgroundHex: String
        let categories: [String]
        let members: [String]
        let canSave: Bool
        let canDelete: Bool
    }

    var onStateChange: ((State) -> Void)?
    var onFinish: ((Binder) -> Void)?
    var onDeleted: (() -> Void)?
    var onError: ((String) -> Void)?

    private let mode: BinderSettingMode
    private let fetchBinderUseCase: FetchBinderUseCase
    private let createBinderUseCase: CreateBinderUseCase
    private let updateBinderUseCase: UpdateBinderUseCase
    private let deleteBindersUseCase: DeleteBindersUseCase
    private let imageStorage: ImageStorageProtocol

    private var binder: Binder?
    private var name = ""
    private var profileImageID: String?
    private var backgroundHex = "#F2F4F8"
    private var categories: [String] = []
    private var members: [String] = []

    init(
        mode: BinderSettingMode,
        fetchBinderUseCase: FetchBinderUseCase,
        createBinderUseCase: CreateBinderUseCase,
        updateBinderUseCase: UpdateBinderUseCase,
        deleteBindersUseCase: DeleteBindersUseCase,
        imageStorage: ImageStorageProtocol
    ) {
        self.mode = mode
        self.fetchBinderUseCase = fetchBinderUseCase
        self.createBinderUseCase = createBinderUseCase
        self.updateBinderUseCase = updateBinderUseCase
        self.deleteBindersUseCase = deleteBindersUseCase
        self.imageStorage = imageStorage
    }

    func load() {
        switch mode {
        case .create:
            name = ""
            profileImageID = nil
            backgroundHex = "#F2F4F8"
            categories = []
            members = []
            emitState()
        case .edit(let binderID):
            do {
                binder = try fetchBinderUseCase.execute(id: binderID)
                name = binder?.name ?? ""
                profileImageID = binder?.profileImageID
                backgroundHex = binder?.backgroundHex ?? "#F2F4F8"
                categories = binder?.categories ?? []
                members = binder?.members ?? []
                emitState()
            } catch {
                onError?(L10n.text(.binderSettingLoadFailed))
            }
        }
    }

    func updateName(_ name: String) {
        self.name = name
        emitState()
    }

    func updateBackgroundHex(_ hex: String) {
        backgroundHex = hex
        emitState()
    }

    func updateProfileImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            onError?(L10n.text(.saveProfileImageUnavailable))
            return
        }

        do {
            profileImageID = try imageStorage.saveImageData(data, preferredExtension: "jpg")
            emitState()
        } catch {
            onError?(L10n.text(.saveProfileImageFailed))
        }
    }

    func addCategory(_ category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty,
              !categories.contains(where: { $0.caseInsensitiveCompare(trimmedCategory) == .orderedSame }) else {
            return
        }

        categories.append(trimmedCategory)
        emitState()
    }

    func addMember(_ member: String) {
        let trimmedMember = member.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMember.isEmpty,
              !members.contains(where: { $0.caseInsensitiveCompare(trimmedMember) == .orderedSame }) else {
            return
        }

        members.append(trimmedMember)
        emitState()
    }

    func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            onError?(L10n.text(.binderNameRequired))
            return
        }

        do {
            switch mode {
            case .create:
                let createdBinder = try createBinderUseCase.execute(
                    name: trimmedName,
                    profileImageID: profileImageID,
                    backgroundHex: backgroundHex,
                    categories: categories,
                    members: members
                )
                onFinish?(createdBinder)
            case .edit:
                guard var binder else { return }
                binder.name = trimmedName
                binder.profileImageID = profileImageID
                binder.backgroundHex = backgroundHex
                binder.categories = categories
                binder.members = members
                try updateBinderUseCase.execute(binder)
                onFinish?(binder)
            }
        } catch {
            onError?(L10n.text(.binderSaveFailed))
        }
    }

    func deleteBinder() {
        guard case .edit(let binderID) = mode else { return }

        do {
            try deleteBindersUseCase.execute(binderIDs: [binderID])
            onDeleted?()
        } catch {
            onError?(L10n.text(.binderDeleteFailed))
        }
    }

    private func emitState() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let title: String
        let canDelete: Bool

        switch mode {
        case .create:
            title = L10n.text(.newBinder)
            canDelete = false
        case .edit:
            title = L10n.text(.binderSetting)
            canDelete = true
        }

        onStateChange?(
            State(
                title: title,
                name: name,
                profileImageID: profileImageID,
                backgroundHex: backgroundHex,
                categories: categories,
                members: members,
                canSave: !trimmedName.isEmpty,
                canDelete: canDelete
            )
        )
    }
}
