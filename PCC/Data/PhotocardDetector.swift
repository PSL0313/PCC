import UIKit
import Vision

/// 이미지 속 사각형을 탐지하는 객체
///
/// Vision 프레임워크의
/// VNDetectRectanglesRequest를 사용한다.
final class PhotocardDetector {

    /// 이미지 속 사각형 탐지
    ///
    /// Parameters:
    ///   - image: 탐지할 원본 이미지
    ///   - completion:
    ///     탐지된 사각형 목록 반환
    ///
    /// Returns:
    /// [VNRectangleObservation]
    func detectRectangles(
        from image: UIImage,
        completion: @escaping ([VNRectangleObservation]) -> Void
    ) {

        // ========================================================
        // UIImage → CGImage 변환
        // ========================================================

        /// Vision은 보통 CGImage를 사용하여 분석한다.
        guard let cgImage = image.cgImage else {
            completion([])
            print("CGImage 생성 실패")
            return
        }

        // Rectangle Request 생성
        let request = VNDetectRectanglesRequest { request, error in

            // 탐지 실패
            if let error {

                print("사각형 탐지 실패:", error)

                completion([])
                return
            }

            // 탐지 결과 획득
            let rectangles =
                request.results as?
                [VNRectangleObservation]
                ?? []
            print("탐지된 사각형 개수:", rectangles.count)
            completion(rectangles)
        }

        // ========================================================
        // 탐지 옵션
        // ========================================================

        /// 최대 탐지 개수
        ///
        /// 가장 신뢰도가 높은
        /// 후보만 반환
        request.maximumObservations = 12

        /// 최소 크기
        ///
        /// 이미지 전체의
        /// 10% 이상 크기의 사각형만 탐지
        ///
        /// 예:
        /// 아주 작은 카드 무시
        request.minimumSize = 0.10

        /// 최소 가로세로 비율
        ///
        /// width / height
        ///
        /// 0.55 미만이면 무시
        request.minimumAspectRatio = 0.50

        /// 최대 가로세로 비율
        ///
        /// width / height
        ///
        /// 0.75 초과면 무시
        request.maximumAspectRatio = 0.82

        /// 최소 신뢰도
        ///
        /// Vision이
        ///
        /// "이건 사각형일 확률이 높음"
        ///
        /// 이라고 판단한 경우만 반환
        request.minimumConfidence = 0.20

        request.quadratureTolerance = 30
        // ========================================================
        // Handler 생성
        // ========================================================

        /// Vision 분석 실행기
        ///
        /// 어떤 이미지를 분석할지 지정
        let handler =
            VNImageRequestHandler(
                cgImage: cgImage
            )

        // ========================================================
        // Vision 실행
        // ========================================================

        DispatchQueue.global(
            qos: .userInitiated
        ).async {

            do {

                /// 실제 분석 수행
                ///
                /// request 내부의 결과가
                /// 자동으로 채워진다.
                try handler.perform([
                    request
                ])

            } catch {

                print(
                    "Vision 실행 실패:",
                    error
                )

                completion([])
            }
        }
    }
}
