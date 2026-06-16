import UIKit
import SnapKit

final class PhotocardPreviewViewController: UIViewController {
    private let cards: [Photocard]
    private let imageLoader: ImageLoader
    private let collectionView: UICollectionView
    private var selectedIndex: Int
    var onClose: (() -> Void)?
    var onEditMetadata: ((String) -> Void)?

    init(
        cards: [Photocard],
        selectedIndex: Int,
        imageLoader: ImageLoader
    ) {
        self.cards = cards
        self.selectedIndex = selectedIndex
        self.imageLoader = imageLoader

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        addGesture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard cards.indices.contains(selectedIndex) else { return }
        collectionView.scrollToItem(
            at: IndexPath(item: selectedIndex, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
    }

    private func configureUI() {
        view.backgroundColor = Colors.Theme.mainBackgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissViewController)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            style: .plain,
            target: self,
            action: #selector(editMetadataButtonTapped)
        )

        collectionView.backgroundColor = Colors.Theme.mainBackgroundColor
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            ImagePreviewCollectionViewCell.self,
            forCellWithReuseIdentifier: ImagePreviewCollectionViewCell.reuseIdentifier
        )

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func addGesture() {
        let swipeGesture = UISwipeGestureRecognizer(
            target: self,
            action: #selector(dismissViewController)
        )
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }

    @objc private func dismissViewController() {
        onClose?()
    }

    @objc private func editMetadataButtonTapped() {
        guard cards.indices.contains(selectedIndex) else { return }
        onEditMetadata?(cards[selectedIndex].id)
    }
}

extension PhotocardPreviewViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        cards.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImagePreviewCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? ImagePreviewCollectionViewCell else {
            return UICollectionViewCell()
        }

        let image = imageLoader.image(for: cards[indexPath.item].imageID)
            ?? UIImage(systemName: "rectangle.portrait")
            ?? UIImage()
        cell.configure(image: image)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = max(scrollView.bounds.width, 1)
        selectedIndex = Int(round(scrollView.contentOffset.x / width))
    }
}
