import Foundation

protocol MetricsCalculationServiceProtocol {
    func calculate(points: [MarkerPoint], target: TargetPoint?) -> AnalysisMetrics
}

final class MetricsCalculationService: MetricsCalculationServiceProtocol {
    func calculate(points: [MarkerPoint], target: TargetPoint?) -> AnalysisMetrics {
        guard !points.isEmpty else { return .empty }

        let count = points.count
        let xs = points.map(\.xMm)
        let ys = points.map(\.yMm)

        let centroidX = xs.reduce(0, +) / Double(count)
        let centroidY = ys.reduce(0, +) / Double(count)

        let targetX = target?.pointMm.x ?? 0
        let targetY = target?.pointMm.y ?? 0

        let distancesToTarget = points.map { point in
            hypot(point.xMm - targetX, point.yMm - targetY)
        }

        let meanDistanceToTarget = distancesToTarget.reduce(0, +) / Double(count)
        let maxDistance = distancesToTarget.max() ?? 0

        let distanceFromTargetToCentroid = hypot(centroidX - targetX, centroidY - targetY)

        let stdX = standardDeviation(values: xs)
        let stdY = standardDeviation(values: ys)

        let radiiFromCentroid = points.map { point in
            hypot(point.xMm - centroidX, point.yMm - centroidY)
        }

        let avgRadius = radiiFromCentroid.reduce(0, +) / Double(count)
        let groupingDiameter = (radiiFromCentroid.max() ?? 0) * 2.0

        return AnalysisMetrics(
            markerCount: count,
            centroidXMm: centroidX,
            centroidYMm: centroidY,
            meanDistanceToTargetMm: meanDistanceToTarget,
            distanceFromTargetToCentroidMm: distanceFromTargetToCentroid,
            stdDevXMm: stdX,
            stdDevYMm: stdY,
            maxDistanceMm: maxDistance,
            groupingDiameterMm: groupingDiameter,
            averageRadiusMm: avgRadius
        )
    }

    private func standardDeviation(values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}
