import Foundation

final class AnalysisResultViewModel: ObservableObject {
    struct AlertMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published var metrics: AnalysisMetrics = .empty
    @Published var saveTitle: String = ""
    @Published var saveMemo: String = ""
    @Published var isSaveSheetPresented: Bool = false
    @Published var isShareSheetPresented: Bool = false
    @Published var shareURLs: [URL] = []
    @Published var alertMessage: AlertMessage?

    private let sessionStore: MeasurementSessionStoreProtocol
    private let csvExportService: CSVExportServiceProtocol

    init(
        sessionStore: MeasurementSessionStoreProtocol = MeasurementSessionStore(),
        csvExportService: CSVExportServiceProtocol = CSVExportService()
    ) {
        self.sessionStore = sessionStore
        self.csvExportService = csvExportService
    }

    func calculate(
        points: [MarkerPoint],
        target: TargetPoint?,
        service: MetricsCalculationServiceProtocol
    ) {
        metrics = service.calculate(points: points, target: target)
    }

    func prepareSaveFormIfNeeded() {
        guard saveTitle.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        saveTitle = "Session \(formatter.string(from: Date()))"
    }

    func saveCurrentSession(draft: MeasurementSessionDraft) {
        let normalizedTitle = saveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            alertMessage = AlertMessage(title: "Error", message: "Please enter a session title.")
            return
        }

        let session = SavedMeasurementSession.from(
            draft: draft,
            title: normalizedTitle,
            memo: saveMemo.trimmingCharacters(in: .whitespacesAndNewlines),
            metrics: metrics
        )

        do {
            try sessionStore.saveSession(session)
            alertMessage = AlertMessage(title: "Saved", message: "Session saved locally.")
            isSaveSheetPresented = false
        } catch {
            alertMessage = AlertMessage(title: "Error", message: "Failed to save session: \(error.localizedDescription)")
        }
    }

    func exportCurrentSessionCSV(draft: MeasurementSessionDraft) {
        let fallbackTitle: String
        if saveTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fallbackTitle = "Untitled Session"
        } else {
            fallbackTitle = saveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let session = SavedMeasurementSession.from(
            draft: draft,
            title: fallbackTitle,
            memo: saveMemo.trimmingCharacters(in: .whitespacesAndNewlines),
            metrics: metrics
        )

        do {
            shareURLs = try csvExportService.export(session: session)
            isShareSheetPresented = true
            alertMessage = AlertMessage(title: "CSV Ready", message: "CSV files are ready to share.")
        } catch {
            alertMessage = AlertMessage(title: "Error", message: "Failed to export CSV: \(error.localizedDescription)")
        }
    }
}
