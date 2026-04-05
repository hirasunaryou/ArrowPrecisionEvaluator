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
        // MVP skeleton:
        // 後で二値化 + 連結成分 + 重心計算へ差し替える
        return SampleDataFactory.makeSampleMarkerPoints()
    }
}
