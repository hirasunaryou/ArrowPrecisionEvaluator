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
        // MVP skeleton:
        // 後で HSV segmentation の結果画像を返す
        return image
    }
}
