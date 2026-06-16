import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// Vision이 검출한 포토카드 영역을
/// 원근 보정(Perspective Correction)하거나
/// 단순 크롭(Crop)하는 객체
final class PhotocardPerspectiveCorrector {

    /// Core Image 렌더링 엔진
    ///
    /// CIFilter가 생성한 CIImage를
    /// 실제 CGImage로 렌더링할 때 사용
    private let context = CIContext()

    /// ============================================================
    /// MARK: - Perspective Correction
    /// ============================================================

    /// Vision이 검출한 사각형을 기준으로
    /// 비스듬한 포토카드를 반듯한 직사각형으로 보정
    /// edgePaddingRatio는 이전 호출부 호환을 위해 남겨두지만 보정에는 사용하지 않는다.
    func correctPerspective(
        image: UIImage,
        rectangle: VNRectangleObservation,
        edgePaddingRatio: CGFloat = 0.035
    ) -> UIImage? {
        perspectiveCorrect(image: image, observation: rectangle)
    }

    /// Vision이 검출한 꼭짓점을 그대로 사용해 원근 보정만 수행한다.
    /// 비율 보정이나 여백 제거는 보정된 이미지에서 별도 후처리한다.
    func perspectiveCorrect(
        image: UIImage,
        observation: VNRectangleObservation
    ) -> UIImage? {

        /// UIImage → CIImage 변환
        ///
        /// Core Image의 필터는 CIImage만 처리 가능
        guard let ciImage = CIImage(image: image) else {
            return nil
        }

        /// 현재 이미지의 실제 영역
        ///
        /// 예:
        /// (0, 0, 866, 1331)
        let imageExtent = ciImage.extent

        // ========================================================
        // Vision 좌표 → CoreImage 좌표 변환
        // ========================================================

        /// Vision은 정규화 좌표(0 ~ 1)를 사용
        ///
        /// 예:
        /// topLeft = (0.12, 0.87)
        ///
        /// Core Image는 실제 픽셀 좌표 사용
        ///
        /// 예:
        /// topLeft = (104, 1158)
        ///
        /// 따라서 변환 필요
        let detectedTopLeft = convert(
            observation.topLeft,
            imageExtent: imageExtent
        )

        let detectedTopRight = convert(
            observation.topRight,
            imageExtent: imageExtent
        )

        let detectedBottomLeft = convert(
            observation.bottomLeft,
            imageExtent: imageExtent
        )

        let detectedBottomRight = convert(
            observation.bottomRight,
            imageExtent: imageExtent
        )

        // ========================================================
        // Perspective Correction 필터 생성
        // ========================================================

        /// 원근 보정 필터
        ///
        /// 비스듬하게 촬영된 사각형을
        /// 정면에서 본 것처럼 펼쳐준다.
        let filter = CIFilter.perspectiveCorrection()

        /// 입력 이미지 설정
        filter.setValue(
            ciImage,
            forKey: kCIInputImageKey
        )

        /// Vision이 찾은 4개의 꼭짓점 전달
        ///
        /// Core Image는 이 정보를 기준으로
        /// 사각형을 직사각형으로 펼친다.
        filter.setValue(
            CIVector(cgPoint: detectedTopLeft),
            forKey: "inputTopLeft"
        )

        filter.setValue(
            CIVector(cgPoint: detectedTopRight),
            forKey: "inputTopRight"
        )

        filter.setValue(
            CIVector(cgPoint: detectedBottomLeft),
            forKey: "inputBottomLeft"
        )

        filter.setValue(
            CIVector(cgPoint: detectedBottomRight),
            forKey: "inputBottomRight"
        )

        /// 필터 결과
        ///
        /// 아직 UIImage가 아니라 CIImage
        guard let outputImage = filter.outputImage else {
            return nil
        }

        /// Core Image 렌더링 수행
        ///
        /// CIImage → CGImage 변환
        guard let cgImage = context.createCGImage(
            outputImage,
            from: outputImage.extent
        ) else {
            return nil
        }

        /// UIKit에서 사용할 UIImage 생성
        return UIImage(cgImage: cgImage)
    }

    /// Vision이 찾은 4개 꼭짓점으로 원근을 먼저 보정한 뒤
    /// 포토카드 기본 비율에 맞춰 결과 이미지를 정리한다.
    func correctPhotocard(
        image: UIImage,
        rectangle: VNRectangleObservation,
        targetAspectRatio: CGFloat = 55.0 / 85.0,
        insetRatio: CGFloat = 0.015,
        targetSize: CGSize? = nil
    ) -> UIImage? {

        guard let correctedImage = perspectiveCorrect(
            image: image,
            observation: rectangle
        ) else {
            return nil
        }

        let insetImage = insetCrop(
            image: correctedImage,
            insetRatio: insetRatio
        ) ?? correctedImage

        let aspectAlignedImage = centerCropToRatio(
            image: insetImage,
            targetRatio: targetAspectRatio
        ) ?? insetImage

        guard let targetSize else {
            return aspectAlignedImage
        }

        return resize(
            image: aspectAlignedImage,
            targetSize: targetSize
        ) ?? aspectAlignedImage
    }

