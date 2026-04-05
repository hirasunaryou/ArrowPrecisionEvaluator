import CoreGraphics

/// Converts points between an aspect-fit displayed image and its original pixel coordinate space.
struct AspectFitImageCoordinateMapper {
    let imageSize: CGSize
    let containerSize: CGSize

    var displayFrame: CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }

        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: (containerSize.width - fittedSize.width) / 2.0,
            y: (containerSize.height - fittedSize.height) / 2.0
        )
        return CGRect(origin: origin, size: fittedSize)
    }

    func viewPoint(fromImagePoint imagePoint: CGPoint) -> CGPoint {
        let frame = displayFrame
        guard frame.width > 0, frame.height > 0 else { return .zero }

        let normalizedX = imagePoint.x / imageSize.width
        let normalizedY = imagePoint.y / imageSize.height
        return CGPoint(
            x: frame.minX + (normalizedX * frame.width),
            y: frame.minY + (normalizedY * frame.height)
        )
    }

    func imagePoint(fromViewPoint viewPoint: CGPoint) -> CGPoint {
        let frame = displayFrame
        guard frame.width > 0, frame.height > 0 else { return .zero }

        let clampedX = min(max(viewPoint.x, frame.minX), frame.maxX)
        let clampedY = min(max(viewPoint.y, frame.minY), frame.maxY)
        let normalizedX = (clampedX - frame.minX) / frame.width
        let normalizedY = (clampedY - frame.minY) / frame.height

        return CGPoint(
            x: normalizedX * imageSize.width,
            y: normalizedY * imageSize.height
        )
    }
}
