import UIKit

protocol Coordinator: AnyObject {
    var onFinish: ((Coordinator) -> Void)? { get set }
    var navigationController: UINavigationController? { get }
    var childCoordinators: [Coordinator] { get}
    
    func start()
    func finish()
    func removeChild(_ child: Coordinator)
}

