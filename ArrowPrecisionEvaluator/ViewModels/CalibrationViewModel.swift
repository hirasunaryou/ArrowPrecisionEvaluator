import SwiftUI

final class CalibrationViewModel: ObservableObject {
    /// Corner points are always stored in the original image's pixel space.
    /// Order: top-left, top-right, bottom-right, bottom-left.
    @Published var corners: [CGPoint] = []

    @Published var widthMmText: String = "420"
    @Published var heightMmText: String = "297"

    func initializeCornersIfNeeded(imageSize: CGSize) {
        guard imageSize.width > 0, imageSize.height > 0 else { return }
        guard corners.count != 4 || corners.contains(where: { !isPoint($0, insideImageSize: imageSize) }) else { return }

        // Start slightly inset from each edge so handles remain easy to grab.
        let insetRatio: CGFloat = 0.1
        let insetX = imageSize.width * insetRatio
        let insetY = imageSize.height * insetRatio

        corners = [
            CGPoint(x: insetX, y: insetY),
            CGPoint(x: imageSize.width - insetX, y: insetY),
            CGPoint(x: imageSize.width - insetX, y: imageSize.height - insetY),
            CGPoint(x: insetX, y: imageSize.height - insetY)
        ]
    }

    func moveCorner(at index: Int, to newPoint: CGPoint, imageSize: CGSize) {
        guard corners.indices.contains(index) else { return }
        corners[index] = clampToImageBounds(point: newPoint, imageSize: imageSize)
    }

    func moveCorner(at index: Int, toDisplayedPoint displayedPoint: CGPoint, mapper: AspectFitImageCoordinateMapper) {
        moveCorner(at: index, to: mapper.imagePoint(fromViewPoint: displayedPoint), imageSize: mapper.imageSize)
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

    private func isPoint(_ point: CGPoint, insideImageSize imageSize: CGSize) -> Bool {
        point.x >= 0 && point.x <= imageSize.width && point.y >= 0 && point.y <= imageSize.height
    }

    private func clampToImageBounds(point: CGPoint, imageSize: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), imageSize.width),
            y: min(max(point.y, 0), imageSize.height)
        )
    }
}