    /// ============================================================
    /// MARK: - Crop
    /// ============================================================

    /// Vision이 찾은 영역을 기준으로
    /// 포토카드를 단순 크롭
    ///
    /// Perspective Correction 없이
    /// 사각형 영역만 잘라낸다.
    func cropPhotocard(
        image: UIImage,
        rectangle: VNRectangleObservation,
        targetAspectRatio: CGFloat = 55.0 / 95.0
    ) -> UIImage? {

        guard let cgImage = image.cgImage else {
            return nil
        }

        let imageSize = CGSize(
            width: cgImage.width,
            height: cgImage.height
        )

        let boundingBox = rectangle.boundingBox

        /// Vision boundingBox는
        /// 정규화 좌표(0~1) 사용
        ///
        /// CGImage는 픽셀 좌표 사용
        ///
        /// 따라서 실제 픽셀 영역으로 변환
        var cropRect = CGRect(
            x: boundingBox.minX * imageSize.width,

            /// Vision 원점:
            /// 왼쪽 아래
            ///
            /// UIKit 원점:
            /// 왼쪽 위
            ///
            /// y축 뒤집기 필요
            y: (1 - boundingBox.maxY) * imageSize.height,

            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )

        let currentAspectRatio =
            cropRect.width / cropRect.height

        /// 포토카드 비율에 맞게
        /// 잘라낼 영역 조정
        if currentAspectRatio > targetAspectRatio {

            let targetWidth =
                cropRect.height * targetAspectRatio

            cropRect.origin.x +=
                (cropRect.width - targetWidth) / 2

            cropRect.size.width = targetWidth

        } else {

            let targetHeight =
                cropRect.width / targetAspectRatio

            cropRect.origin.y +=
                (cropRect.height - targetHeight) / 2

            cropRect.size.height = targetHeight
        }

        /// 이미지 범위를 벗어나지 않도록 보정
        cropRect = cropRect.integral
            .intersection(
                CGRect(
                    origin: .zero,
                    size: imageSize
                )
            )

        guard !cropRect.isNull,
              let croppedImage = cgImage.cropping(
                to: cropRect
              ) else {
            return nil
        }

        return UIImage(
            cgImage: croppedImage,
            scale: image.scale,
            orientation: .up
        )
    }

    func centerCropToRatio(
        image: UIImage,
        targetRatio: CGFloat
    ) -> UIImage? {

        guard let cgImage = image.cgImage else {
            return nil
        }

        guard targetRatio > 0 else {
            return nil
        }

        let imageSize = CGSize(
            width: cgImage.width,
            height: cgImage.height
        )

        var cropRect = CGRect(
            origin: .zero,
            size: imageSize
        )

        let currentAspectRatio =
            cropRect.width / cropRect.height

        if currentAspectRatio > targetRatio {

            let targetWidth =
                cropRect.height * targetRatio

            cropRect.origin.x =
                (cropRect.width - targetWidth) / 2

            cropRect.size.width = targetWidth

        } else {

            let targetHeight =
                cropRect.width / targetRatio

            cropRect.origin.y =
                (cropRect.height - targetHeight) / 2

            cropRect.size.height = targetHeight
        }

        cropRect = cropRect.integral
            .intersection(
                CGRect(
                    origin: .zero,
                    size: imageSize
                )
            )

        guard !cropRect.isNull,
              let croppedImage = cgImage.cropping(
                to: cropRect
              ) else {
            return nil
        }

        return UIImage(
            cgImage: croppedImage,
            scale: image.scale,
            orientation: .up
        )
    }

    func insetCrop(
        image: UIImage,
        insetRatio: CGFloat
    ) -> UIImage? {

        guard let cgImage = image.cgImage else {
            return nil
        }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let insetX = width * max(0, insetRatio)
        let insetY = height * max(0, insetRatio)
        let cropRect = CGRect(
            x: insetX,
            y: insetY,
            width: width - insetX * 2,
            height: height - insetY * 2
        ).integral

        guard cropRect.width > 1,
              cropRect.height > 1,
              let croppedImage = cgImage.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(
            cgImage: croppedImage,
            scale: image.scale,
            orientation: .up
        )
    }

    func resize(
        image: UIImage,
        targetSize: CGSize
    ) -> UIImage? {

        guard targetSize.width > 0,
              targetSize.height > 0 else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(
            size: targetSize,
            format: format
        ).image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: targetSize
                )
            )
        }
    }

    /// ============================================================
    /// MARK: - Coordinate Convert
    /// ============================================================

    /// Vision의 정규화 좌표(0~1)를
    /// Core Image의 실제 픽셀 좌표로 변환
    ///
    /// 예:
    /// (0.5, 0.5)
    ///
    /// →
    ///
    /// (433, 665)
    private func convert(
        _ point: CGPoint,
        imageExtent: CGRect
    ) -> CGPoint {

        CGPoint(
            x: imageExtent.minX +
                point.x * imageExtent.width,

            y: imageExtent.minY +
                point.y * imageExtent.height
        )
    }
}
