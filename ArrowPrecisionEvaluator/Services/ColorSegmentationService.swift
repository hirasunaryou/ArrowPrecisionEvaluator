import SwiftUI

struct ColorSegmentationPreviewAnalysis {
    let previewImage: UIImage
    let componentAreas: [Int]
}

protocol ColorSegmentationServiceProtocol {
    func previewAnalysis(
        image: UIImage,
        preset: ColorPreset,
        sensitivity: Double,
        minimumArea: Double
    ) -> ColorSegmentationPreviewAnalysis?
}

final class ColorSegmentationService: ColorSegmentationServiceProtocol {
    private let previewMaxDimension: CGFloat = 640

    func previewAnalysis(
        image: UIImage,
        preset: ColorPreset,
        sensitivity: Double,
        minimumArea: Double
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
            let basePreviewImage = HSVMarkerSegmentation.maskPreviewImage(from: result)
        else {
            return nil
        }

        let previewImage = annotatedPreviewImage(
            basePreviewImage: basePreviewImage,
            components: result.components,
            minimumArea: minimumArea,
            canvasSize: CGSize(width: result.width, height: result.height)
        )

        return ColorSegmentationPreviewAnalysis(
            previewImage: previewImage,
            componentAreas: result.components.map(\.area)
        )
    }

    private func annotatedPreviewImage(
        basePreviewImage: UIImage,
        components: [HSVMarkerSegmentation.Component],
        minimumArea: Double,
        canvasSize: CGSize
    ) -> UIImage {
        let minArea = max(1, Int(minimumArea.rounded()))
        let passingComponents = components.filter { $0.area >= minArea }
        let renderer = UIGraphicsImageRenderer(size: canvasSize)

        return renderer.image { _ in
            basePreviewImage.draw(in: CGRect(origin: .zero, size: canvasSize))

            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.setStrokeColor(UIColor.systemYellow.cgColor)
            context.setLineWidth(2)

            // Draw candidate centroids that pass minimumArea so preview visibly reflects this value.
            for component in passingComponents {
                let center = CGPoint(x: component.centroidX, y: component.centroidY)
                context.strokeEllipse(in: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12))
            }
        }
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
