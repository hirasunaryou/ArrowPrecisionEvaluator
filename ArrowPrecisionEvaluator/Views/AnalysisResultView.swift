import SwiftUI

struct AnalysisResultView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = AnalysisResultViewModel()
    @State private var isSaveSheetPresented = false

    var body: some View {
        List {
            Section("Session") {
                HStack {
                    Text("Title")
                    Spacer()
                    Text(viewModel.sessionTitle.isEmpty ? viewModel.suggestedTitle() : viewModel.sessionTitle)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                if !viewModel.sessionMemo.isEmpty {
                    HStack(alignment: .top) {
                        Text("Memo")
                        Spacer()
                        Text(viewModel.sessionMemo)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Button("Save Session") {
                    isSaveSheetPresented = true
                }

                if let shareCSVURL = viewModel.shareCSVURL {
                    ShareLink(item: shareCSVURL) {
                        Label("Share CSV", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button("Prepare CSV") {
                        viewModel.prepareCSV(from: environment.flowViewModel.draft)
                    }
                }
            }

            Section("Metrics") {
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
        }
        .navigationTitle("Analysis Result")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Back to Home") {
                    environment.flowViewModel.resetToHome()
                }
            }
        }
        .sheet(isPresented: $isSaveSheetPresented) {
            saveSheet
        }
        .alert("Result", isPresented: Binding(
            get: { viewModel.toastMessage != nil },
            set: { newValue in
                if !newValue { viewModel.toastMessage = nil }
            }
        ), actions: {
            Button("OK") {
                viewModel.toastMessage = nil
            }
        }, message: {
            Text(viewModel.toastMessage ?? "")
        })
        .onAppear {
            let draft = environment.flowViewModel.draft
            viewModel.calculate(
                points: draft.finalMarkerPoints,
                target: draft.targetPoint,
                service: environment.flowViewModel.metricsCalculationService
            )
            if viewModel.sessionTitle.isEmpty {
                viewModel.sessionTitle = viewModel.suggestedTitle()
            }
            environment.flowViewModel.draft.metrics = viewModel.metrics
        }
    }

    private var saveSheet: some View {
        NavigationStack {
            Form {
                Section("Save Session") {
                    TextField("Title", text: $viewModel.sessionTitle)
                    TextField("Memo", text: $viewModel.sessionMemo, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Save Result")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isSaveSheetPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveSession(from: environment.flowViewModel.draft)
                        isSaveSheetPresented = false
                    }
                }
            }
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
