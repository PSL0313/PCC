import UIKit
import SnapKit

class BasePhotocardDisplayCell: UICollectionViewCell {
    class var reuseIdentifier: String {
        String(describing: self)
    }

    class var visibleOptions: [CardDisplayOption] {
        []
    }

    class func preferredHeight(for width: CGFloat) -> CGFloat {
        let horizontalInset: CGFloat = 12
        let imageHeight = max(width - horizontalInset, 1) * 1.55
        let lineCount = visibleOptions.count

        guard lineCount > 0 else {
            return imageHeight + 12
        }

        let lineHeight: CGFloat = 16
        let lineSpacing = CGFloat(max(lineCount - 1, 0)) * 2
        return 6 + imageHeight + 5 + CGFloat(lineCount) * lineHeight + lineSpacing + 8
    }

    private let imageView = UIImageView()
    private let infoStackView = UIStackView()
    private let titleLabel = UILabel()
    private let memberLabel = UILabel()
    private let categoryLabel = UILabel()
    private let selectionDimView = UIView()
    private let selectionBadgeView = UIImageView()
    private let cardCornerRatio: CGFloat = 0.055

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        applyCardImageCornerRadius()
        [titleLabel, memberLabel, categoryLabel].forEach {
            $0.text = nil
            $0.isHidden = true
        }
        setSelectionMode(isEnabled: false, isSelected: false)
    }

    func configure(
        photocard: Photocard,
        imageLoader: ImageLoader,
        displayOptions: Set<CardDisplayOption>
    ) {
        let options = Set(type(of: self).visibleOptions)
        imageView.image = imageLoader.image(for: photocard.imageID)
            ?? UIImage(systemName: "rectangle.portrait")

        titleLabel.text = photocard.title
        titleLabel.isHidden = !options.contains(.title)

        memberLabel.text = L10n.displayMember(photocard.memberName)
        memberLabel.isHidden = !options.contains(.memberName)

        categoryLabel.text = L10n.displayCategory(photocard.category)
        categoryLabel.isHidden = !options.contains(.category)

        remakeImageConstraints(hasMetadata: !options.isEmpty)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        applyCardImageCornerRadius()
    }

    private func configureUI() {
        contentView.backgroundColor = Colors.Theme.cardViewBackgroundColor
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = .tertiaryLabel
        imageView.backgroundColor = Colors.Theme.mainBackgroundColor
        imageView.layer.masksToBounds = true
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true

        selectionDimView.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        selectionDimView.isHidden = true
        selectionDimView.isUserInteractionEnabled = false

        selectionBadgeView.image = UIImage(systemName: "checkmark.circle.fill")
        selectionBadgeView.tintColor = .systemBlue
        selectionBadgeView.backgroundColor = .white
        selectionBadgeView.layer.cornerRadius = 11
        selectionBadgeView.layer.masksToBounds = true
        selectionBadgeView.isHidden = true
        selectionBadgeView.isUserInteractionEnabled = false

        infoStackView.axis = .vertical
        infoStackView.spacing = 2
        infoStackView.alignment = .fill

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        memberLabel.font = .systemFont(ofSize: 12, weight: .regular)
        categoryLabel.font = .systemFont(ofSize: 12, weight: .regular)

        [titleLabel, memberLabel, categoryLabel].forEach {
            $0.textColor = $0 === titleLabel ? .label : .secondaryLabel
            $0.numberOfLines = 1
            $0.lineBreakMode = .byTruncatingTail
            $0.isHidden = true
            infoStackView.addArrangedSubview($0)
        }

        contentView.addSubview(imageView)
        contentView.addSubview(infoStackView)
        contentView.addSubview(selectionDimView)
        contentView.addSubview(selectionBadgeView)
        remakeImageConstraints(hasMetadata: false)

        infoStackView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(5)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.bottom.lessThanOrEqualToSuperview().inset(8)
        }

        selectionDimView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        selectionBadgeView.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(8)
            $0.size.equalTo(22)
        }
    }

    private func remakeImageConstraints(hasMetadata: Bool) {
        imageView.snp.remakeConstraints {
            if hasMetadata {
                $0.top.leading.trailing.equalToSuperview().inset(6)
                $0.height.equalTo(imageView.snp.width).multipliedBy(1.55)
            } else {
                $0.edges.equalToSuperview().inset(6)
            }
        }
    }

    private func applyCardImageCornerRadius() {
        let width = imageView.bounds.width
        guard width > 0 else { return }
        imageView.layer.cornerRadius = width * cardCornerRatio
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
    }

    func setSelectionMode(
        isEnabled: Bool,
        isSelected: Bool
    ) {
        selectionDimView.isHidden = !isEnabled || !isSelected
        selectionBadgeView.isHidden = !isEnabled || !isSelected
        contentView.layer.borderWidth = isEnabled && isSelected ? 2 : 0
        contentView.layer.borderColor = UIColor.systemBlue.cgColor
    }
}

