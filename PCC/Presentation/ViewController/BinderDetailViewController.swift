import UIKit
import SnapKit

final class BinderDetailViewController: UIViewController {
    private let viewModel: BinderDetailViewModel
    private let imageLoader: ImageLoader
    var onRoute: ((BinderDetailViewModel.Route) -> Void)?

    private let collectionView: UICollectionView
    private let emptyLabel = UILabel()

    private var cards: [Photocard] = []
    private var columnCount: CardColumnCount = .three
    private var displayOptions = Set<CardDisplayOption>()
    private var isDeleteSelectionMode = false
    private var selectedPhotocardIDs = Set<String>()
    
    // 서치바
    private let searchBar = UISearchBar()
    
    // Add 버튼
    private lazy var floatingAddButton: UIBarButtonItem = {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        return addButton
    }()
    
    // 하단 툴바
    private let bottomToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        return toolbar
    }()

    // 툴바와 키보드의 간격 조정에 사용할 Constraint
    private var bottomConstraint: Constraint?
    
    init(
        viewModel: BinderDetailViewModel,
        imageLoader: ImageLoader
    ) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 10
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupToolbarItems()
        bindViewModel()
        setupKeyboardObservers()
        ux()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .appLanguageDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLocalizedTexts()
        viewModel.action(.viewWillAppear)
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground
        configureNavigationItems()
        
        collectionView.backgroundColor = .systemBackground

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 96, right: 16)
        registerPhotocardCells()

        emptyLabel.text = L10n.text(.emptyPhotocard)
        emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(collectionView)
        view.addSubview(emptyLabel)

        collectionView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(collectionView)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }
    
    // Toolbar Item 설정
    func setupToolbarItems() {
        searchBar.placeholder = L10n.text(.searchPhotocard)
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        // 하단 툴바에 서치 바, 아이템 추가 버튼 추가
        bottomToolbar.setItems(
            [
                UIBarButtonItem(customView: searchBar),
                UIBarButtonItem.flexibleSpace(),
                floatingAddButton
            ],
            animated: false
        )
        // 하위 뷰로 추가
        view.addSubview(bottomToolbar)
        // 제약 조건 설정
        searchBar.snp.makeConstraints {
            $0.height.equalTo(40)
        }
        bottomToolbar.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(8)
            
            self.bottomConstraint = $0.bottom
                .equalTo(view.keyboardLayoutGuide.snp.top)
                .offset(0)
                .constraint
        }
    }
    
    private func configureNavigationItems() {
        guard !isDeleteSelectionMode else {
            let deleteButton = UIBarButtonItem(
                title: L10n.text(.delete),
                style: .plain,
                target: self,
                action: #selector(deleteSelectedButtonTapped)
            )
            deleteButton.tintColor = selectedPhotocardIDs.isEmpty ? .clear : .systemBlue

            navigationItem.rightBarButtonItems = [
                deleteButton,
                UIBarButtonItem(
                    title: L10n.text(.cancel),
                    style: .plain,
                    target: self,
                    action: #selector(cancelDeleteSelectionButtonTapped)
                )
            ]
            return
        }

        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: nil,
            action: nil
        )
        menuButton.menu = makeMenu()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "gearshape"),
                style: .plain,
                target: self,
                action: #selector(settingButtonTapped)
            ),
            menuButton
        ]
    }
    
    
    private func ux() {
        // 스크롤 활성화 및 드래그를 통한 키보드 내리기
        collectionView.isScrollEnabled = true
        collectionView.keyboardDismissMode = .onDrag
        
        // 콘텐츠가 적은 경우 스크롤 off 이슈에 대한 대응
        /// 빈 화면을 클릭하면 키보드 내림 제스처 등록
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboardWhenScrollingIsUnavailable)
        )
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.title = state.binder?.name ?? L10n.text(.binder)
            self.cards = state.cards
            self.columnCount = state.columnCount
            self.displayOptions = state.displayOptions
            self.isDeleteSelectionMode = state.isDeleteSelectionMode
            self.selectedPhotocardIDs = state.selectedPhotocardIDs
            self.emptyLabel.isHidden = !state.cards.isEmpty
            self.configureNavigationItems()
            self.collectionView.reloadData()
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }

        viewModel.onRoute = { [weak self] route in
            self?.onRoute?(route)
        }
    }

    private func makeMenu() -> UIMenu {
        let columnMenu = UIMenu(
            title: L10n.text(.columnCount),
            options: .displayInline,
            children: CardColumnCount.allCases.map { count in
                UIAction(
                    title: count.title,
                    state: columnCount == count ? .on : .off
                ) { [weak self] _ in
                    self?.viewModel.action(.columnCountChanged(count))
                }
            }
        )

        let sortMenu = UIMenu(
            title: L10n.text(.sortOption),
            options: .displayInline,
            children: SortOption.allCases.map { option in
                UIAction(
                    title: option.title,
                    state: viewModel.currentSortOption == option ? .on : .off
                ) { [weak self] _ in
                    self?.viewModel.action(.sortOptionChanged(option))
                }
            }
        )

        let displayMenu = UIMenu(
            title: L10n.text(.display),
            options: .displayInline,
            children: CardDisplayOption.allCases.map { option in
                let action = UIAction(
                    title: option.title,
                    attributes: .keepsMenuPresented,
                    state: displayOptions.contains(option) ? .on : .off
                ) { [weak self] action in
                    action.state = action.state == .on ? .off : .on
                    self?.viewModel.action(.displayOptionToggled(option))
                }
                return action
            }
        )

        let deleteSelectionAction = UIAction(
            title: L10n.text(.deleteSelection),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.viewModel.action(.deleteSelectionModeTapped)
        }

        return UIMenu(
            title: "",
            children: [
                UIMenu(options: .displayInline, children: [deleteSelectionAction]),
                columnMenu,
                sortMenu,
                displayMenu
            ]
        )
    }

    private func registerPhotocardCells() {
        let cellTypes: [BasePhotocardDisplayCell.Type] = [
            ImageOnlyPhotocardCell.self,
            TitleOnlyPhotocardCell.self,
            MemberOnlyPhotocardCell.self,
            CategoryOnlyPhotocardCell.self,
            TitleMemberPhotocardCell.self,
            TitleCategoryPhotocardCell.self,
            MemberCategoryPhotocardCell.self,
            FullInfoPhotocardCell.self
        ]

        cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.reuseIdentifier)
        }
    }

    @objc private func settingButtonTapped() {
        viewModel.action(.settingTapped)
    }

    @objc private func addButtonTapped() {
        viewModel.action(.addPhotocardTapped)
    }

    @objc private func languageDidChange() {
        updateLocalizedTexts()
    }

    private func updateLocalizedTexts() {
        emptyLabel.text = L10n.text(.emptyPhotocard)
        searchBar.placeholder = L10n.text(.searchPhotocard)
        title = viewModel.binder?.name ?? L10n.text(.binder)
        configureNavigationItems()
        collectionView.reloadData()
    }

    @objc private func cancelDeleteSelectionButtonTapped() {
        viewModel.action(.cancelDeleteSelectionTapped)
    }

    @objc private func deleteSelectedButtonTapped() {
        guard !selectedPhotocardIDs.isEmpty else { return }
        let count = selectedPhotocardIDs.count
        // 선택된 포토카드를 삭제하기 전 확인하는 알림.
        let alertController = UIAlertController(
            title: L10n.format(.selectedPhotocardDeleteTitle, count),
            message: L10n.text(.selectedPhotocardDeleteMessage),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: L10n.text(.cancel), style: .cancel))
        alertController.addAction(
            UIAlertAction(title: L10n.text(.delete), style: .destructive) { [weak self] _ in
                self?.viewModel.action(.deleteSelectedPhotocardsConfirmed)
            }
        )
        present(alertController, animated: true)
    }
    
    // 스크롤이 안되는 상황
    @objc private func dismissKeyboardWhenScrollingIsUnavailable() {
        view.endEditing(true)
    }
}

