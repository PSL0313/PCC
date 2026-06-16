import Foundation

final class HomeViewModel {
    enum Route {
        case appSetting
        case createBinder
        case binderDetail(binderID: String)
    }

    enum Input {
        case viewWillAppear
        case settingTapped
        case addBinderTapped
        case binderSelected(index: Int)
        case searchTextChanged(String)
        case deleteSelectionModeTapped
        case cancelDeleteSelectionTapped
        case deleteSelectedBindersConfirmed
    }

    struct State {
        let binders: [Binder]
        let isEmpty: Bool
        let isDeleteSelectionMode: Bool
        let selectedBinderIDs: Set<String>
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((Route) -> Void)?
    var onError: ((String) -> Void)?

    private let fetchBindersUseCase: FetchBindersUseCase
    private let deleteBindersUseCase: DeleteBindersUseCase
    private var allBinders: [Binder] = []
    private(set) var binders: [Binder] = []
    private var searchText = ""
    private var isDeleteSelectionMode = false
    private var selectedBinderIDs = Set<String>()

    init(
        fetchBindersUseCase: FetchBindersUseCase,
        deleteBindersUseCase: DeleteBindersUseCase
    ) {
        self.fetchBindersUseCase = fetchBindersUseCase
        self.deleteBindersUseCase = deleteBindersUseCase
    }

    func action(_ input: Input) {
        switch input {
        case .viewWillAppear:
            loadBinders()
        case .settingTapped:
            onRoute?(.appSetting)
        case .addBinderTapped:
            onRoute?(.createBinder)
        case .binderSelected(let index):
            guard binders.indices.contains(index) else { return }
            if isDeleteSelectionMode {
                toggleSelection(binderID: binders[index].id)
            } else {
                onRoute?(.binderDetail(binderID: binders[index].id))
            }
        case .searchTextChanged(let text):
            searchText = text
            applyFilter()
        case .deleteSelectionModeTapped:
            isDeleteSelectionMode = true
            selectedBinderIDs.removeAll()
            emitState()
        case .cancelDeleteSelectionTapped:
            isDeleteSelectionMode = false
            selectedBinderIDs.removeAll()
            emitState()
        case .deleteSelectedBindersConfirmed:
            deleteSelectedBinders()
        }
    }

    private func loadBinders() {
        do {
            allBinders = try fetchBindersUseCase.execute()
            applyFilter()
        } catch {
            onError?(L10n.text(.binderListLoadFailed))
        }
    }

    private func applyFilter() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        binders = query.isEmpty
            ? allBinders
            : allBinders.filter { $0.name.localizedCaseInsensitiveContains(query) }

        selectedBinderIDs = selectedBinderIDs.filter { id in
            binders.contains { $0.id == id }
        }
        emitState()
    }

    private func emitState() {
        onStateChange?(
            State(
                binders: binders,
                isEmpty: binders.isEmpty,
                isDeleteSelectionMode: isDeleteSelectionMode,
                selectedBinderIDs: selectedBinderIDs
            )
        )
    }

    private func toggleSelection(binderID: String) {
        if selectedBinderIDs.contains(binderID) {
            selectedBinderIDs.remove(binderID)
        } else {
            selectedBinderIDs.insert(binderID)
        }
        emitState()
    }

    private func deleteSelectedBinders() {
        guard !selectedBinderIDs.isEmpty else { return }

        do {
            try deleteBindersUseCase.execute(binderIDs: selectedBinderIDs)
            isDeleteSelectionMode = false
            selectedBinderIDs.removeAll()
            loadBinders()
        } catch {
            onError?(L10n.text(.selectedBinderDeleteFailed))
        }
    }
}
