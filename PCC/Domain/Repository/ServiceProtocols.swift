import Foundation
import UIKit

struct ProcessedPhotocardImage {
    let image: UIImage
    let sourceIndex: Int
}

protocol PhotocardImageProcessingServiceProtocol {
    func process(
        images: [UIImage],
        progress: @escaping (Double, String) -> Void,
        completion: @escaping ([ProcessedPhotocardImage]) -> Void
    )
}

protocol PhotocardClassificationServiceProtocol {
    func classify(imageData: Data) -> PhotocardClassification?
}

protocol InAppPurchaseServiceProtocol {
    func canUsePremiumFeatures() -> Bool
}
