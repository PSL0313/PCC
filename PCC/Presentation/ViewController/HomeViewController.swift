import UIKit
import SnapKit

final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let imageLoader: ImageLoader
    var onRoute: ((HomeViewModel.Route) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    private var binders: [Binder] = []
    private var isDeleteSelectionMode = false
    private var selectedBinderIDs = Set<String>()
   
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
        viewModel: HomeViewModel,
        imageLoader: ImageLoader
    ) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupToolbarItems()
        bindViewModel()
        setupKeyboardObservers()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .appLanguageDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLocalizedTexts()
        viewModel.action(.viewWillAppear)
    }

    private func configureUI() {
        title = "Home"
        view.backgroundColor = .systemBackground
        configureNavigationItems()

        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset.bottom = 60
        tableView.verticalScrollIndicatorInsets.bottom = 60
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            BinderTableViewCell.self,
            forCellReuseIdentifier: BinderTableViewCell.reuseIdentifier
        )

        emptyLabel.text = L10n.text(.emptyBinder)
        emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tableView.snp.makeConstraints {
            $0.top.bottom.leading.trailing.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.binders = state.binders
            self.isDeleteSelectionMode = state.isDeleteSelectionMode
            self.selectedBinderIDs = state.selectedBinderIDs
            self.emptyLabel.isHidden = !state.isEmpty
            self.configureNavigationItems()
            self.tableView.reloadData()
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }

        viewModel.onRoute = { [weak self] route in
            self?.onRoute?(route)
        }
    }

    // Toolbar Item 설정
    func setupToolbarItems() {
        searchBar.placeholder = L10n.text(.searchBinder)
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
            deleteButton.tintColor = selectedBinderIDs.isEmpty ? .gray : .systemRed

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

    private func makeMenu() -> UIMenu {
        let deleteSelectionAction = UIAction(
            title: L10n.text(.deleteSelection),
            image: UIImage(systemName: "trash")
        ) { [weak self] _ in
            self?.viewModel.action(.deleteSelectionModeTapped)
        }

        return UIMenu(
            title: "",
            children: [
                UIMenu(options: .displayInline, children: [deleteSelectionAction])
            ]
        )
    }

    @objc private func settingButtonTapped() {
        viewModel.action(.settingTapped)
    }

    @objc private func addButtonTapped() {
        viewModel.action(.addBinderTapped)
    }

    @objc private func languageDidChange() {
        updateLocalizedTexts()
    }

    private func updateLocalizedTexts() {
        emptyLabel.text = L10n.text(.emptyBinder)
        searchBar.placeholder = L10n.text(.searchBinder)
        configureNavigationItems()
    }

    @objc private func cancelDeleteSelectionButtonTapped() {
        viewModel.action(.cancelDeleteSelectionTapped)
    }

    @objc private func deleteSelectedButtonTapped() {
        guard !selectedBinderIDs.isEmpty else { return }
        let count = selectedBinderIDs.count
        // 선택한 바인더를 삭제하기 전 확인하는 알림.
        let alertController = UIAlertController(
            title: L10n.format(.selectedBinderDeleteTitle, count),
            message: L10n.text(.selectedBinderDeleteMessage),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: L10n.text(.cancel), style: .cancel))
        alertController.addAction(
            UIAlertAction(title: L10n.text(.delete), style: .destructive) { [weak self] _ in
                self?.viewModel.action(.deleteSelectedBindersConfirmed)
            }
        )
        present(alertController, animated: true)
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.action(.searchTextChanged(searchText))
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        binders.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BinderTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? BinderTableViewCell else {
            return UITableViewCell()
        }

        let binder = binders[indexPath.row]
        cell.configure(binder: binder, imageLoader: imageLoader)
        cell.setSelectionMode(
            isEnabled: isDeleteSelectionMode,
            isSelected: selectedBinderIDs.contains(binder.id)
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.action(.binderSelected(index: indexPath.row))
    }
}

extension HomeViewController {
    
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
