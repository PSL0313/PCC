import UIKit

extension UIViewController {
    func enableKeyboardDismissOnTap() {
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
