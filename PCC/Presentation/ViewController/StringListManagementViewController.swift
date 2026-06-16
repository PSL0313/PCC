import UIKit

final class StringListManagementViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [String]
    private let addTitle: String
    private let placeholder: String
    private let onAdd: (String) -> Void
    private var textObserver: NSObjectProtocol?

    init(
        title: String,
        items: [String],
        addTitle: String,
        placeholder: String,
        onAdd: @escaping (String) -> Void
    ) {
        self.items = items
        self.addTitle = addTitle
        self.placeholder = placeholder
        self.onAdd = onAdd
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let textObserver {
            NotificationCenter.default.removeObserver(textObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
        toolbarItems = [
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(addButtonTapped)
            )
        ]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func addButtonTapped() {
        // 새 카테고리나 멤버 이름을 입력받는 알림.
        let alertController = UIAlertController(
            title: addTitle,
            message: nil,
            preferredStyle: .alert
        )

        let addAction = UIAlertAction(title: L10n.text(.add), style: .default) { [weak self] _ in
            guard let self,
                  let text = alertController.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else {
                return
            }

            if !self.items.contains(where: { $0.caseInsensitiveCompare(text) == .orderedSame }) {
                self.items.append(text)
                self.onAdd(text)
                self.tableView.insertRows(
                    at: [IndexPath(row: self.items.count - 1, section: 0)],
                    with: .automatic
                )
            }

            self.removeTextObserver()
        }
        addAction.isEnabled = false

        alertController.addTextField { [weak self] textField in
            textField.placeholder = self?.placeholder
            self?.textObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { _ in
                let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                addAction.isEnabled = !text.isEmpty
            }
        }

        alertController.addAction(UIAlertAction(title: L10n.text(.cancel), style: .cancel) { [weak self] _ in
            self?.removeTextObserver()
        })
        alertController.addAction(addAction)

        present(alertController, animated: true)
    }

    private func removeTextObserver() {
        if let textObserver {
            NotificationCenter.default.removeObserver(textObserver)
            self.textObserver = nil
        }
    }
}

extension StringListManagementViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        items.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}
