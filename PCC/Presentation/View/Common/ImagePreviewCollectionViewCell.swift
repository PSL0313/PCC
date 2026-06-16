import UIKit

final class ImagePreviewCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "ImagePreviewCollectionViewCell"

    private let imageContainerView = UIView()
    private let imageView = UIImageView()
    private let cardCornerRatio: CGFloat = 0.095
    private let photocardAspectRatio: CGFloat = 55.0 / 85.0
    private var showsPhotocardShape = true

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
    }

    func configure(image: UIImage, showsPhotocardShape: Bool = true) {
        imageView.image = image
        self.showsPhotocardShape = showsPhotocardShape
        imageView.contentMode = showsPhotocardShape ? .scaleAspectFill : .scaleAspectFit
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageContainerView.frame = imageContainerFrame()
        imageContainerView.layer.cornerRadius = showsPhotocardShape
            ? imageContainerView.bounds.width * cardCornerRatio
            : 0
        imageView.frame = imageContainerView.bounds
    }

    private func imageContainerFrame() -> CGRect {
        guard showsPhotocardShape else {
            return contentView.bounds
        }

        let availableBounds = contentView.bounds.insetBy(dx: 28, dy: 28)
        guard availableBounds.width > 0, availableBounds.height > 0 else {
            return contentView.bounds
        }

        let availableRatio = availableBounds.width / availableBounds.height
        let size: CGSize
        if availableRatio > photocardAspectRatio {
            let height = availableBounds.height
            size = CGSize(width: height * photocardAspectRatio, height: height)
        } else {
            let width = availableBounds.width
            size = CGSize(width: width, height: width / photocardAspectRatio)
        }

        return CGRect(
            x: contentView.bounds.midX - size.width / 2,
            y: contentView.bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private func configureUI() {
        contentView.backgroundColor = Colors.Theme.mainBackgroundColor

        imageContainerView.backgroundColor = Colors.Theme.mainBackgroundColor
        imageContainerView.layer.masksToBounds = true
        imageContainerView.layer.cornerCurve = .continuous

        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = Colors.Theme.mainBackgroundColor

        contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(imageView)
    }
}
