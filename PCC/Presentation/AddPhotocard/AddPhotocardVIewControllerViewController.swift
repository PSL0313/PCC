import UIKit
import PhotosUI
import SnapKit

final class AddPhotocardViewController: UIViewController {
    private let viewModel: AddPhotocardViewModel
    var onFinish: (() -> Void)?
    var onCancel: (() -> Void)?

    private let collectionView: UICollectionView
    private let headerView = UIView()
    private let stepLabel = UILabel()
    private let countLabel = UILabel()
    private let emptyStateView = UIView()
    private let emptyImageView = UIImageView()
    private let emptyTitleLabel = UILabel()
    private let emptySubtitleLabel = UILabel()
    private let guideTitleLabel = UILabel()
    private let guideBodyLabel = UILabel()
    private let sourceButtonStackView = UIStackView()
    private let cameraButton = UIButton(type: .system)
    private let selectButton = UIButton(type: .system)
    private let moveButton = UIButton(type: .system)
    private let processingView = UIView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()

    private var selectedImages: [UIImage] = []
    private var processedImages: [ProcessedPhotocardImage] = []
    private var step: AddPhotocardStep = .selecting
    private var sourceButtonStackHeightConstraint: Constraint?

    init(viewModel: AddPhotocardViewModel) {
        self.viewModel = viewModel

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appLanguageDidChange),
            name: .appLanguageDidChange,
            object: nil
        )
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
            (viewController: AddPhotocardViewController, _) in
            viewController.updateDynamicColors()
        }
        bindViewModel()
        viewModel.load()
    }

    private func configureUI() {
        title = L10n.text(.addPhoto)
        view.backgroundColor = Colors.Theme.mainBackgroundColor
        configureNavigationItems(visibleImageCount: 0, canFinish: false)

        stepLabel.font = .systemFont(ofSize: 24, weight: .bold)
        stepLabel.textColor = .label

        countLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        countLabel.textColor = .secondaryLabel
        countLabel.textAlignment = .right
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        collectionView.backgroundColor = Colors.Theme.mainBackgroundColor
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            ImagePreviewCollectionViewCell.self,
            forCellWithReuseIdentifier: ImagePreviewCollectionViewCell.reuseIdentifier
        )

        emptyStateView.isUserInteractionEnabled = false

        emptyImageView.image = UIImage(systemName: "rectangle.stack.badge.plus")
        emptyImageView.tintColor = .label
        emptyImageView.contentMode = .scaleAspectFit

        emptyTitleLabel.text = L10n.text(.addPhoto)
        emptyTitleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        emptyTitleLabel.textColor = .label
        emptyTitleLabel.textAlignment = .center

        emptySubtitleLabel.text = L10n.text(.addPhotoSubtitle)
        emptySubtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        emptySubtitleLabel.textColor = .secondaryLabel
        emptySubtitleLabel.textAlignment = .center

        guideTitleLabel.text = L10n.text(.addPhotoGuideTitle)
        guideTitleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        guideTitleLabel.textColor = .label
        guideTitleLabel.textAlignment = .center

        guideBodyLabel.text = L10n.text(.addPhotoGuideBody)
        guideBodyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        guideBodyLabel.textColor = .secondaryLabel
        guideBodyLabel.textAlignment = .center
        guideBodyLabel.numberOfLines = 0

        sourceButtonStackView.axis = .horizontal
        sourceButtonStackView.spacing = 12
        sourceButtonStackView.distribution = .fillEqually

        configureSecondaryButton(
            cameraButton,
            title: L10n.text(.camera),
            imageName: "camera"
        )
        cameraButton.addTarget(
            self,
            action: #selector(cameraButtonTapped),
            for: .touchUpInside
        )

        configureSecondaryButton(
            selectButton,
            title: L10n.text(.album),
            imageName: "photo.on.rectangle"
        )
        selectButton.addTarget(
            self,
            action: #selector(selectButtonTapped),
            for: .touchUpInside
        )

        sourceButtonStackView.addArrangedSubview(cameraButton)
        sourceButtonStackView.addArrangedSubview(selectButton)

        configurePrimaryButton(
            moveButton,
            title: L10n.text(.extractCard),
            imageName: "wand.and.stars"
        )
        moveButton.addTarget(
            self,
            action: #selector(moveButtonTapped),
            for: .touchUpInside
        )

        processingView.backgroundColor = Colors.Theme.mainBackgroundColor
        processingView.isHidden = true

        progressView.progressTintColor = .label
        progressView.trackTintColor = .tertiarySystemFill

        progressLabel.textAlignment = .center
        progressLabel.font = .systemFont(ofSize: 16, weight: .medium)
        progressLabel.textColor = .label

        view.addSubview(headerView)
        headerView.addSubview(stepLabel)
        headerView.addSubview(countLabel)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyTitleLabel)
        emptyStateView.addSubview(emptySubtitleLabel)
        emptyStateView.addSubview(guideTitleLabel)
        emptyStateView.addSubview(guideBodyLabel)
        view.addSubview(sourceButtonStackView)
        view.addSubview(moveButton)
        view.addSubview(processingView)
        processingView.addSubview(progressView)
        processingView.addSubview(progressLabel)

        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        stepLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(countLabel.snp.leading).offset(-12)
        }

        countLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(sourceButtonStackView.snp.top).offset(-16)
        }

        emptyStateView.snp.makeConstraints {
            $0.center.equalTo(collectionView)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        emptyImageView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(52)
        }

        emptyTitleLabel.snp.makeConstraints {
            $0.top.equalTo(emptyImageView.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview()
        }

        emptySubtitleLabel.snp.makeConstraints {
            $0.top.equalTo(emptyTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        guideTitleLabel.snp.makeConstraints {
            $0.top.equalTo(emptySubtitleLabel.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview()
        }

        guideBodyLabel.snp.makeConstraints {
            $0.top.equalTo(guideTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        sourceButtonStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(moveButton.snp.top).offset(-12)
            sourceButtonStackHeightConstraint = $0.height.equalTo(48).constraint
        }

        moveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(18)
            $0.height.equalTo(54)
        }

        processingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        progressView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(44)
            $0.centerY.equalToSuperview()
        }

        progressLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(progressView.snp.top).offset(-18)
        }

        updateDynamicColors()
        updateProcessingUI(step: step)
    }

    private func updateLocalizedTexts() {
        title = L10n.text(.addPhoto)
        emptyTitleLabel.text = L10n.text(.addPhoto)
        emptySubtitleLabel.text = L10n.text(.addPhotoSubtitle)
        guideTitleLabel.text = L10n.text(.addPhotoGuideTitle)
        guideBodyLabel.text = L10n.text(.addPhotoGuideBody)

        configureSecondaryButton(
            cameraButton,
            title: L10n.text(.camera),
            imageName: "camera"
        )
        configureSecondaryButton(
            selectButton,
            title: L10n.text(.album),
            imageName: "photo.on.rectangle"
        )
        configureNavigationItems(
            visibleImageCount: visibleImages().count,
            canFinish: !processedImages.isEmpty
        )
        updateProcessingUI(step: step)
    }

    private func configureNavigationItems(
        visibleImageCount: Int,
        canFinish: Bool
    ) {
        guard visibleImageCount > 1 else {
            let cancelButton = UIBarButtonItem(
                title: L10n.text(.cancel),
                style: .plain,
                target: self,
                action: #selector(cancelButtonTapped)
            )
            cancelButton.tintColor = .label
            navigationItem.leftBarButtonItem = cancelButton
            navigationItem.rightBarButtonItem = nil
            return
        }

        let allCancelAction = UIAction(title: L10n.text(.allCancel)) { [weak self] _ in
            self?.viewModel.cancel(.cancelAll)
        }
        let currentCancelAction = UIAction(title: L10n.text(.currentCardCancel)) { [weak self] _ in
            self?.viewModel.cancel(.cancelCurrent)
        }

        let cancelButton = UIBarButtonItem(
            title: L10n.text(.cancel),
            style: .plain,
            target: nil,
            action: nil
        )
        cancelButton.tintColor = .label
        let actions = visibleImageCount == 1
            ? [allCancelAction]
            : [allCancelAction, currentCancelAction]
        cancelButton.menu = UIMenu(children: actions)
        navigationItem.leftBarButtonItem = cancelButton

        navigationItem.rightBarButtonItem = nil

    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.step = state.step
            self.selectedImages = state.selectedImages
            self.processedImages = state.processedImages
            self.configureNavigationItems(
                visibleImageCount: state.visibleImageCount,
                canFinish: state.canFinish
            )
            self.updateProcessingUI(step: state.step)
            self.updateActionButtonState(state)
            self.collectionView.reloadData()

            if state.currentIndex < self.collectionView.numberOfItems(inSection: 0) {
                self.collectionView.scrollToItem(
                    at: IndexPath(item: state.currentIndex, section: 0),
                    at: .centeredHorizontally,
                    animated: false
                )
            }
        }

        viewModel.onError = { [weak self] message in
            self?.showAlert(message: message)
        }

        viewModel.onFinish = { [weak self] in
            self?.onFinish?()
        }

        viewModel.onCancel = { [weak self] in
            self?.onCancel?()
        }
    }

    private func updateProcessingUI(step: AddPhotocardStep) {
        let visibleCount = visibleImages().count
        emptyStateView.isHidden = visibleCount > 0
        countLabel.isHidden = visibleCount == 0

        switch step {
        case .processing(let progress, let message):
            processingView.isHidden = false
            progressView.progress = Float(progress)
            progressLabel.text = message
            stepLabel.text = L10n.text(.extracting)
            countLabel.text = "\(visibleCount)"
            configurePrimaryButton(
                moveButton,
                title: L10n.text(.extracting),
                imageName: "wand.and.stars"
            )
            sourceButtonStackView.isHidden = true
            sourceButtonStackHeightConstraint?.update(offset: 0)
        case .reviewing:
            processingView.isHidden = true
            stepLabel.text = L10n.text(.resultReview)
            countLabel.text = L10n.format(.resultCount, visibleCount)
            configurePrimaryButton(
                moveButton,
                title: L10n.text(.save),
                imageName: "checkmark"
            )
            sourceButtonStackView.isHidden = true
            sourceButtonStackHeightConstraint?.update(offset: 0)
        case .selecting:
            processingView.isHidden = true
            stepLabel.text = L10n.text(.addPhoto)
            countLabel.text = L10n.format(.originalCount, visibleCount)
            configurePrimaryButton(
                moveButton,
                title: L10n.text(.extractCard),
                imageName: "wand.and.stars"
            )
            sourceButtonStackView.isHidden = false
            sourceButtonStackHeightConstraint?.update(offset: 48)
        }

        updateDynamicColors()
    }

    private func updateActionButtonState(_ state: AddPhotocardViewModel.State) {
        let isEnabled: Bool
        switch state.step {
        case .selecting:
            isEnabled = state.canMoveToBinder
        case .reviewing:
            isEnabled = state.canFinish
        case .processing:
            isEnabled = false
        }

        moveButton.isEnabled = isEnabled
        moveButton.alpha = isEnabled ? 1 : 0.35
    }

    private func visibleImages() -> [UIImage] {
        switch step {
        case .reviewing:
            return processedImages.map(\.image)
        case .selecting, .processing:
            return selectedImages
        }
    }

    @objc private func selectButtonTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func cameraButtonTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(message: L10n.text(.cameraUnavailable))
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func cancelButtonTapped() {
        viewModel.cancel(.cancelAll)
    }

    @objc private func moveButtonTapped() {
        switch step {
        case .reviewing:
            viewModel.finish()
        case .selecting:
            viewModel.processSelectedImages()
        case .processing:
            break
        }
    }

    @objc private func doneButtonTapped() {
        viewModel.finish()
    }

    @objc private func appLanguageDidChange() {
        updateLocalizedTexts()
    }

    private func configurePrimaryButton(
        _ button: UIButton,
        title: String,
        imageName: String
    ) {
        var configuration = UIButton.Configuration.filled()
        var attributes = AttributeContainer()
        attributes.font = .boldSystemFont(ofSize: 17)
        configuration.attributedTitle = AttributedString(title, attributes: attributes)
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = .label
        configuration.baseForegroundColor = .systemBackground
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 16,
            bottom: 0,
            trailing: 16
        )
        button.configuration = configuration
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.layer.masksToBounds = true
    }

    private func configureSecondaryButton(
        _ button: UIButton,
        title: String,
        imageName: String
    ) {
        var configuration = UIButton.Configuration.plain()
        var attributes = AttributeContainer()
        attributes.font = .systemFont(ofSize: 16, weight: .semibold)
        configuration.attributedTitle = AttributedString(title, attributes: attributes)
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePadding = 8
        configuration.baseForegroundColor = .label
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 12,
            bottom: 0,
            trailing: 12
        )
        button.configuration = configuration
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.masksToBounds = true
    }

    private func updateDynamicColors() {
        [cameraButton, selectButton].forEach {
            $0.tintColor = .label
            $0.layer.borderColor = UIColor.separator.resolvedColor(
                with: traitCollection
            ).cgColor
        }

        moveButton.tintColor = .systemBackground
        progressView.progressTintColor = .label
        progressView.trackTintColor = .tertiarySystemFill
    }
}

extension AddPhotocardViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else {
            return
        }

        var images = Array<UIImage?>(repeating: nil, count: results.count)
        let dispatchGroup = DispatchGroup()

        for (index, result) in results.enumerated() {
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
                continue
            }

            dispatchGroup.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                images[index] = object as? UIImage
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.viewModel.setSelectedImages(images.compactMap { $0 })
        }
    }
}

extension AddPhotocardViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            return
        }

        viewModel.setSelectedImages([image])
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension AddPhotocardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        visibleImages().count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImagePreviewCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? ImagePreviewCollectionViewCell else {
            return UICollectionViewCell()
        }

        let showsPhotocardShape: Bool
        if case .reviewing = step {
            showsPhotocardShape = true
        } else {
            showsPhotocardShape = false
        }

        cell.configure(
            image: visibleImages()[indexPath.item],
            showsPhotocardShape: showsPhotocardShape
        )
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = max(scrollView.bounds.width, 1)
        let index = Int(round(scrollView.contentOffset.x / width))
        viewModel.updateCurrentIndex(index)
    }
}
