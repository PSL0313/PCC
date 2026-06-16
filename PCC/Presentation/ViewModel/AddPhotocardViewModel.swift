import Foundation
import UIKit

final class AddPhotocardViewModel {
    struct State {
        let step: AddPhotocardStep
        let selectedImages: [UIImage]
        let processedImages: [ProcessedPhotocardImage]
        let currentIndex: Int
        let visibleImageCount: Int
        let canMoveToBinder: Bool
        let canFinish: Bool
    }

    var onStateChange: ((State) -> Void)?
    var onFinish: (() -> Void)?
    var onCancel: (() -> Void)?
    var onError: ((String) -> Void)?

    private let binderID: String
    private let processImagesUseCase: ProcessPhotocardImagesUseCase
    private let savePhotocardsUseCase: SavePhotocardsUseCase
    private let classifyPhotocardUseCase: ClassifyPhotocardUseCase
    private let imageStorage: ImageStorageProtocol

    private var step: AddPhotocardStep = .selecting
    private(set) var selectedImages: [UIImage] = []
    private(set) var processedImages: [ProcessedPhotocardImage] = []
    private var currentIndex = 0

    init(
        binderID: String,
        processImagesUseCase: ProcessPhotocardImagesUseCase,
        savePhotocardsUseCase: SavePhotocardsUseCase,
        classifyPhotocardUseCase: ClassifyPhotocardUseCase,
        imageStorage: ImageStorageProtocol
    ) {
        self.binderID = binderID
        self.processImagesUseCase = processImagesUseCase
        self.savePhotocardsUseCase = savePhotocardsUseCase
        self.classifyPhotocardUseCase = classifyPhotocardUseCase
        self.imageStorage = imageStorage
    }

    func load() {
        emitState()
    }

    func setSelectedImages(_ images: [UIImage]) {
        selectedImages = images
        processedImages = []
        currentIndex = 0
        step = .selecting
        emitState()
    }

    func processSelectedImages() {
        guard !selectedImages.isEmpty else {
            return
        }

        step = .processing(progress: 0, message: L10n.text(.photoAnalyzePreparing))
        emitState()

        processImagesUseCase.execute(
            images: selectedImages,
            progress: { [weak self] progress, message in
                DispatchQueue.main.async {
                    self?.step = .processing(progress: progress, message: message)
                    self?.emitState()
                }
            },
            completion: { [weak self] results in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.processedImages = results
                    self.currentIndex = 0
                    self.step = .reviewing
                    self.emitState()
                }
            }
        )
    }

    func updateCurrentIndex(_ index: Int) {
        let maxIndex = max(visibleImageCount - 1, 0)
        currentIndex = max(0, min(index, maxIndex))
    }

    func cancel(_ option: CancellationOption) {
        switch option {
        case .cancelAll:
            onCancel?()
        case .cancelCurrent:
            guard visibleImageCount > 1 else {
                onCancel?()
                return
            }

            guard processedImages.indices.contains(currentIndex) else {
                if selectedImages.indices.contains(currentIndex) {
                    selectedImages.remove(at: currentIndex)
                    currentIndex = min(currentIndex, max(selectedImages.count - 1, 0))
                    emitState()
                }
                return
            }

            processedImages.remove(at: currentIndex)
            currentIndex = min(currentIndex, max(processedImages.count - 1, 0))

            if processedImages.isEmpty {
                step = .selecting
            }

            emitState()
        }
    }

    func finish() {
        guard !processedImages.isEmpty else {
            onError?(L10n.text(.noSaveableCard))
            return
        }

        do {
            let cards = try processedImages.enumerated().compactMap { index, processedImage -> Photocard? in
                guard let data = processedImage.image.jpegData(compressionQuality: 0.92) else {
                    return nil
                }

                let imageID = try imageStorage.saveImageData(data, preferredExtension: "jpg")
                let classification = classifyPhotocardUseCase.execute(imageData: data)

                return Photocard(
                    title: L10n.text(.noTitle),
                    imageID: imageID,
                    sortIndex: index,
                    classification: classification
                )
            }

            try savePhotocardsUseCase.execute(cards, to: binderID)
            onFinish?()
        } catch {
            onError?(L10n.text(.saveToBinderFailed))
        }
    }

    private func emitState() {
        onStateChange?(
            State(
                step: step,
                selectedImages: selectedImages,
                processedImages: processedImages,
                currentIndex: currentIndex,
                visibleImageCount: visibleImageCount,
                canMoveToBinder: !selectedImages.isEmpty,
                canFinish: !processedImages.isEmpty
            )
        )
    }

    private var visibleImageCount: Int {
        switch step {
        case .reviewing:
            return processedImages.count
        case .selecting, .processing:
            return selectedImages.count
        }
    }
}
