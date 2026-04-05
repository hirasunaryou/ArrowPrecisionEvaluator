import SwiftUI

protocol ColorSegmentationServiceProtocol {
    func previewMask(
        image: UIImage,
        preset: ColorPreset,
        parameters: SegmentationParameters
    ) -> UIImage
}

final class ColorSegmentationService: ColorSegmentationServiceProtocol {
    func previewMask(
        image: UIImage,
        preset: ColorPreset,
        parameters: SegmentationParameters
    ) -> UIImage {
        guard
            let result = HSVMarkerSegmentation.analyze(
                image: image,
                preset: preset,
                parameters: parameters
            ),
            let previewImage = HSVMarkerSegmentation.maskPreviewImage(from: result)
        else {
            return image
        }

        return previewImage
    }
}
