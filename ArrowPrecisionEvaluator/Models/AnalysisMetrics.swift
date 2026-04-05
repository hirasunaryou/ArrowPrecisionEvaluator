import Foundation

struct AnalysisMetrics: Codable, Hashable {
    var markerCount: Int
    var centroidXMm: Double
    var centroidYMm: Double
    var meanDistanceToTargetMm: Double
    var distanceFromTargetToCentroidMm: Double
    var stdDevXMm: Double
    var stdDevYMm: Double
    var maxDistanceMm: Double
    var groupingDiameterMm: Double
    var averageRadiusMm: Double

    static let empty = AnalysisMetrics(
        markerCount: 0,
        centroidXMm: 0,
        centroidYMm: 0,
        meanDistanceToTargetMm: 0,
        distanceFromTargetToCentroidMm: 0,
        stdDevXMm: 0,
        stdDevYMm: 0,
        maxDistanceMm: 0,
        groupingDiameterMm: 0,
        averageRadiusMm: 0
    )
}
