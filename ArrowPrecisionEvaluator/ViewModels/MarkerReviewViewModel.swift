import Foundation
import CoreGraphics

final class MarkerReviewViewModel: ObservableObject {
    enum EditMode: String, CaseIterable, Identifiable {
        case add
        case remove

        var id: String { rawValue }

        var title: String {
            switch self {
            case .add: return "Add"
            case .remove: return "Remove"
            }
        }
    }

    @Published var markerPoints: [MarkerPoint] = []
    @Published var editMode: EditMode = .add

    func removeMarker(id: UUID) {
        markerPoints.removeAll { $0.id == id }
    }

    func addMarker(at imagePoint: CGPoint, calibrationData: CalibrationData?) {
        let xMm = calibrationData.map { Double(imagePoint.x) * $0.mmPerPixelX } ?? Double(imagePoint.x)
        let yMm = calibrationData.map { Double(imagePoint.y) * $0.mmPerPixelY } ?? Double(imagePoint.y)

        let point = MarkerPoint(
            xPx: Double(imagePoint.x),
            yPx: Double(imagePoint.y),
            xMm: xMm,
            yMm: yMm,
            areaPx: 0,
            isManuallyAdded: true
        )
        markerPoints.append(point)
    }

    func removeMarker(near location: CGPoint, mapper: AspectFitImageCoordinateMapper, radius: CGFloat) {
        guard !markerPoints.isEmpty else { return }

        let indexedDistances = markerPoints.enumerated().map { index, marker in
            let markerViewPoint = mapper.viewPoint(
                fromImagePoint: CGPoint(x: marker.xPx, y: marker.yPx)
            )
            return (index: index, distance: hypot(markerViewPoint.x - location.x, markerViewPoint.y - location.y))
        }

        guard
            let nearest = indexedDistances.min(by: { $0.distance < $1.distance }),
            nearest.distance <= radius
        else { return }

        markerPoints.remove(at: nearest.index)
    }
}
