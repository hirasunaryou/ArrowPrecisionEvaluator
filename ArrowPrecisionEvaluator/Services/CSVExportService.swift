import Foundation

protocol CSVExportServiceProtocol {
    func export(session: SavedMeasurementSession) throws -> [URL]
}

final class CSVExportService: CSVExportServiceProtocol {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func export(session: SavedMeasurementSession) throws -> [URL] {
        let exportDirectory = try makeExportDirectory(sessionID: session.id)

        let summaryURL = exportDirectory.appendingPathComponent("session_summary.csv")
        let pointsURL = exportDirectory.appendingPathComponent("marker_points.csv")

        try makeSummaryCSV(session: session).write(to: summaryURL, atomically: true, encoding: .utf8)
        try makeMarkerPointsCSV(session: session).write(to: pointsURL, atomically: true, encoding: .utf8)

        return [summaryURL, pointsURL]
    }

    private func makeExportDirectory(sessionID: UUID) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("ArrowPrecisionEvaluator")
            .appendingPathComponent("exports")
            .appendingPathComponent("\(timestamp)_\(sessionID.uuidString)")

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeSummaryCSV(session: SavedMeasurementSession) -> String {
        var rows: [String] = []
        rows.append("field,value")

        rows.append(csvPair("session_id", session.id.uuidString))
        rows.append(csvPair("title", session.title))
        rows.append(csvPair("memo", session.memo))
        rows.append(csvPair("created_at_iso8601", isoString(session.createdAt)))
        rows.append(csvPair("selected_color_preset", session.selectedColorPreset?.rawValue ?? ""))

        rows.append(csvPair("calibration_physical_width_mm", session.calibrationData?.physicalWidthMm))
        rows.append(csvPair("calibration_physical_height_mm", session.calibrationData?.physicalHeightMm))
        rows.append(csvPair("calibration_mm_per_pixel_x", session.calibrationData?.mmPerPixelX))
        rows.append(csvPair("calibration_mm_per_pixel_y", session.calibrationData?.mmPerPixelY))

        rows.append(csvPair("target_x_px", session.targetPoint?.pointPx.x))
        rows.append(csvPair("target_y_px", session.targetPoint?.pointPx.y))
        rows.append(csvPair("target_x_mm", session.targetPoint?.pointMm.x))
        rows.append(csvPair("target_y_mm", session.targetPoint?.pointMm.y))
        rows.append(csvPair("target_uses_center", session.targetPoint?.usesCenter))

        rows.append(csvPair("marker_count", session.metrics.markerCount))
        rows.append(csvPair("centroid_x_mm", session.metrics.centroidXMm))
        rows.append(csvPair("centroid_y_mm", session.metrics.centroidYMm))
        rows.append(csvPair("mean_distance_to_target_mm", session.metrics.meanDistanceToTargetMm))
        rows.append(csvPair("target_to_centroid_mm", session.metrics.distanceFromTargetToCentroidMm))
        rows.append(csvPair("stddev_x_mm", session.metrics.stdDevXMm))
        rows.append(csvPair("stddev_y_mm", session.metrics.stdDevYMm))
        rows.append(csvPair("max_distance_mm", session.metrics.maxDistanceMm))
        rows.append(csvPair("grouping_diameter_mm", session.metrics.groupingDiameterMm))
        rows.append(csvPair("average_radius_mm", session.metrics.averageRadiusMm))

        return rows.joined(separator: "\n")
    }

    private func makeMarkerPointsCSV(session: SavedMeasurementSession) -> String {
        var rows: [String] = []
        rows.append("session_id,marker_index,marker_id,x_px,y_px,x_mm,y_mm,area_px,is_manually_added")

        for (index, point) in session.markerPoints.enumerated() {
            rows.append(
                [
                    csvCell(session.id.uuidString),
                    csvCell(index),
                    csvCell(point.id.uuidString),
                    csvCell(point.xPx),
                    csvCell(point.yPx),
                    csvCell(point.xMm),
                    csvCell(point.yMm),
                    csvCell(point.areaPx),
                    csvCell(point.isManuallyAdded)
                ].joined(separator: ",")
            )
        }

        if session.markerPoints.isEmpty {
            rows.append([csvCell(session.id.uuidString), "", "", "", "", "", "", "", ""].joined(separator: ","))
        }

        return rows.joined(separator: "\n")
    }

    private func csvPair(_ key: String, _ value: String) -> String {
        "\(csvCell(key)),\(csvCell(value))"
    }

    private func csvPair<T>(_ key: String, _ value: T?) -> String {
        guard let value else {
            return csvPair(key, "")
        }
        return csvPair(key, String(describing: value))
    }

    private func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func csvCell<T>(_ value: T) -> String {
        csvCell(String(describing: value))
    }

    private func csvCell(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
