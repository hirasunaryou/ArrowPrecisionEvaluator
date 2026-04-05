import Foundation

final class AnalysisResultViewModel: ObservableObject {
    @Published var metrics: AnalysisMetrics = .empty
    @Published var sessionTitle: String = ""
    @Published var sessionMemo: String = ""
    @Published var shareCSVURL: URL?
    @Published var toastMessage: String?

    let createdAt: Date

    private let sessionStore: MeasurementSessionStoreProtocol
    private let csvExportService: SessionCSVExportServiceProtocol

    init(
        sessionStore: MeasurementSessionStoreProtocol = MeasurementSessionStore(),
        csvExportService: SessionCSVExportServiceProtocol = SessionCSVExportService(),
        createdAt: Date = Date()
    ) {
        self.sessionStore = sessionStore
        self.csvExportService = csvExportService
        self.createdAt = createdAt
    }

    func calculate(
        points: [MarkerPoint],
        target: TargetPoint?,
        service: MetricsCalculationServiceProtocol
    ) {
        metrics = service.calculate(points: points, target: target)
    }

    func suggestedTitle() -> String {
        "Session \(createdAt.formatted(date: .abbreviated, time: .shortened))"
    }

    func saveSession(from draft: MeasurementSessionDraft) {
        let normalizedTitle = sessionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = normalizedTitle.isEmpty ? suggestedTitle() : normalizedTitle

        let session = SavedMeasurementSession.fromDraft(
            title: finalTitle,
            memo: sessionMemo,
            createdAt: createdAt,
            draft: draft,
            metrics: metrics
        )

        do {
            try sessionStore.saveSession(session)
            sessionTitle = finalTitle
            toastMessage = "Saved locally"
        } catch {
            toastMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func prepareCSV(from draft: MeasurementSessionDraft) {
        let normalizedTitle = sessionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = normalizedTitle.isEmpty ? suggestedTitle() : normalizedTitle

        let session = SavedMeasurementSession.fromDraft(
            title: finalTitle,
            memo: sessionMemo,
            createdAt: createdAt,
            draft: draft,
            metrics: metrics
        )

        do {
            shareCSVURL = try csvExportService.createCSVFile(for: session)
            sessionTitle = finalTitle
            toastMessage = "CSV prepared"
        } catch {
            toastMessage = "CSV export failed: \(error.localizedDescription)"
        }
    }
}
