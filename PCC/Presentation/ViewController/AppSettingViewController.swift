import UIKit

final class AppSettingViewController: UIViewController {
    enum Route {
        case languageSetting
    }

    private enum Row: Int, CaseIterable {
        case language
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    var onRoute: ((Route) -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = L10n.text(.setting)
        tableView.reloadData()
    }

    private func configureUI() {
        title = L10n.text(.setting)
        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension AppSettingViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        Row.allCases.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = L10n.text(.language)
        cell.detailTextLabel?.text = AppLanguage.current.displayName
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension AppSettingViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        onRoute?(.languageSetting)
    }
}

final class LanguageSettingViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        title = L10n.text(.language)
        view.backgroundColor = .systemGroupedBackground
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension LanguageSettingViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        AppLanguage.allCases.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let language = AppLanguage.allCases[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = language.displayName
        cell.accessoryType = language == AppLanguage.current ? .checkmark : .none
        return cell
    }
}

extension LanguageSettingViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        AppLanguage.current = AppLanguage.allCases[indexPath.row]
        title = L10n.text(.language)
        tableView.reloadData()
    }
}
