import SwiftUI

struct ColorSegmentationPreviewAnalysis {
    let previewImage: UIImage
    let componentAreas: [Int]
}

protocol ColorSegmentationServiceProtocol {
    func previewAnalysis(
        image: UIImage,
        preset: ColorPreset,
        sensitivity: Double
    ) -> ColorSegmentationPreviewAnalysis?
}

final class ColorSegmentationService: ColorSegmentationServiceProtocol {
    private let previewMaxDimension: CGFloat = 640

    func previewAnalysis(
        image: UIImage,
        preset: ColorPreset,
        sensitivity: Double
    ) -> ColorSegmentationPreviewAnalysis? {
        // Preview is intentionally downscaled to reduce per-update CPU cost on iPhone.
        let previewSource = downscaledImageIfNeeded(image)
        let parameters = SegmentationParameters(sensitivity: sensitivity, minimumArea: 1)

        guard
            let result = HSVMarkerSegmentation.analyze(
                image: previewSource,
                preset: preset,
                parameters: parameters
            ),
            let previewImage = HSVMarkerSegmentation.maskPreviewImage(from: result)
        else {
            return nil
        }

        return ColorSegmentationPreviewAnalysis(
            previewImage: previewImage,
            componentAreas: result.components.map(\.area)
        )
    }

    private func downscaledImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxInputDimension = max(image.size.width, image.size.height)
        guard maxInputDimension > previewMaxDimension else { return image }

        let scale = previewMaxDimension / maxInputDimension
        let targetSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
