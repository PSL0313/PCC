import UIKit
import PhotosUI
import SnapKit

final class BinderSettingViewController: UIViewController {
    enum Route {
        case categoryList(items: [String], onAdd: (String) -> Void)
        case memberList(items: [String], onAdd: (String) -> Void)
    }

    private let viewModel: BinderSettingViewModel
    private let imageLoader: ImageLoader
    var onRoute: ((Route) -> Void)?
    var onFinish: ((Binder) -> Void)?
    var onDeleted: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let profileButton = UIButton(type: .system)
    private let profileImageView = UIImageView()
    private let nameTextField = UITextField()
    private let colorStackView = UIStackView()
    private let listContainerView = UIView()
    private let categoryRowButton = SettingsDisclosureRow()
    private let memberRowButton = SettingsDisclosureRow()
    private let saveButton = UIButton(type: .system)
    
    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem (
            title: L10n.text(.save),
            style: .plain,
            target: self,
            action: #selector(saveButtonTapped)
        )
        item.tintColor = .label
        return item
    }()
    
    private lazy var deleteBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            title: L10n.text(.delete),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        item.tintColor = .systemRed
        return item
    }()
    private var categories: [String] = []
    private var members: [String] = []

    private let colorOptions = [
        "#F2F4F8",
        "#D8F3DC",
        "#FFE5D9",
        "#DDE7FF",
        "#FFF3B0",
        "#EADCF8"
    ]

    init(
        viewModel: BinderSettingViewModel,
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
        bindViewModel()
        viewModel.load()
    }

    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        enableKeyboardDismissOnTap()
        navigationItem.rightBarButtonItems = [saveBarButtonItem]

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.tintColor = .secondaryLabel
        profileImageView.backgroundColor = .secondarySystemBackground
        profileImageView.layer.cornerRadius = 44
        profileImageView.layer.masksToBounds = true

        profileButton.setTitle(L10n.text(.editProfileImage), for: .normal)
        profileButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        profileButton.addTarget(
            self,
            action: #selector(profileButtonTapped),
            for: .touchUpInside
        )

        nameTextField.placeholder = L10n.text(.binderName)
        nameTextField.borderStyle = .roundedRect
        nameTextField.clearButtonMode = .whileEditing
        nameTextField.addTarget(
            self,
            action: #selector(nameTextFieldChanged),
            for: .editingChanged
        )

        listContainerView.backgroundColor = .secondarySystemGroupedBackground
        listContainerView.layer.cornerRadius = 12
        listContainerView.layer.masksToBounds = true
        categoryRowButton.configure(title: L10n.text(.category), value: "0", showsSeparator: true)
        memberRowButton.configure(title: L10n.text(.member), value: "0", showsSeparator: false)
        categoryRowButton.addTarget(
            self,
            action: #selector(categoryRowTapped),
            for: .touchUpInside
        )
        memberRowButton.addTarget(
            self,
            action: #selector(memberRowTapped),
            for: .touchUpInside
        )

        colorStackView.axis = .horizontal
        colorStackView.spacing = 12
        colorStackView.distribution = .fillEqually

        colorOptions.forEach { hex in
            let button = UIButton(type: .system)
            button.backgroundColor = UIColor(hex: hex)
            button.layer.cornerRadius = 18
            button.layer.borderColor = UIColor.label.cgColor
            button.layer.borderWidth = 1
            button.accessibilityIdentifier = hex
            button.addTarget(
                self,
                action: #selector(colorButtonTapped(_:)),
                for: .touchUpInside
            )
            colorStackView.addArrangedSubview(button)
        }

        saveButton.setTitle(L10n.text(.save), for: .normal)
        saveButton.setTitleColor(.systemBackground, for: .normal)
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        saveButton.backgroundColor = .label
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(
            self,
            action: #selector(saveButtonTapped),
            for: .touchUpInside
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.backgroundColor = .systemGroupedBackground
        contentView.backgroundColor = .systemGroupedBackground
        contentView.addSubview(profileImageView)
        contentView.addSubview(profileButton)
        contentView.addSubview(nameTextField)
        contentView.addSubview(colorStackView)
        contentView.addSubview(listContainerView)
        listContainerView.addSubview(categoryRowButton)
        listContainerView.addSubview(memberRowButton)
        contentView.addSubview(saveButton)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        profileImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(28)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(88)
        }

        profileButton.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }

        nameTextField.snp.makeConstraints {
            $0.top.equalTo(profileButton.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(48)
        }

        colorStackView.snp.makeConstraints {
            $0.top.equalTo(nameTextField.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        listContainerView.snp.makeConstraints {
            $0.top.equalTo(colorStackView.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(96)
        }

        categoryRowButton.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(48)
        }

        memberRowButton.snp.makeConstraints {
            $0.top.equalTo(categoryRowButton.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        saveButton.snp.makeConstraints {
            $0.bottom.equalTo(self.view.snp.bottom).offset(-36)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
            $0.bottom.equalToSuperview().inset(28)
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.title = state.title
            self.nameTextField.text = state.name
            self.profileImageView.image = self.imageLoader.image(for: state.profileImageID)
                ?? UIImage(systemName: "person.crop.circle.fill")
            if state.canDelete {
                self.navigationItem.rightBarButtonItems = [self.deleteBarButtonItem]
            }
//            self.navigationItem.rightBarButtonItems = state.canDelete
//                ? [self.saveBarButtonItem, self.deleteBarButtonItem]
//                : [self.saveBarButtonItem]
            self.saveBarButtonItem.isEnabled = state.canSave
            self.saveButton.isEnabled = state.canSave
            self.saveButton.alpha = state.canSave ? 1 : 0.45
            self.categories = state.categories
            self.members = state.members
            self.categoryRowButton.configure(
                title: L10n.text(.category),
                value: "\(state.categories.count)",
                showsSeparator: true
            )
            self.memberRowButton.configure(
                title: L10n.text(.member),
                value: "\(state.members.count)",
                showsSeparator: false
            )
            self.updateColorSelection(selectedHex: state.backgroundHex)
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }

        viewModel.onFinish = { [weak self] binder in
            self?.onFinish?(binder)
        }

        viewModel.onDeleted = { [weak self] in
            self?.onDeleted?()
        }
    }

    private func updateColorSelection(selectedHex: String) {
        for case let button as UIButton in colorStackView.arrangedSubviews {
            let isSelected = button.accessibilityIdentifier == selectedHex
            button.layer.borderColor = isSelected
                ? UIColor.label.cgColor
                : UIColor.separator.cgColor
            button.layer.borderWidth = isSelected ? 3 : 1
        }
    }

    @objc private func nameTextFieldChanged() {
        viewModel.updateName(nameTextField.text ?? "")
    }

    @objc private func profileButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func colorButtonTapped(_ sender: UIButton) {
        guard let hex = sender.accessibilityIdentifier else {
            return
        }

        viewModel.updateBackgroundHex(hex)
    }

    @objc private func categoryRowTapped() {
        onRoute?(
            .categoryList(items: categories) { [weak self] category in
                self?.viewModel.addCategory(category)
            }
        )
    }

    @objc private func memberRowTapped() {
        onRoute?(
            .memberList(items: members) { [weak self] member in
                self?.viewModel.addMember(member)
            }
        )
    }

    @objc private func saveButtonTapped() {
        viewModel.save()
    }

    @objc private func deleteButtonTapped() {
        // 바인더 삭제 전 사용자 확인을 받는 알림.
        let alertController = UIAlertController(
            title: L10n.text(.binderDeleteTitle),
            message: L10n.text(.binderDeleteMessage),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: L10n.text(.cancel), style: .cancel))
        alertController.addAction(
            UIAlertAction(title: L10n.text(.delete), style: .destructive) { [weak self] _ in
                self?.viewModel.deleteBinder()
            }
        )
        present(alertController, animated: true)
    }
}

extension BinderSettingViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else {
                return
            }

            DispatchQueue.main.async {
                self?.viewModel.updateProfileImage(image)
            }
        }
    }
}
