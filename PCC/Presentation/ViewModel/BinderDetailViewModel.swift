import Foundation

final class BinderDetailViewModel {
    private enum Preferences {
        static let columnCountKey = "binderDetail.columnCount"
        static let sortOptionKey = "binderDetail.sortOption"
        static let displayOptionsKey = "binderDetail.displayOptions"
    }

    enum Route {
        case binderSetting(binderID: String)
        case addPhotocard(binderID: String)
        case photocardPreview(binderID: String, cards: [Photocard], selectedIndex: Int)
    }

    enum Input {
        case viewWillAppear
        case settingTapped
        case addPhotocardTapped
        case searchTextChanged(String)
        case sortOptionChanged(SortOption)
        case columnCountChanged(CardColumnCount)
        case displayOptionToggled(CardDisplayOption)
        case cardSelected(index: Int)
        case deleteSelectionModeTapped
        case cancelDeleteSelectionTapped
        case deleteSelectedPhotocardsConfirmed
    }

    struct State {
        let binder: Binder?
        let cards: [Photocard]
        let sortOption: SortOption
        let columnCount: CardColumnCount
        let displayOptions: Set<CardDisplayOption>
        let searchText: String
        let isDeleteSelectionMode: Bool
        let selectedPhotocardIDs: Set<String>
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((Route) -> Void)?
    var onError: ((String) -> Void)?

    private let binderID: String
    private let fetchBinderUseCase: FetchBinderUseCase
    private let deletePhotocardsUseCase: DeletePhotocardsUseCase

    private(set) var binder: Binder?
    private var searchText = ""
    private var sortOption: SortOption
    private var columnCount: CardColumnCount
    private var displayOptions: Set<CardDisplayOption>
    private var isDeleteSelectionMode = false
    private var selectedPhotocardIDs = Set<String>()

    var currentSortOption: SortOption {
        sortOption
    }

    init(
        binderID: String,
        fetchBinderUseCase: FetchBinderUseCase,
        deletePhotocardsUseCase: DeletePhotocardsUseCase
    ) {
        self.binderID = binderID
        self.fetchBinderUseCase = fetchBinderUseCase
        self.deletePhotocardsUseCase = deletePhotocardsUseCase
        self.sortOption = Self.loadSortOption()
        self.columnCount = Self.loadColumnCount()
        self.displayOptions = Self.loadDisplayOptions()
    }

    func action(_ input: Input) {
        switch input {
        case .viewWillAppear:
            loadBinder()
        case .settingTapped:
            onRoute?(.binderSetting(binderID: binderID))
        case .addPhotocardTapped:
            onRoute?(.addPhotocard(binderID: binderID))
        case .searchTextChanged(let text):
            searchText = text
            emitState()
        case .sortOptionChanged(let option):
            sortOption = option
            UserDefaults.standard.set(option.rawValue, forKey: Preferences.sortOptionKey)
            emitState()
        case .columnCountChanged(let count):
            columnCount = count
            UserDefaults.standard.set(count.rawValue, forKey: Preferences.columnCountKey)
            emitState()
        case .displayOptionToggled(let option):
            if displayOptions.contains(option) {
                displayOptions.remove(option)
            } else {
                displayOptions.insert(option)
            }
            UserDefaults.standard.set(
                displayOptions.map(\.rawValue),
                forKey: Preferences.displayOptionsKey
            )
            emitState()
        case .cardSelected(let index):
            let cards = sortedCards(filteredCards())
            guard cards.indices.contains(index) else { return }
            if isDeleteSelectionMode {
                toggleSelection(photocardID: cards[index].id)
            } else {
                onRoute?(.photocardPreview(binderID: binderID, cards: cards, selectedIndex: index))
            }
        case .deleteSelectionModeTapped:
            isDeleteSelectionMode = true
            selectedPhotocardIDs.removeAll()
            emitState()
        case .cancelDeleteSelectionTapped:
            isDeleteSelectionMode = false
            selectedPhotocardIDs.removeAll()
            emitState()
        case .deleteSelectedPhotocardsConfirmed:
            deleteSelectedPhotocards()
        }
    }

    private func loadBinder() {
        do {
            binder = try fetchBinderUseCase.execute(id: binderID)
            emitState()
        } catch {
            onError?(L10n.text(.binderInfoLoadFailed))
        }
    }

    private func emitState() {
        onStateChange?(
            State(
                binder: binder,
                cards: sortedCards(filteredCards()),
                sortOption: sortOption,
                columnCount: columnCount,
                displayOptions: displayOptions,
                searchText: searchText,
                isDeleteSelectionMode: isDeleteSelectionMode,
                selectedPhotocardIDs: selectedPhotocardIDs
            )
        )
    }

    private func toggleSelection(photocardID: String) {
        if selectedPhotocardIDs.contains(photocardID) {
            selectedPhotocardIDs.remove(photocardID)
        } else {
            selectedPhotocardIDs.insert(photocardID)
        }
        emitState()
    }

    private func deleteSelectedPhotocards() {
        guard !selectedPhotocardIDs.isEmpty else { return }

        do {
            try deletePhotocardsUseCase.execute(
                photocardIDs: selectedPhotocardIDs,
                from: binderID
            )
            isDeleteSelectionMode = false
            selectedPhotocardIDs.removeAll()
            binder = try fetchBinderUseCase.execute(id: binderID)
            emitState()
        } catch {
            onError?(L10n.text(.selectedPhotocardDeleteFailed))
        }
    }

    private func filteredCards() -> [Photocard] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return binder?.photocards ?? []
        }

        let query = searchText.lowercased()
        return (binder?.photocards ?? []).filter {
            $0.title.lowercased().contains(query)
                || $0.memberName.lowercased().contains(query)
                || $0.category.lowercased().contains(query)
        }
    }

    private func sortedCards(_ cards: [Photocard]) -> [Photocard] {
        switch sortOption {
        case .createdAt:
            return cards.sorted { $0.createdAt > $1.createdAt }
        case .titleAscending:
            return cards.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDescending:
            return cards.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .category:
            return cards.sorted { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
        }
    }

    private static func loadColumnCount() -> CardColumnCount {
        let rawValue = UserDefaults.standard.integer(forKey: Preferences.columnCountKey)
        return CardColumnCount(rawValue: rawValue) ?? .three
    }

    private static func loadSortOption() -> SortOption {
        guard let rawValue = UserDefaults.standard.string(forKey: Preferences.sortOptionKey) else {
            return .createdAt
        }
        return SortOption(rawValue: rawValue) ?? .createdAt
    }

    private static func loadDisplayOptions() -> Set<CardDisplayOption> {
        let rawValues = UserDefaults.standard.stringArray(forKey: Preferences.displayOptionsKey) ?? []
        return Set(rawValues.compactMap(CardDisplayOption.init(rawValue:)))
    }
}
