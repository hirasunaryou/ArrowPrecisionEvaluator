import Foundation

protocol MeasurementSessionStoreProtocol {
    func loadSessions() throws -> [SavedMeasurementSession]
    func saveSession(_ session: SavedMeasurementSession) throws
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
        return try JSONDecoder().decode([SavedMeasurementSession].self, from: data)
    }

    func saveSession(_ session: SavedMeasurementSession) throws {
        var sessions = try loadSessions()
        sessions.insert(session, at: 0)

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
