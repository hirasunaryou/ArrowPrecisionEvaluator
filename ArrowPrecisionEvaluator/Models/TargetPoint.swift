import Foundation

struct TargetPoint: Codable, Hashable {
    var pointPx: CodablePoint
    var pointMm: CodablePoint
    var usesCenter: Bool
}
