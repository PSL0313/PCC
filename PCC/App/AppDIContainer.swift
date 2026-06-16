import Foundation

final class AppDIContainer {

    private lazy var localBinderDataSource: LocalBinderDataSourceProtocol = {
        LocalBinderDataSource()
    }()

    private lazy var binderRepository: BinderRepositoryProtocol = {
        BinderRepositoryImpl(dataSource: localBinderDataSource)
    }()

    private lazy var imageStorage: ImageStorageProtocol = {
        FileImageStorage()
    }()

    private lazy var imageProcessor: PhotocardImageProcessingServiceProtocol = {
        OpenCVPhotocardImageProcessor()
    }()

    private lazy var classificationService: PhotocardClassificationServiceProtocol = {
        PlaceholderPhotocardClassificationService()
    }()

    private lazy var purchaseService: InAppPurchaseServiceProtocol = {
        PlaceholderInAppPurchaseService()
    }()

    func makeHomeViewController() -> HomeViewController {
        HomeViewController(
            viewModel: makeHomeViewModel(),
            imageLoader: makeImageLoader()
        )
    }

    func makeAppSettingViewController() -> AppSettingViewController {
        AppSettingViewController()
    }

    func makeLanguageSettingViewController() -> LanguageSettingViewController {
        LanguageSettingViewController()
    }

    func makeBinderDetailViewController(binderID: String) -> BinderDetailViewController {
        BinderDetailViewController(
            viewModel: makeBinderDetailViewModel(binderID: binderID),
            imageLoader: makeImageLoader()
        )
    }

    func makeBinderSettingViewController(mode: BinderSettingMode) -> BinderSettingViewController {
        BinderSettingViewController(
            viewModel: makeBinderSettingViewModel(mode: mode),
            imageLoader: makeImageLoader()
        )
    }

    func makeAddPhotocardViewController(binderID: String) -> AddPhotocardViewController {
        AddPhotocardViewController(viewModel: makeAddPhotocardViewModel(binderID: binderID))
    }

    func makePhotocardPreviewViewController(
        cards: [Photocard],
        selectedIndex: Int
    ) -> PhotocardPreviewViewController {
        PhotocardPreviewViewController(
            cards: cards,
            selectedIndex: selectedIndex,
            imageLoader: makeImageLoader()
        )
    }

    func makePhotocardMetadataViewController(
        binderID: String,
        photocardID: String
    ) -> PhotocardMetadataViewController {
        PhotocardMetadataViewController(
            viewModel: makePhotocardMetadataViewModel(
                binderID: binderID,
                photocardID: photocardID
            )
        )
    }

    func makeStringListManagementViewController(
        title: String,
        items: [String],
        addTitle: String,
        placeholder: String,
        onAdd: @escaping (String) -> Void
    ) -> StringListManagementViewController {
        StringListManagementViewController(
            title: title,
            items: items,
            addTitle: addTitle,
            placeholder: placeholder,
            onAdd: onAdd
        )
    }

    private func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            fetchBindersUseCase: FetchBindersUseCase(repository: binderRepository),
            deleteBindersUseCase: DeleteBindersUseCase(
                repository: binderRepository,
                imageStorage: imageStorage
            )
        )
    }

    private func makeBinderDetailViewModel(binderID: String) -> BinderDetailViewModel {
        BinderDetailViewModel(
            binderID: binderID,
            fetchBinderUseCase: FetchBinderUseCase(repository: binderRepository),
            deletePhotocardsUseCase: DeletePhotocardsUseCase(
                repository: binderRepository,
                imageStorage: imageStorage
            )
        )
    }

    private func makeBinderSettingViewModel(mode: BinderSettingMode) -> BinderSettingViewModel {
        BinderSettingViewModel(
            mode: mode,
            fetchBinderUseCase: FetchBinderUseCase(repository: binderRepository),
            createBinderUseCase: CreateBinderUseCase(repository: binderRepository),
            updateBinderUseCase: UpdateBinderUseCase(repository: binderRepository),
            deleteBindersUseCase: DeleteBindersUseCase(
                repository: binderRepository,
                imageStorage: imageStorage
            ),
            imageStorage: imageStorage
        )
    }

    private func makeAddPhotocardViewModel(binderID: String) -> AddPhotocardViewModel {
        AddPhotocardViewModel(
            binderID: binderID,
            processImagesUseCase: ProcessPhotocardImagesUseCase(processor: imageProcessor),
            savePhotocardsUseCase: SavePhotocardsUseCase(repository: binderRepository),
            classifyPhotocardUseCase: ClassifyPhotocardUseCase(classifier: classificationService),
            imageStorage: imageStorage
        )
    }

    private func makePhotocardMetadataViewModel(
        binderID: String,
        photocardID: String
    ) -> PhotocardMetadataViewModel {
        PhotocardMetadataViewModel(
            binderID: binderID,
            photocardID: photocardID,
            fetchBinderUseCase: FetchBinderUseCase(repository: binderRepository),
            updatePhotocardUseCase: UpdatePhotocardUseCase(repository: binderRepository),
            deletePhotocardUseCase: DeletePhotocardUseCase(
                repository: binderRepository,
                imageStorage: imageStorage
            )
        )
    }

    private func makeImageLoader() -> ImageLoader {
        ImageLoader(imageStorage: imageStorage)
    }
}
