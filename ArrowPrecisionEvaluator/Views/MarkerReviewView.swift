import SwiftUI

struct MarkerReviewView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = MarkerReviewViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Detected Markers: \(viewModel.markerPoints.count)")
                .font(.headline)

            List {
                ForEach(viewModel.markerPoints) { point in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("x: \(point.xMm, specifier: "%.1f") mm")
                            Text("y: \(point.yMm, specifier: "%.1f") mm")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if point.isManuallyAdded {
                            Text("Manual")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Button("Delete") {
                            viewModel.removeMarker(id: point.id)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            Button("Add Sample Manual Point") {
                viewModel.addMarker(xMm: 75, yMm: 55)
            }
            .buttonStyle(.bordered)

            Button("Confirm Final Markers") {
                environment.flowViewModel.draft.finalMarkerPoints = viewModel.markerPoints
                environment.flowViewModel.path.append(.analysis)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Marker Review")
        .onAppear {
            viewModel.markerPoints = environment.flowViewModel.draft.candidateMarkerPoints
        }
    }
}
