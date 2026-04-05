import Foundation

final class SavedSessionsViewModel: ObservableObject {
    struct AlertMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Published var sessions: [SavedMeasurementSession] = []
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

    func loadSessions() {
        do {
            sessions = try sessionStore.loadSessions()
        } catch {
            alertMessage = AlertMessage(title: "Error", message: "Failed to load saved sessions: \(error.localizedDescription)")
        }
    }

    func deleteSessions(at offsets: IndexSet) {
        let ids = offsets.map { sessions[$0].id }

        do {
            for id in ids {
                try sessionStore.deleteSession(id: id)
            }
            sessions.remove(atOffsets: offsets)
        } catch {
            alertMessage = AlertMessage(title: "Error", message: "Failed to delete session: \(error.localizedDescription)")
            loadSessions()
        }
    }

    func exportAllSessionsCSV() {
        guard !sessions.isEmpty else {
            alertMessage = AlertMessage(title: "No Sessions", message: "Save at least one session before exporting.")
            return
        }

        do {
            shareURLs = try csvExportService.exportAll(sessions: sessions)
            isShareSheetPresented = true
            alertMessage = AlertMessage(title: "CSV Ready", message: "Bulk CSV files are ready to share.")
        } catch {
            alertMessage = AlertMessage(title: "Error", message: "Failed to export bulk CSV: \(error.localizedDescription)")
        }
    }

    func exportSingleSessionCSV(_ session: SavedMeasurementSession) {
        do {
            shareURLs = try csvExportService.export(session: session)
            isShareSheetPresented = true
            alertMessage = AlertMessage(title: "CSV Ready", message: "Session CSV files are ready to share.")
        } catch {
            alertMessage = AlertMessage(title: "Error", message: "Failed to export CSV: \(error.localizedDescription)")
        }
    }

    func deleteSession(_ session: SavedMeasurementSession) {
        do {
            try sessionStore.deleteSession(id: session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            alertMessage = AlertMessage(title: "Error", message: "Failed to delete session: \(error.localizedDescription)")
            loadSessions()
        }
    }
}
