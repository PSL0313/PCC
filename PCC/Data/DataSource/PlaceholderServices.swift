import Foundation

final class PlaceholderPhotocardClassificationService: PhotocardClassificationServiceProtocol {
    func classify(imageData: Data) -> PhotocardClassification? {
        nil
    }
}

final class PlaceholderInAppPurchaseService: InAppPurchaseServiceProtocol {
    func canUsePremiumFeatures() -> Bool {
        false
    }
}
