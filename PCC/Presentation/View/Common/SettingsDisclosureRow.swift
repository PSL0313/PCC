import UIKit
import SnapKit

final class SettingsDisclosureRow: UIControl {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let chevronImageView = UIImageView()
    private let separatorView = UIView()

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .tertiarySystemGroupedBackground : .clear
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: String,
        value: String,
        showsSeparator: Bool
    ) {
        titleLabel.text = title
        valueLabel.text = value
        separatorView.isHidden = !showsSeparator
    }

    private func configureUI() {
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label

        valueLabel.font = .systemFont(ofSize: 17)
        valueLabel.textColor = .secondaryLabel
        valueLabel.textAlignment = .right

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit

        separatorView.backgroundColor = .separator

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(chevronImageView)
        addSubview(separatorView)

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-12)
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8)
            $0.height.equalTo(13)
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
            $0.width.greaterThanOrEqualTo(20)
        }

        separatorView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }
}
