import SwiftUI

struct SavedSessionsView: View {
    @StateObject private var viewModel = SavedSessionsViewModel()

    var body: some View {
        Group {
            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "No Saved Sessions",
                    systemImage: "tray",
                    description: Text("Save a measurement session from Analysis Result to build your history.")
                )
            } else {
                List {
                    ForEach(viewModel.sessions) { session in
                        NavigationLink {
                            SavedSessionDetailView(session: session, viewModel: viewModel)
                        } label: {
                            sessionRow(session)
                        }
                    }
                    .onDelete(perform: viewModel.deleteSessions)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Saved Sessions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Export All CSV") {
                    viewModel.exportAllSessionsCSV()
                }
                .disabled(viewModel.sessions.isEmpty)
            }
        }
        .onAppear {
            viewModel.loadSessions()
        }
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            ShareSheet(activityItems: viewModel.shareURLs)
        }
        .alert(item: $viewModel.alertMessage) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }

    private func sessionRow(_ session: SavedMeasurementSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.title)
                .font(.headline)

            if !session.memo.isEmpty {
                Text(session.memo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                metricPill("Markers", "\(session.metrics.markerCount)")
                metricPill("Mean", formatMm(session.metrics.meanDistanceToTargetMm))
                metricPill("Group", formatMm(session.metrics.groupingDiameterMm))
            }
        }
        .padding(.vertical, 4)
    }

    private func metricPill(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    private func formatMm(_ value: Double) -> String {
        String(format: "%.2fmm", value)
    }
}
