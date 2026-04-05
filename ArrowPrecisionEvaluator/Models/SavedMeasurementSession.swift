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

    static func fromDraft(
        id: UUID = UUID(),
        title: String,
        memo: String,
        createdAt: Date = Date(),
        draft: MeasurementSessionDraft,
        metrics: AnalysisMetrics
    ) -> SavedMeasurementSession {
        SavedMeasurementSession(
            id: id,
            title: title,
            memo: memo,
            createdAt: createdAt,
            selectedColorPreset: draft.selectedColorPreset,
            calibrationData: draft.calibrationData,
            targetPoint: draft.targetPoint,
            markerPoints: draft.finalMarkerPoints,
            metrics: metrics
        )
    }
}
