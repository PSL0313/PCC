import Foundation
import UIKit

final class SavePhotocardsUseCase {
    private let repository: BinderRepositoryProtocol

    init(repository: BinderRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ photocards: [Photocard], to binderID: String) throws {
        try repository.addPhotocards(photocards, to: binderID)
    }
}

final class UpdatePhotocardUseCase {
    private let repository: BinderRepositoryProtocol

    init(repository: BinderRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ photocard: Photocard, in binderID: String) throws {
        try repository.updatePhotocard(photocard, in: binderID)
    }
}

final class DeletePhotocardUseCase {
    private let repository: BinderRepositoryProtocol
    private let imageStorage: ImageStorageProtocol

    init(
        repository: BinderRepositoryProtocol,
        imageStorage: ImageStorageProtocol
    ) {
        self.repository = repository
        self.imageStorage = imageStorage
    }

    func execute(photocardID: String, from binderID: String) throws {
        try DeletePhotocardsUseCase(
            repository: repository,
            imageStorage: imageStorage
        ).execute(photocardIDs: [photocardID], from: binderID)
    }
}

final class DeletePhotocardsUseCase {
    private let repository: BinderRepositoryProtocol
    private let imageStorage: ImageStorageProtocol

    init(
        repository: BinderRepositoryProtocol,
        imageStorage: ImageStorageProtocol
    ) {
        self.repository = repository
        self.imageStorage = imageStorage
    }

    func execute(photocardIDs: Set<String>, from binderID: String) throws {
        guard !photocardIDs.isEmpty else { return }

        let imageIDs = try repository.fetchBinder(id: binderID)?
            .photocards
            .filter { photocardIDs.contains($0.id) }
            .map(\.imageID) ?? []

        try repository.removePhotocards(ids: photocardIDs, from: binderID)
        imageIDs.forEach { try? imageStorage.deleteImageData(id: $0) }
    }
}

final class ProcessPhotocardImagesUseCase {
    private let processor: PhotocardImageProcessingServiceProtocol

    init(processor: PhotocardImageProcessingServiceProtocol) {
        self.processor = processor
    }

    func execute(
        images: [UIImage],
        progress: @escaping (Double, String) -> Void,
        completion: @escaping ([ProcessedPhotocardImage]) -> Void
    ) {
        processor.process(images: images, progress: progress, completion: completion)
    }
}

final class ClassifyPhotocardUseCase {
    private let classifier: PhotocardClassificationServiceProtocol

    init(classifier: PhotocardClassificationServiceProtocol) {
        self.classifier = classifier
    }

    func execute(imageData: Data) -> PhotocardClassification? {
        classifier.classify(imageData: imageData)
    }
}

final class CheckPremiumAccessUseCase {
    private let purchaseService: InAppPurchaseServiceProtocol

    init(purchaseService: InAppPurchaseServiceProtocol) {
        self.purchaseService = purchaseService
    }

    func execute() -> Bool {
        purchaseService.canUsePremiumFeatures()
    }
}
