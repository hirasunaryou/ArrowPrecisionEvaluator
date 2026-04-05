import Foundation

final class MarkerReviewViewModel: ObservableObject {
    @Published var markerPoints: [MarkerPoint] = []

    func removeMarker(id: UUID) {
        markerPoints.removeAll { $0.id == id }
    }

    func addMarker(xMm: Double, yMm: Double) {
        let point = MarkerPoint(
            xPx: xMm,
            yPx: yMm,
            xMm: xMm,
            yMm: yMm,
            areaPx: 0,
            isManuallyAdded: true
        )
        markerPoints.append(point)
    }
}
