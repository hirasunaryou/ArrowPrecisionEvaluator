import Foundation

final class AnalysisResultViewModel: ObservableObject {
    @Published var metrics: AnalysisMetrics = .empty

    func calculate(
        points: [MarkerPoint],
        target: TargetPoint?,
        service: MetricsCalculationServiceProtocol
    ) {
        metrics = service.calculate(points: points, target: target)
    }
}
