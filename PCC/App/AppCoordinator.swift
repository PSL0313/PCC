import UIKit

final class AppCoordinator: Coordinator {
    private var window: UIWindow
    private let appDIContainer: AppDIContainer
    private(set) var childCoordinators: [Coordinator] = []
    private(set) var navigationController: UINavigationController?
    
    var onFinish: ((Coordinator) -> Void)?

    init(window: UIWindow, appDIContainer: AppDIContainer) {
        self.window = window
        self.appDIContainer = appDIContainer
    }

    func start() {
        // 앱 첫 화면으로 사용할 홈 뷰컨.
        let homeViewController = makeHomeViewController()
        // 홈 화면을 감싸는 메인 네비게이션 컨트롤러.
        let navigationController = UINavigationController(rootViewController: homeViewController)
        self.setNavigationController(navigationController)
        self.window.rootViewController = navigationController
        self.window.makeKeyAndVisible()
    }

    func finish() {
    }

    func removeChild(_ child: Coordinator) {
        childCoordinators.removeAll { $0 === child }
    }

    func setNavigationController(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
}

private extension AppCoordinator {
    func makeHomeViewController() -> HomeViewController {
        let viewController = appDIContainer.makeHomeViewController()
        viewController.onRoute = { [weak self] route in
            switch route {
            case .appSetting:
                self?.showAppSetting()
            case .createBinder:
                self?.showCreateBinder()
            case .binderDetail(let binderID):
                self?.showBinderDetail(binderID: binderID)
            }
        }

        return viewController
    }

    func showAppSetting() {
        let viewController = appDIContainer.makeAppSettingViewController()
        viewController.onRoute = { [weak self] route in
            switch route {
            case .languageSetting:
                self?.showLanguageSetting()
            }
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    func showLanguageSetting() {
        let viewController = appDIContainer.makeLanguageSettingViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func showCreateBinder() {
        let viewController = appDIContainer.makeBinderSettingViewController(mode: .create)

        viewController.onFinish = { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        viewController.onRoute = { [weak self] route in
            self?.showBinderSettingRoute(route)
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    func showBinderDetail(binderID: String) {
        let viewController = appDIContainer.makeBinderDetailViewController(binderID: binderID)

        viewController.onRoute = { [weak self] route in
            switch route {
            case .binderSetting(let binderID):
                self?.showBinderSetting(binderID: binderID)
            case .addPhotocard(let binderID):
                self?.showAddPhotocardFlow(binderID: binderID)
            case .photocardPreview(let binderID, let cards, let selectedIndex):
                self?.showPhotocardPreview(
                    binderID: binderID,
                    cards: cards,
                    selectedIndex: selectedIndex
                )
            }
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    func showBinderSetting(binderID: String) {
        let viewController = appDIContainer.makeBinderSettingViewController(
            mode: .edit(binderID: binderID)
        )

        viewController.onFinish = { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        viewController.onDeleted = { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        viewController.onRoute = { [weak self] route in
            self?.showBinderSettingRoute(route)
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    func showAddPhotocardFlow(binderID: String) {
        let viewController = appDIContainer.makeAddPhotocardViewController(binderID: binderID)
        // 포토카드 추가 플로우를 전체 화면으로 보여줄 네비게이션 컨트롤러.
        let modalNavigationController = UINavigationController(rootViewController: viewController)
        modalNavigationController.modalPresentationStyle = .fullScreen

        viewController.onFinish = { [weak modalNavigationController] in
            modalNavigationController?.dismiss(animated: true)
        }

        viewController.onCancel = { [weak modalNavigationController] in
            modalNavigationController?.dismiss(animated: true)
        }

        navigationController?.present(modalNavigationController, animated: true)
    }

    func showPhotocardPreview(
        binderID: String,
        cards: [Photocard],
        selectedIndex: Int
    ) {
        let viewController = appDIContainer.makePhotocardPreviewViewController(
            cards: cards,
            selectedIndex: selectedIndex
        )
        // 미리보기와 메타데이터 화면을 함께 관리할 모달 네비게이션 컨트롤러.
        let modalNavigationController = UINavigationController(rootViewController: viewController)
        modalNavigationController.modalPresentationStyle = .fullScreen

        viewController.onClose = { [weak modalNavigationController] in
            modalNavigationController?.dismiss(animated: true)
        }

        viewController.onEditMetadata = { [weak self, weak modalNavigationController] photocardID in
            guard let self else { return }
            let editViewController = self.appDIContainer.makePhotocardMetadataViewController(
                binderID: binderID,
                photocardID: photocardID
            )
            editViewController.onFinish = { [weak modalNavigationController] in
                modalNavigationController?.popViewController(animated: true)
            }
            editViewController.onDeleted = { [weak modalNavigationController] in
                modalNavigationController?.dismiss(animated: true)
            }
            modalNavigationController?.pushViewController(editViewController, animated: true)
        }

        navigationController?.present(modalNavigationController, animated: true)
    }
    
    func showBinderSettingRoute(_ route: BinderSettingViewController.Route) {
        let viewController: StringListManagementViewController
        switch route {
        case .categoryList(let items, let onAdd):
            viewController = appDIContainer.makeStringListManagementViewController(
                title: L10n.text(.category),
                items: items,
                addTitle: L10n.text(.categoryAdd),
                placeholder: L10n.text(.categoryName),
                onAdd: onAdd
            )
        case .memberList(let items, let onAdd):
            viewController = appDIContainer.makeStringListManagementViewController(
                title: L10n.text(.member),
                items: items,
                addTitle: L10n.text(.memberAdd),
                placeholder: L10n.text(.memberNamePlaceholder),
                onAdd: onAdd
            )
        }

        navigationController?.pushViewController(viewController, animated: true)
    }
    
}
