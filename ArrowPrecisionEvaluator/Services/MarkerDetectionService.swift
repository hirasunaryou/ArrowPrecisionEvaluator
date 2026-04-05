import Foundation
import SwiftUI

protocol MarkerDetectionServiceProtocol {
    func detectMarkers(
        from image: UIImage,
        preset: ColorPreset,
        parameters: SegmentationParameters,
        calibrationData: CalibrationData?
    ) -> [MarkerPoint]
}

final class MarkerDetectionService: MarkerDetectionServiceProtocol {
    func detectMarkers(
        from image: UIImage,
        preset: ColorPreset,
        parameters: SegmentationParameters,
        calibrationData: CalibrationData?
    ) -> [MarkerPoint] {
        // Manual-first MVP behavior:
        // No fake detections are injected so real-photo measurements are not polluted.
        // Users can proceed to manual review and place markers themselves.
        return []
    }
}
