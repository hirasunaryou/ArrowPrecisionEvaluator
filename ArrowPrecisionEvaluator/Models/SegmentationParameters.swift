import Foundation

struct SegmentationParameters: Codable, Hashable {
    var sensitivity: Double
    var minimumArea: Double

    static let `default` = SegmentationParameters(
        sensitivity: 0.5,
        minimumArea: 30
    )
}
