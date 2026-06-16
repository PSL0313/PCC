import UIKit

final class ImageLoader {
    private let imageStorage: ImageStorageProtocol

    init(imageStorage: ImageStorageProtocol) {
        self.imageStorage = imageStorage
    }

    func image(for imageID: String?) -> UIImage? {
        guard let imageID,
              let data = imageStorage.loadImageData(id: imageID) else {
            return nil
        }

        return UIImage(data: data)
    }
}
