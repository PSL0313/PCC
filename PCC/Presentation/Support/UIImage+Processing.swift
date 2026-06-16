import UIKit

extension UIImage {
    func normalizedForVisionProcessing() -> UIImage {
        guard imageOrientation != .up else {
            return self
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func renderedForOpenCVProcessing() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func applyRoundedMask(cornerRatio: CGFloat = 0.04) -> UIImage {
        let cornerRadius = size.width * cornerRatio
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
            draw(in: rect)
        }
    }
}
