import UIKit

final class OpenCVPhotocardImageProcessor: PhotocardImageProcessingServiceProtocol {
    private let fallbackProcessor: PhotocardImageProcessingServiceProtocol

    init(fallbackProcessor: PhotocardImageProcessingServiceProtocol = VisionPhotocardImageProcessor()) {
        self.fallbackProcessor = fallbackProcessor
    }

    func process(
        images: [UIImage],
        progress: @escaping (Double, String) -> Void,
        completion: @escaping ([ProcessedPhotocardImage]) -> Void
    ) {
        guard !images.isEmpty else {
            completion([])
            return
        }

        var results: [ProcessedPhotocardImage] = []

        func processNext(_ index: Int) {
            guard index < images.count else {
                completion(results)
                return
            }

            let normalizedImage = images[index]
                .normalizedForVisionProcessing()
                .renderedForOpenCVProcessing()
            progress(
                Double(index) / Double(images.count),
                L10n.format(.processingOpenCVContour, index + 1, images.count)
            )

            DispatchQueue.global(qos: .userInitiated).async {
                // OpenCV 컨투어로 카드 외곽선을 먼저 찾고, 실패 시 기존 Vision 보정으로 폴백한다.
                let extractedImage = OpenCVPhotocardExtractor.extractPhotocard(from: normalizedImage)

                DispatchQueue.main.async {
                    if let extractedImage {
                        results.append(
                            ProcessedPhotocardImage(
                                image: extractedImage,
                                sourceIndex: index
                            )
                        )
                        progress(
                            Double(index + 1) / Double(images.count),
                            L10n.format(.processingOpenCVComplete, index + 1, images.count)
                        )
                        processNext(index + 1)
                    } else {
                        self.processWithFallback(
                            image: normalizedImage,
                            sourceIndex: index,
                            progress: progress
                        ) { fallbackResult in
                            results.append(fallbackResult)
                            processNext(index + 1)
                        }
                    }
                }
            }
        }

        processNext(0)
    }

    private func processWithFallback(
        image: UIImage,
        sourceIndex: Int,
        progress: @escaping (Double, String) -> Void,
        completion: @escaping (ProcessedPhotocardImage) -> Void
    ) {
        fallbackProcessor.process(
            images: [image],
            progress: { _, message in
                progress(0, L10n.format(.processingVisionFallback, message))
            },
            completion: { fallbackResults in
                if let fallbackResult = fallbackResults.first {
                    completion(
                        ProcessedPhotocardImage(
                            image: fallbackResult.image,
                            sourceIndex: sourceIndex
                        )
                    )
                } else {
                    completion(
                        ProcessedPhotocardImage(
                            image: image,
                            sourceIndex: sourceIndex
                        )
                    )
                }
            }
        )
    }
}
