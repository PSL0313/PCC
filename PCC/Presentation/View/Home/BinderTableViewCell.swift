import UIKit
import SnapKit

final class BinderTableViewCell: UITableViewCell {
    static let reuseIdentifier = "BinderTableViewCell"

    private let cardContainerView = UIView()
    private let profileImageView = UIImageView()
    private let textStackView = UIStackView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let previewStackView = UIView()
    private let selectionDimView = UIView()
    private let selectionBadgeView = UIImageView()
    private var previewImageViews: [UIImageView] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        previewImageViews.forEach { $0.image = nil }
        setSelectionMode(isEnabled: false, isSelected: false)
    }

    func configure(
        binder: Binder,
        imageLoader: ImageLoader
    ) {
        cardContainerView.backgroundColor = UIColor(hex: binder.backgroundHex)
        titleLabel.text = binder.name
        countLabel.text = L10n.format(.cardCount, binder.photocards.count)

        profileImageView.image = imageLoader.image(for: binder.profileImageID)
            ?? UIImage(systemName: "person.crop.circle.fill")

        let previewIDs = Array(binder.photocards.suffix(3)).map(\.imageID)
        for (index, imageView) in previewImageViews.enumerated() {
            imageView.image = index < previewIDs.count
                ? imageLoader.image(for: previewIDs[index])
                : UIImage(systemName: "rectangle.portrait")
        }
    }

    func setSelectionMode(isEnabled: Bool, isSelected: Bool) {
        selectionDimView.isHidden = !isEnabled
        selectionBadgeView.isHidden = !isEnabled
        selectionDimView.alpha = isSelected ? 1 : 0.35
        selectionBadgeView.image = UIImage(
            systemName: isSelected ? "checkmark.circle.fill" : "circle"
        )
        selectionBadgeView.tintColor = isSelected ? .systemBlue : .white
    }

    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardContainerView.layer.cornerRadius = 18
        cardContainerView.layer.masksToBounds = true

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.tintColor = .secondaryLabel
        profileImageView.backgroundColor = .systemBackground.withAlphaComponent(0.7)
        profileImageView.layer.cornerRadius = 28
        profileImageView.layer.masksToBounds = true

        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 2

        countLabel.font = .systemFont(ofSize: 13, weight: .medium)
        countLabel.textColor = .gray

        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 6
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(countLabel)

        contentView.addSubview(cardContainerView)
        cardContainerView.addSubview(profileImageView)
        cardContainerView.addSubview(textStackView)
        cardContainerView.addSubview(previewStackView)
        cardContainerView.addSubview(selectionDimView)
        cardContainerView.addSubview(selectionBadgeView)

        selectionDimView.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        selectionDimView.isHidden = true
        selectionDimView.isUserInteractionEnabled = false

        selectionBadgeView.tintColor = .systemBlue
        selectionBadgeView.backgroundColor = .white
        selectionBadgeView.layer.cornerRadius = 12
        selectionBadgeView.layer.masksToBounds = true
        selectionBadgeView.isHidden = true

        cardContainerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(8)
            $0.height.equalTo(132)
        }

        profileImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(18)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(56)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(profileImageView.snp.trailing).offset(14)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(previewStackView.snp.leading).offset(-10)
            $0.top.greaterThanOrEqualToSuperview().offset(18)
            $0.bottom.lessThanOrEqualToSuperview().inset(18)
        }

        previewStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(18)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(104)
            $0.height.equalTo(92)
        }

        selectionDimView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        selectionBadgeView.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(14)
            $0.size.equalTo(24)
        }

        makePreviewImageViews()
    }

    private func makePreviewImageViews() {
        for index in 0..<3 {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.tintColor = .gray
            imageView.backgroundColor = .white
            imageView.layer.cornerRadius = 8
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 2
            imageView.layer.masksToBounds = true
            previewStackView.addSubview(imageView)
            previewImageViews.append(imageView)

            let rotation = CGFloat(index - 1) * 0.12
            imageView.transform = CGAffineTransform(rotationAngle: rotation)

            imageView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalToSuperview().offset(index * 22)
                $0.width.equalTo(56)
                $0.height.equalTo(80)
            }
        }
    }
}
