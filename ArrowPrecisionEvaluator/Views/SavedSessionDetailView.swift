import SwiftUI

struct SavedSessionDetailView: View {
    let session: SavedMeasurementSession
    @ObservedObject var viewModel: SavedSessionsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Session") {
                detailRow("Title", session.title)
                detailRow("Created", session.createdAt.formatted(date: .abbreviated, time: .shortened))
                detailRow("Marker Count", "\(session.metrics.markerCount)")
                detailRow("Memo", session.memo.isEmpty ? "-" : session.memo)
            }

            Section("Metrics") {
                detailRow("Mean Distance to Target", formatMm(session.metrics.meanDistanceToTargetMm))
                detailRow("Target to Centroid", formatMm(session.metrics.distanceFromTargetToCentroidMm))
                detailRow("Grouping Diameter", formatMm(session.metrics.groupingDiameterMm))
                detailRow("Max Distance", formatMm(session.metrics.maxDistanceMm))
            }

            Section("Actions") {
                Button("Export Session CSV / Share") {
                    viewModel.exportSingleSessionCSV(session)
                }

                Button(role: .destructive) {
                    viewModel.deleteSession(session)
                    dismiss()
                } label: {
                    Text("Delete Session")
                }
            }
        }
        .navigationTitle("Session Detail")
    }

    private func detailRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
        }
    }

    private func formatMm(_ value: Double) -> String {
        String(format: "%.2f mm", value)
    }
}
