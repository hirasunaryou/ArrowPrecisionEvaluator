import Foundation

struct MarkerPoint: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var xPx: Double
    var yPx: Double
    var xMm: Double
    var yMm: Double
    var areaPx: Double
    var isManuallyAdded: Bool = false
}
