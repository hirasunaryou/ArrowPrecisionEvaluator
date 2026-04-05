import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

protocol PerspectiveCorrectionServiceProtocol {
    func correct(image: UIImage, corners: [CGPoint], outputSize: CGSize) -> UIImage
}

final class PerspectiveCorrectionService: PerspectiveCorrectionServiceProtocol {
    private let context = CIContext(options: nil)

    func correct(image: UIImage, corners: [CGPoint], outputSize: CGSize) -> UIImage {
        guard corners.count == 4 else { return image }
        guard image.size.width > 0, image.size.height > 0 else { return image }
        guard let normalizedInput = normalizedCGImage(from: image) else { return image }

        let sourceWidth = CGFloat(normalizedInput.width)
        let sourceHeight = CGFloat(normalizedInput.height)

        // Calibration points are stored in UIImage-space coordinates. Convert them into
        // normalized pixel coordinates so Core Image can apply a stable projective warp.
        let pixelScaleX = sourceWidth / image.size.width
        let pixelScaleY = sourceHeight / image.size.height

        func toCICoordinate(_ point: CGPoint) -> CGPoint {
            let pixelPoint = CGPoint(x: point.x * pixelScaleX, y: point.y * pixelScaleY)
            // UIKit is top-left origin; Core Image is bottom-left origin.
            return CGPoint(x: pixelPoint.x, y: sourceHeight - pixelPoint.y)
        }

        // Corner order expected by the calibration screen:
        // [top-left, top-right, bottom-right, bottom-left]
        let topLeft = toCICoordinate(corners[0])
        let topRight = toCICoordinate(corners[1])
        let bottomRight = toCICoordinate(corners[2])
        let bottomLeft = toCICoordinate(corners[3])

        let perspectiveFilter = CIFilter.perspectiveCorrection()
        perspectiveFilter.inputImage = CIImage(cgImage: normalizedInput)
        perspectiveFilter.topLeft = topLeft
        perspectiveFilter.topRight = topRight
        perspectiveFilter.bottomRight = bottomRight
        perspectiveFilter.bottomLeft = bottomLeft

        guard let corrected = perspectiveFilter.outputImage else { return image }

        let targetSize = resolvedTargetSize(requestedSize: outputSize, fallbackExtent: corrected.extent)
        let scaled = corrected
            .transformed(by: CGAffineTransform(scaleX: targetSize.width / corrected.extent.width,
                                               y: targetSize.height / corrected.extent.height))
            .cropped(to: CGRect(origin: .zero, size: targetSize))

        guard let cgImage = context.createCGImage(scaled, from: CGRect(origin: .zero, size: targetSize)) else {
            return image
        }

        // Use scale 1 so UIImage.size directly matches corrected pixel coordinates
        // used throughout the flow (target point, markers, mm conversion).
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }

    private func resolvedTargetSize(requestedSize: CGSize, fallbackExtent: CGRect) -> CGSize {
        if requestedSize.width > 0, requestedSize.height > 0 {
            return CGSize(width: requestedSize.width.rounded(), height: requestedSize.height.rounded())
        }
        return CGSize(width: fallbackExtent.width.rounded(), height: fallbackExtent.height.rounded())
    }

    private func normalizedCGImage(from image: UIImage) -> CGImage? {
        let pixelWidth = Int(image.size.width * image.scale)
        let pixelHeight = Int(image.size.height * image.scale)
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pixelWidth, height: pixelHeight))
        let normalized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: CGSize(width: pixelWidth, height: pixelHeight)))
        }

        return normalized.cgImage
    }
}
