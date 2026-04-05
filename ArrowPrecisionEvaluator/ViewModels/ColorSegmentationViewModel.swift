import SwiftUI

final class ColorSegmentationViewModel: ObservableObject {
    @Published var selectedColorPreset: ColorPreset = .red
    @Published var sensitivity: Double = 0.5
    @Published var minimumArea: Double = 30
    @Published var previewImage: UIImage?

    func currentParameters() -> SegmentationParameters {
        SegmentationParameters(
            sensitivity: sensitivity,
            minimumArea: minimumArea
        )
    }
}
