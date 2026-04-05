import SwiftUI

final class CalibrationViewModel: ObservableObject {
    @Published var corners: [CGPoint] = [
        CGPoint(x: 80, y: 60),
        CGPoint(x: 820, y: 60),
        CGPoint(x: 820, y: 540),
        CGPoint(x: 80, y: 540)
    ]

    @Published var widthMmText: String = "420"
    @Published var heightMmText: String = "297"

    func moveCorner(at index: Int, to newPoint: CGPoint) {
        guard corners.indices.contains(index) else { return }
        corners[index] = newPoint
    }

    func buildCalibrationData(imageSize: CGSize) -> CalibrationData? {
        guard
            let widthMm = Double(widthMmText),
            let heightMm = Double(heightMmText),
            widthMm > 0,
            heightMm > 0
        else {
            return nil
        }

        let widthPx = distance(from: corners[0], to: corners[1])
        let heightPx = distance(from: corners[0], to: corners[3])

        guard widthPx > 0, heightPx > 0 else { return nil }

        return CalibrationData(
            cornersPx: corners.map(CodablePoint.init),
            physicalWidthMm: widthMm,
            physicalHeightMm: heightMm,
            mmPerPixelX: widthMm / widthPx,
            mmPerPixelY: heightMm / heightPx
        )
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> Double {
        hypot(p1.x - p2.x, p1.y - p2.y)
    }
}
