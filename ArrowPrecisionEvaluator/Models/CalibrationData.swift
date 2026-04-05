import Foundation

struct CalibrationData: Codable, Hashable {
    var cornersPx: [CodablePoint]
    var physicalWidthMm: Double
    var physicalHeightMm: Double
    var mmPerPixelX: Double
    var mmPerPixelY: Double
}
