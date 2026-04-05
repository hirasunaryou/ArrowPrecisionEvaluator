import Foundation

protocol MeasurementSessionStoreProtocol {
    func loadSessions() -> [SavedMeasurementSession]
    @discardableResult
    func saveSession(_ session: SavedMeasurementSession) throws -> URL
}

enum MeasurementSessionStoreError: LocalizedError {
    case failedToCreateDirectory

    var errorDescription: String? {
        switch self {
        case .failedToCreateDirectory:
            return "Could not create session storage directory."
        }
    }
}

final class MeasurementSessionStore: MeasurementSessionStoreProtocol {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func loadSessions() -> [SavedMeasurementSession] {
        guard let data = try? Data(contentsOf: storageFileURL()) else { return [] }
        return (try? decoder.decode([SavedMeasurementSession].self, from: data)) ?? []
    }

    @discardableResult
    func saveSession(_ session: SavedMeasurementSession) throws -> URL {
        let directoryURL = try sessionsDirectoryURL()
        let storageURL = storageFileURL()

        var sessions = loadSessions()
        sessions.insert(session, at: 0)

        let data = try encoder.encode(sessions)
        do {
            try data.write(to: storageURL, options: .atomic)
        } catch {
            if !fileManager.fileExists(atPath: directoryURL.path) {
                throw MeasurementSessionStoreError.failedToCreateDirectory
            }
            throw error
        }

        return storageURL
    }

    private func sessionsDirectoryURL() throws -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ??
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directoryURL = baseURL.appendingPathComponent("MeasurementSessions", isDirectory: true)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                throw MeasurementSessionStoreError.failedToCreateDirectory
            }
        }

        return directoryURL
    }

    private func storageFileURL() -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ??
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return baseURL
            .appendingPathComponent("MeasurementSessions", isDirectory: true)
            .appendingPathComponent("saved_sessions.json")
    }
}
