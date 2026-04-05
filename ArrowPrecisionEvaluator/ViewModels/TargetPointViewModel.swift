import SwiftUI

final class TargetPointViewModel: ObservableObject {
    @Published var usesCenterTarget: Bool = true
    /// Stored in corrected image coordinate space (pixels), not view space.
    @Published var targetPointPx: CGPoint = CGPoint(x: 450, y: 300)

    func initializeTargetPoint(
        existingTarget: TargetPoint?,
        imageSize: CGSize,
        defaultUsesCenterTarget: Bool
    ) {
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        if let existingTarget {
            usesCenterTarget = existingTarget.usesCenter
            targetPointPx = CGPoint(existingTarget.pointPx)
            if existingTarget.usesCenter {
                setCenter(in: imageSize)
            }
            return
        }

        usesCenterTarget = defaultUsesCenterTarget
        if defaultUsesCenterTarget {
            setCenter(in: imageSize)
        }
    }

    func setCenter(in size: CGSize) {
        targetPointPx = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
    }

    func displayedTargetPoint(imageSize: CGSize, containerSize: CGSize) -> CGPoint {
        let mapper = AspectFitImageCoordinateMapper(imageSize: imageSize, containerSize: containerSize)
        return mapper.viewPoint(fromImagePoint: targetPointPx)
    }

    func updateTargetPoint(
        fromDisplayedPoint displayedPoint: CGPoint,
        imageSize: CGSize,
        containerSize: CGSize
    ) {
        let mapper = AspectFitImageCoordinateMapper(imageSize: imageSize, containerSize: containerSize)
        // Convert and clamp from displayed coordinates to corrected-image coordinates.
        targetPointPx = mapper.imagePoint(fromViewPoint: displayedPoint)
    }

    func buildTargetPoint(imageSize: CGSize, calibrationData: CalibrationData?) -> TargetPoint {
        // Center mode always uses the true corrected-image center.
        let pointPx = usesCenterTarget
            ? CGPoint(x: imageSize.width / 2.0, y: imageSize.height / 2.0)
            : targetPointPx

        let mmX = calibrationData.map { Double(pointPx.x) * $0.mmPerPixelX } ?? Double(pointPx.x)
        let mmY = calibrationData.map { Double(pointPx.y) * $0.mmPerPixelY } ?? Double(pointPx.y)

        return TargetPoint(
            pointPx: CodablePoint(pointPx),
            pointMm: CodablePoint(x: mmX, y: mmY),
            usesCenter: usesCenterTarget
        )
    }
}
