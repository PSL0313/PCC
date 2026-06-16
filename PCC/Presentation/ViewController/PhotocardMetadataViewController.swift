import UIKit

final class PhotocardMetadataViewController: UIViewController {
    private enum Section: Int, CaseIterable {
        case title
        case category
        case member
        case delete
    }

    private let viewModel: PhotocardMetadataViewModel
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var state: PhotocardMetadataViewModel.State?
    var onFinish: (() -> Void)?
    var onDeleted: (() -> Void)?

    init(viewModel: PhotocardMetadataViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
        viewModel.load()
    }

    private func configureUI() {
        title = L10n.text(.cardInfo)
        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(
            TextFieldTableViewCell.self,
            forCellReuseIdentifier: TextFieldTableViewCell.reuseIdentifier
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: L10n.text(.save),
            style: .prominent,
            target: self,
            action: #selector(saveButtonTapped)
        )

        enableKeyboardDismissOnTap()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            let previousState = self.state
            self.state = state
            self.navigationItem.rightBarButtonItem?.isEnabled = state.canSave

            guard let previousState else {
                self.tableView.reloadData()
                return
            }

            var sectionsToReload = IndexSet()
            if previousState.categories != state.categories
                || previousState.selectedCategory != state.selectedCategory {
                sectionsToReload.insert(Section.category.rawValue)
            }
            if previousState.members != state.members
                || previousState.selectedMember != state.selectedMember {
                sectionsToReload.insert(Section.member.rawValue)
            }

            if !sectionsToReload.isEmpty {
                self.tableView.reloadSections(sectionsToReload, with: .automatic)
            }
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }

        viewModel.onFinish = { [weak self] in
            self?.onFinish?()
        }

        viewModel.onDeleted = { [weak self] in
            self?.onDeleted?()
        }
    }

    private func makeSelectionCell(
        title: String,
        isSelected: Bool
    ) -> UITableViewCell {
        // 카테고리/멤버 선택 상태를 체크마크로 보여주는 셀.
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = title
        cell.accessoryType = isSelected ? .checkmark : .none
        return cell
    }

    private func makeDeleteCell() -> UITableViewCell {
        // 포토카드 삭제 진입 행으로 사용하는 셀.
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = L10n.text(.photocardDeleteAction)
        cell.textLabel?.textColor = .systemRed
        return cell
    }

    private func showDeleteConfirmation() {
        // 포토카드 삭제 전 사용자 확인을 받는 알림.
        let alertController = UIAlertController(
            title: L10n.text(.photocardDeleteTitle),
            message: L10n.text(.photocardDeleteMessage),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: L10n.text(.cancel), style: .cancel))
        alertController.addAction(
            UIAlertAction(title: L10n.text(.delete), style: .destructive) { [weak self] _ in
                self?.viewModel.deletePhotocard()
            }
        )
        present(alertController, animated: true)
    }

    @objc private func saveButtonTapped() {
        viewModel.save()
    }
}

extension PhotocardMetadataViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        guard let section = Section(rawValue: section),
              let state else {
            return 0
        }

        switch section {
        case .title:
            return 1
        case .category:
            return 1 + state.categories.count
        case .member:
            return 1 + state.members.count
        case .delete:
            return 1
        }
    }

    func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        guard let section = Section(rawValue: section) else {
            return nil
        }

        switch section {
        case .title:
            return L10n.text(.title)
        case .category:
            return L10n.text(.category)
        case .member:
            return L10n.text(.member)
        case .delete:
            return nil
        }
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section),
              let state else {
            return UITableViewCell()
        }

        switch section {
        case .title:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TextFieldTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TextFieldTableViewCell else {
                return UITableViewCell()
            }

            // 카드 제목을 직접 입력하는 텍스트필드 셀.
            cell.textField.placeholder = L10n.text(.cardTitle)
            cell.textField.text = state.title
            cell.onTextChanged = { [weak self] text in
                self?.viewModel.updateTitle(text)
            }
            return cell

        case .category:
            let category = indexPath.row == 0
                ? L10n.uncategorizedStorageValue
                : state.categories[indexPath.row - 1]
            return makeSelectionCell(
                title: L10n.displayCategory(category),
                isSelected: state.selectedCategory == category
            )

        case .member:
            let member = indexPath.row == 0
                ? ""
                : state.members[indexPath.row - 1]
            return makeSelectionCell(
                title: L10n.displayMember(member),
                isSelected: indexPath.row == 0
                    ? state.selectedMember.isEmpty
                    : state.selectedMember == member
            )
        case .delete:
            return makeDeleteCell()
        }
    }

}

extension PhotocardMetadataViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = Section(rawValue: indexPath.section),
              let state else {
            return
        }

        switch section {
        case .title:
            break
        case .category:
            let category = indexPath.row == 0
                ? L10n.uncategorizedStorageValue
                : state.categories[indexPath.row - 1]
            viewModel.selectCategory(category)
        case .member:
            let member = indexPath.row == 0
                ? ""
                : state.members[indexPath.row - 1]
            viewModel.selectMember(member)
        case .delete:
            showDeleteConfirmation()
        }
    }
}
