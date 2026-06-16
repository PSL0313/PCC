import UIKit
import Vision

final class VisionPhotocardImageProcessor: PhotocardImageProcessingServiceProtocol {
    private let detector: PhotocardDetector
    private let perspectiveCorrector: PhotocardPerspectiveCorrector
    private let targetAspectRatio: CGFloat = 55.0 / 85.0
    private let postCorrectionInsetRatio: CGFloat = 0.025
    private let outputSize = CGSize(width: 1100, height: 1700)

    init(
        detector: PhotocardDetector = PhotocardDetector(),
        perspectiveCorrector: PhotocardPerspectiveCorrector = PhotocardPerspectiveCorrector()
    ) {
        self.detector = detector
        self.perspectiveCorrector = perspectiveCorrector
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

            let normalizedImage = images[index].normalizedForVisionProcessing()
            let message = L10n.format(.imageAnalyzing, index + 1, images.count)
            progress(Double(index) / Double(images.count), message)

            // Vision으로 포토카드 후보 사각형을 찾고, 실패하면 원본 이미지를 검수 단계로 넘긴다.
            detector.detectRectangles(from: normalizedImage) { [weak self] rectangles in
                guard let self else { return }

                let correctedImage: UIImage
                if let rectangle = self.selectBestPhotocardRectangle(from: rectangles),
                   let image = self.perspectiveCorrector.correctPhotocard(
                    image: normalizedImage,
                    rectangle: rectangle,
                    targetAspectRatio: self.targetAspectRatio,
                    insetRatio: self.postCorrectionInsetRatio,
                    targetSize: self.outputSize
                   ) {
                    correctedImage = image
                } else {
                    correctedImage = normalizedImage
                }

                results.append(
                    ProcessedPhotocardImage(
                        image: correctedImage,
                        sourceIndex: index
                    )
                )

                DispatchQueue.main.async {
                    progress(
                        Double(index + 1) / Double(images.count),
                        L10n.format(.processingComplete, index + 1, images.count)
                    )
                    processNext(index + 1)
                }
            }
        }

        processNext(0)
    }

    private func selectBestPhotocardRectangle(
        from rectangles: [VNRectangleObservation]
    ) -> VNRectangleObservation? {
        return rectangles.max { lhs, rhs in
            score(lhs, targetRatio: targetAspectRatio) < score(rhs, targetRatio: targetAspectRatio)
        }
    }

    private func score(
        _ rectangle: VNRectangleObservation,
        targetRatio: CGFloat
    ) -> CGFloat {
        let boundingBox = rectangle.boundingBox
        let areaScore = polygonArea(rectangle)
        let ratio = averageWidth(rectangle) / max(averageHeight(rectangle), 0.001)
        let ratioScore = max(0, 1 - abs(ratio - targetRatio) / 0.22)
        let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        let centerDistance = hypot(center.x - 0.5, center.y - 0.5)
        let centerScore = max(0, 1 - centerDistance)

        return areaScore * 0.42
            + ratioScore * 0.38
            + CGFloat(rectangle.confidence) * 0.14
            + centerScore * 0.06
    }

    private func averageWidth(_ rectangle: VNRectangleObservation) -> CGFloat {
        (
            distance(rectangle.topLeft, rectangle.topRight)
                + distance(rectangle.bottomLeft, rectangle.bottomRight)
        ) / 2
    }

    private func averageHeight(_ rectangle: VNRectangleObservation) -> CGFloat {
        (
            distance(rectangle.topLeft, rectangle.bottomLeft)
                + distance(rectangle.topRight, rectangle.bottomRight)
        ) / 2
    }

    private func polygonArea(_ rectangle: VNRectangleObservation) -> CGFloat {
        let points = [
            rectangle.topLeft,
            rectangle.topRight,
            rectangle.bottomRight,
            rectangle.bottomLeft
        ]

        let shiftedPoints = Array(points.dropFirst()) + [points[0]]
        let sum = zip(points, shiftedPoints).reduce(CGFloat(0)) { result, pair in
            result + pair.0.x * pair.1.y - pair.1.x * pair.0.y
        }

        return abs(sum) / 2
    }

    private func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}
