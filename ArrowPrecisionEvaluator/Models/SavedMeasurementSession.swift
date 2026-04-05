import Foundation

struct SavedMeasurementSession: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var memo: String
    var createdAt: Date
    var selectedColorPreset: ColorPreset?
    var calibrationData: CalibrationData?
    var targetPoint: TargetPoint?
    var markerPoints: [MarkerPoint]
    var metrics: AnalysisMetrics

    init(
        id: UUID = UUID(),
        title: String,
        memo: String,
        createdAt: Date = Date(),
        selectedColorPreset: ColorPreset?,
        calibrationData: CalibrationData?,
        targetPoint: TargetPoint?,
        markerPoints: [MarkerPoint],
        metrics: AnalysisMetrics
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.createdAt = createdAt
        self.selectedColorPreset = selectedColorPreset
        self.calibrationData = calibrationData
        self.targetPoint = targetPoint
        self.markerPoints = markerPoints
        self.metrics = metrics
    }

    static func from(
        draft: MeasurementSessionDraft,
        title: String,
        memo: String,
        metrics: AnalysisMetrics
    ) -> SavedMeasurementSession {
        SavedMeasurementSession(
            title: title,
            memo: memo,
            selectedColorPreset: draft.selectedColorPreset,
            calibrationData: draft.calibrationData,
            targetPoint: draft.targetPoint,
            markerPoints: draft.finalMarkerPoints,
            metrics: metrics
        )
    }
}
