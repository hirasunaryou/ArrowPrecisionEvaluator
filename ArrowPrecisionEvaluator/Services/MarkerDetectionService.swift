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
        guard let result = HSVMarkerSegmentation.analyze(
            image: image,
            preset: preset,
            parameters: parameters
        ) else {
            return []
        }

        return result.components.map { component in
            let xPx = component.centroidX
            let yPx = component.centroidY
            let xMm = calibrationData.map { xPx * $0.mmPerPixelX } ?? xPx
            let yMm = calibrationData.map { yPx * $0.mmPerPixelY } ?? yPx

            return MarkerPoint(
                xPx: xPx,
                yPx: yPx,
                xMm: xMm,
                yMm: yMm,
                areaPx: Double(component.area),
                isManuallyAdded: false
            )
        }
    }
}
