import SwiftUI

struct AnalysisResultView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = AnalysisResultViewModel()

    var body: some View {
        List {
            metricRow("Marker Count", "\(viewModel.metrics.markerCount)")
            metricRow("Centroid X", formatMm(viewModel.metrics.centroidXMm))
            metricRow("Centroid Y", formatMm(viewModel.metrics.centroidYMm))
            metricRow("Mean Distance to Target", formatMm(viewModel.metrics.meanDistanceToTargetMm))
            metricRow("Target to Centroid", formatMm(viewModel.metrics.distanceFromTargetToCentroidMm))
            metricRow("StdDev X", formatMm(viewModel.metrics.stdDevXMm))
            metricRow("StdDev Y", formatMm(viewModel.metrics.stdDevYMm))
            metricRow("Max Distance", formatMm(viewModel.metrics.maxDistanceMm))
            metricRow("Grouping Diameter", formatMm(viewModel.metrics.groupingDiameterMm))
            metricRow("Average Radius", formatMm(viewModel.metrics.averageRadiusMm))
        }
        .navigationTitle("Analysis Result")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Back to Home") {
                    environment.flowViewModel.resetToHome()
                }
            }
        }
        .onAppear {
            let draft = environment.flowViewModel.draft
            viewModel.calculate(
                points: draft.finalMarkerPoints,
                target: draft.targetPoint,
                service: environment.flowViewModel.metricsCalculationService
            )
            environment.flowViewModel.draft.metrics = viewModel.metrics
        }
    }

    private func metricRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func formatMm(_ value: Double) -> String {
        String(format: "%.2f mm", value)
    }
}