final class ImageOnlyPhotocardCell: BasePhotocardDisplayCell {}

final class TitleOnlyPhotocardCell: BasePhotocardDisplayCell {
    override class var visibleOptions: [CardDisplayOption] { [.title] }
}

final class MemberOnlyPhotocardCell: BasePhotocardDisplayCell {
    override class var visibleOptions: [CardDisplayOption] { [.memberName] }
}

final class CategoryOnlyPhotocardCell: BasePhotocardDisplayCell {
    override class var visibleOptions: [CardDisplayOption] { [.category] }
}

final class TitleMemberPhotocardCell: BasePhotocardDisplayCell {
    override class var visibleOptions: [CardDisplayOption] { [.title, .memberName] }
}

final class TitleCategoryPhotocardCell: BasePhotocardDisplayCell {
    override class var visibleOptions: [CardDisplayOption] { [.title, .category] }
}

final class MemberCategoryPhotocardCell: BasePhotocardDisplayCell {
    override class var visibleOptions: [CardDisplayOption] { [.memberName, .category] }
}

final class FullInfoPhotocardCell: BasePhotocardDisplayCell {
    override class var visibleOptions: [CardDisplayOption] { [.title, .memberName, .category] }
}

enum PhotocardCellKind {
    case imageOnly
    case titleOnly
    case memberOnly
    case categoryOnly
    case titleMember
    case titleCategory
    case memberCategory
    case fullInfo

    init(displayOptions: Set<CardDisplayOption>) {
        let hasTitle = displayOptions.contains(.title)
        let hasMember = displayOptions.contains(.memberName)
        let hasCategory = displayOptions.contains(.category)

        switch (hasTitle, hasMember, hasCategory) {
        case (false, false, false):
            self = .imageOnly
        case (true, false, false):
            self = .titleOnly
        case (false, true, false):
            self = .memberOnly
        case (false, false, true):
            self = .categoryOnly
        case (true, true, false):
            self = .titleMember
        case (true, false, true):
            self = .titleCategory
        case (false, true, true):
            self = .memberCategory
        case (true, true, true):
            self = .fullInfo
        }
    }

    var cellType: BasePhotocardDisplayCell.Type {
        switch self {
        case .imageOnly:
            return ImageOnlyPhotocardCell.self
        case .titleOnly:
            return TitleOnlyPhotocardCell.self
        case .memberOnly:
            return MemberOnlyPhotocardCell.self
        case .categoryOnly:
            return CategoryOnlyPhotocardCell.self
        case .titleMember:
            return TitleMemberPhotocardCell.self
        case .titleCategory:
            return TitleCategoryPhotocardCell.self
        case .memberCategory:
            return MemberCategoryPhotocardCell.self
        case .fullInfo:
            return FullInfoPhotocardCell.self
        }
    }
}
