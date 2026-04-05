import SwiftUI

final class MeasurementFlowViewModel: ObservableObject {
    @Published var path: [AppScreen] = []
    @Published var draft: MeasurementSessionDraft = .empty
    @Published var settings: AppSettings

    let perspectiveCorrectionService: PerspectiveCorrectionServiceProtocol
    let colorSegmentationService: ColorSegmentationServiceProtocol
    let markerDetectionService: MarkerDetectionServiceProtocol
    let metricsCalculationService: MetricsCalculationServiceProtocol

    init(
        settings: AppSettings,
        perspectiveCorrectionService: PerspectiveCorrectionServiceProtocol = PerspectiveCorrectionService(),
        colorSegmentationService: ColorSegmentationServiceProtocol = ColorSegmentationService(),
        markerDetectionService: MarkerDetectionServiceProtocol = MarkerDetectionService(),
        metricsCalculationService: MetricsCalculationServiceProtocol = MetricsCalculationService()
    ) {
        self.settings = settings
        self.perspectiveCorrectionService = perspectiveCorrectionService
        self.colorSegmentationService = colorSegmentationService
        self.markerDetectionService = markerDetectionService
        self.metricsCalculationService = metricsCalculationService
    }

    func startNewMeasurement() {
        draft = .empty
        path = [.acquisition]
    }

    func goToSettings() {
        path.append(.settings)
    }

    func goToSavedSessions() {
        path.append(.savedSessions)
    }

    func resetToHome() {
        path = []
    }
}
