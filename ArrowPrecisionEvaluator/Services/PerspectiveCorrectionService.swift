import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

protocol PerspectiveCorrectionServiceProtocol {
    func correct(image: UIImage, corners: [CGPoint], outputSize: CGSize) -> UIImage
}

final class PerspectiveCorrectionService: PerspectiveCorrectionServiceProtocol {
    private let context = CIContext(options: nil)

    func correct(image: UIImage, corners: [CGPoint], outputSize: CGSize) -> UIImage {
        guard
            corners.count == 4,
            let ciInput = CIImage(image: image)
        else {
            return image
        }

        // Core Image coordinates use a bottom-left origin while UIKit uses top-left.
        // The calibration UI stores points in UIKit image space, so we flip Y here.
        func toCIVectorPoint(_ point: CGPoint, imageHeight: CGFloat) -> CGPoint {
            CGPoint(x: point.x, y: imageHeight - point.y)
        }

        // Corner order from CalibrationViewModel: top-left, top-right, bottom-right, bottom-left.
        let topLeft = toCIVectorPoint(corners[0], imageHeight: image.size.height)
        let topRight = toCIVectorPoint(corners[1], imageHeight: image.size.height)
        let bottomRight = toCIVectorPoint(corners[2], imageHeight: image.size.height)
        let bottomLeft = toCIVectorPoint(corners[3], imageHeight: image.size.height)

        let perspectiveFilter = CIFilter.perspectiveCorrection()
        perspectiveFilter.inputImage = ciInput
        perspectiveFilter.topLeft = CGPoint(x: topLeft.x, y: topLeft.y)
        perspectiveFilter.topRight = CGPoint(x: topRight.x, y: topRight.y)
        perspectiveFilter.bottomRight = CGPoint(x: bottomRight.x, y: bottomRight.y)
        perspectiveFilter.bottomLeft = CGPoint(x: bottomLeft.x, y: bottomLeft.y)

        guard let corrected = perspectiveFilter.outputImage else {
            return image
        }

        // Guarantee a predictable rectangular output size for downstream screens.
        guard outputSize.width > 0, outputSize.height > 0 else {
            guard let cgFallback = context.createCGImage(corrected, from: corrected.extent) else {
                return image
            }
            return UIImage(cgImage: cgFallback, scale: image.scale, orientation: image.imageOrientation)
        }

        let sx = outputSize.width / corrected.extent.width
        let sy = outputSize.height / corrected.extent.height
        let scaled = corrected
            .transformed(by: CGAffineTransform(scaleX: sx, y: sy))
            .cropped(to: CGRect(origin: .zero, size: outputSize))

        guard let cgImage = context.createCGImage(scaled, from: CGRect(origin: .zero, size: outputSize)) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
