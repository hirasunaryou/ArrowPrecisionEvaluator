import SwiftUI

struct MeasurementSessionDraft {
    var originalImage: UIImage?
    var correctedImage: UIImage?
    var calibrationData: CalibrationData?
    var targetPoint: TargetPoint?
    var selectedColorPreset: ColorPreset?
    var segmentationParameters: SegmentationParameters = .default
    var candidateMarkerPoints: [MarkerPoint] = []
    var finalMarkerPoints: [MarkerPoint] = []
    var metrics: AnalysisMetrics?

    static let empty = MeasurementSessionDraft()
}
