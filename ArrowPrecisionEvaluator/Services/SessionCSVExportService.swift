import Foundation

protocol SessionCSVExportServiceProtocol {
    func createCSVFile(for session: SavedMeasurementSession) throws -> URL
}

final class SessionCSVExportService: SessionCSVExportServiceProtocol {
    private let fileManager: FileManager
    private let isoFormatter = ISO8601DateFormatter()
    private let filenameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createCSVFile(for session: SavedMeasurementSession) throws -> URL {
        let csv = buildCSV(for: session)
        let fileName = "measurement_session_\(filenameFormatter.string(from: session.createdAt)).csv"
        let url = fileManager.temporaryDirectory.appendingPathComponent(fileName)

        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func buildCSV(for session: SavedMeasurementSession) -> String {
        var lines: [String] = []
        lines.append([
            "session_id", "title", "memo", "created_at", "color_preset",
            "calibration_width_mm", "calibration_height_mm", "mm_per_pixel_x", "mm_per_pixel_y",
            "target_x_px", "target_y_px", "target_x_mm", "target_y_mm", "target_uses_center",
            "marker_count", "centroid_x_mm", "centroid_y_mm", "mean_distance_to_target_mm",
            "target_to_centroid_mm", "stddev_x_mm", "stddev_y_mm", "max_distance_mm",
            "grouping_diameter_mm", "average_radius_mm",
            "marker_index", "marker_id", "marker_x_px", "marker_y_px", "marker_x_mm", "marker_y_mm", "marker_area_px", "marker_is_manual"
        ].joined(separator: ","))

        if session.markerPoints.isEmpty {
            lines.append(makeRow(session: session, markerIndex: nil, marker: nil))
        } else {
            for (index, marker) in session.markerPoints.enumerated() {
                lines.append(makeRow(session: session, markerIndex: index, marker: marker))
            }
        }

        return lines.joined(separator: "\n")
    }

    private func makeRow(session: SavedMeasurementSession, markerIndex: Int?, marker: MarkerPoint?) -> String {
        let calibration = session.calibrationData
        let target = session.targetPoint
        let metrics = session.metrics

        let fields: [String] = [
            session.id.uuidString,
            session.title,
            session.memo,
            isoFormatter.string(from: session.createdAt),
            session.selectedColorPreset?.rawValue ?? "",
            optionalDouble(calibration?.physicalWidthMm),
            optionalDouble(calibration?.physicalHeightMm),
            optionalDouble(calibration?.mmPerPixelX),
            optionalDouble(calibration?.mmPerPixelY),
            optionalDouble(target?.pointPx.x),
            optionalDouble(target?.pointPx.y),
            optionalDouble(target?.pointMm.x),
            optionalDouble(target?.pointMm.y),
            target.map { String($0.usesCenter) } ?? "",
            String(metrics.markerCount),
            String(metrics.centroidXMm),
            String(metrics.centroidYMm),
            String(metrics.meanDistanceToTargetMm),
            String(metrics.distanceFromTargetToCentroidMm),
            String(metrics.stdDevXMm),
            String(metrics.stdDevYMm),
            String(metrics.maxDistanceMm),
            String(metrics.groupingDiameterMm),
            String(metrics.averageRadiusMm),
            markerIndex.map(String.init) ?? "",
            marker?.id.uuidString ?? "",
            optionalDouble(marker?.xPx),
            optionalDouble(marker?.yPx),
            optionalDouble(marker?.xMm),
            optionalDouble(marker?.yMm),
            optionalDouble(marker?.areaPx),
            marker.map { String($0.isManuallyAdded) } ?? ""
        ]

        return fields.map(escapeCSV).joined(separator: ",")
    }

    private func optionalDouble(_ value: Double?) -> String {
        value.map(String.init) ?? ""
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\n") || value.contains("\"") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
