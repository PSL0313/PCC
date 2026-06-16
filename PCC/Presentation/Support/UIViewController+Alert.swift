import UIKit

extension UIViewController {
    func showAlert(title: String = L10n.text(.alert), message: String) {
        // 사용자에게 보여줄 기본 알림 컨트롤러.
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: L10n.text(.confirm), style: .default))
        present(alertController, animated: true)
    }
}
