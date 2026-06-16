import UIKit
import SnapKit

final class TextFieldTableViewCell: UITableViewCell {
    static let reuseIdentifier = "TextFieldTableViewCell"

    let textField = UITextField()
    var onTextChanged: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTextChanged = nil
    }

    private func configureUI() {
        selectionStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.addTarget(
            self,
            action: #selector(textFieldChanged),
            for: .editingChanged
        )

        contentView.addSubview(textField)
        textField.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
            $0.height.equalTo(34)
        }
    }

    @objc private func textFieldChanged() {
        onTextChanged?(textField.text ?? "")
    }
}