extension BinderDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        cards.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let effectiveDisplayOptions = isDeleteSelectionMode
            ? Set(CardDisplayOption.allCases)
            : displayOptions
        let cellType = isDeleteSelectionMode
            ? FullInfoPhotocardCell.self
            : PhotocardCellKind(displayOptions: effectiveDisplayOptions).cellType
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellType.reuseIdentifier,
            for: indexPath
        ) as? BasePhotocardDisplayCell else {
            return UICollectionViewCell()
        }

        cell.configure(
            photocard: cards[indexPath.item],
            imageLoader: imageLoader,
            displayOptions: effectiveDisplayOptions
        )
        cell.setSelectionMode(
            isEnabled: isDeleteSelectionMode,
            isSelected: selectedPhotocardIDs.contains(cards[indexPath.item].id)
        )
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let contentWidth = collectionView.bounds.width
            - collectionView.contentInset.left
            - collectionView.contentInset.right
        let spacing = CGFloat(columnCount.rawValue - 1) * 10
        let width = floor((contentWidth - spacing) / CGFloat(columnCount.rawValue))
        let cellType = isDeleteSelectionMode
            ? FullInfoPhotocardCell.self
            : PhotocardCellKind(displayOptions: displayOptions).cellType
        return CGSize(width: width, height: cellType.preferredHeight(for: width))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.action(.cardSelected(index: indexPath.item))
    }
}

extension BinderDetailViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.action(.searchTextChanged(searchText))
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


extension BinderDetailViewController {
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc
    private func keyboardWillShow(_ notification: Notification) {
        bottomConstraint?.update(offset: -10)

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc
    private func keyboardWillHide(_ notification: Notification) {
        bottomConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}
