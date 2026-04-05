import SwiftUI

final class CalibrationViewModel: ObservableObject {
    /// Corner points are always stored in the original image's pixel space.
    /// Order: top-left, top-right, bottom-right, bottom-left.
    @Published var corners: [CGPoint] = []

    @Published var widthMmText: String = "420"
    @Published var heightMmText: String = "297"

    /// Keep corrected images at a practical working resolution while respecting
    /// the user-entered physical aspect ratio.
    private let correctedLongSidePixels: CGFloat = 2000

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

    func correctedOutputSize() -> CGSize? {
        guard
            let widthMm = Double(widthMmText),
            let heightMm = Double(heightMmText),
            widthMm > 0,
            heightMm > 0
        else {
            return nil
        }

        let aspectRatio = widthMm / heightMm
        guard aspectRatio.isFinite, aspectRatio > 0 else { return nil }

        let widthPx: CGFloat
        let heightPx: CGFloat
        if aspectRatio >= 1 {
            widthPx = correctedLongSidePixels
            heightPx = correctedLongSidePixels / aspectRatio
        } else {
            widthPx = correctedLongSidePixels * aspectRatio
            heightPx = correctedLongSidePixels
        }

        return CGSize(
            width: max(1, widthPx.rounded()),
            height: max(1, heightPx.rounded())
        )
    }

    func buildCalibrationData(correctedImageSize: CGSize) -> CalibrationData? {
        guard
            let widthMm = Double(widthMmText),
            let heightMm = Double(heightMmText),
            widthMm > 0,
            heightMm > 0,
            correctedImageSize.width > 0,
            correctedImageSize.height > 0,
            corners.count == 4
        else {
            return nil
        }

        return CalibrationData(
            cornersPx: corners.map(CodablePoint.init),
            physicalWidthMm: widthMm,
            physicalHeightMm: heightMm,
            // mm/px now matches the corrected image coordinate space used by
            // target and marker screens.
            mmPerPixelX: widthMm / Double(correctedImageSize.width),
            mmPerPixelY: heightMm / Double(correctedImageSize.height)
        )
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
