import Foundation

protocol MeasurementSessionStoreProtocol {
    func loadSessions() throws -> [SavedMeasurementSession]
    func saveSession(_ session: SavedMeasurementSession) throws
    func deleteSession(id: UUID) throws
}

final class MeasurementSessionStore: MeasurementSessionStoreProtocol {
    private let fileManager: FileManager
    private let fileName = "saved_measurement_sessions.json"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadSessions() throws -> [SavedMeasurementSession] {
        let url = try sessionsFileURL()
        guard fileManager.fileExists(atPath: url.path) else { return [] }

        let data = try Data(contentsOf: url)
        let sessions = try JSONDecoder().decode([SavedMeasurementSession].self, from: data)
        return sessions.sorted { $0.createdAt > $1.createdAt }
    }

    func saveSession(_ session: SavedMeasurementSession) throws {
        var sessions = try loadSessions()
        sessions.insert(session, at: 0)
        try writeSessions(sessions)
    }

    func deleteSession(id: UUID) throws {
        var sessions = try loadSessions()
        sessions.removeAll { $0.id == id }
        try writeSessions(sessions)
    }

    private func writeSessions(_ sessions: [SavedMeasurementSession]) throws {
        let data = try JSONEncoder().encode(sessions)
        let url = try sessionsFileURL()
        try data.write(to: url, options: .atomic)
    }

    private func sessionsFileURL() throws -> URL {
        let directory = try appSupportDirectoryURL()
        return directory.appendingPathComponent(fileName)
    }

    private func appSupportDirectoryURL() throws -> URL {
        let url = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
}
