import SwiftUI

final class TargetPointViewModel: ObservableObject {
    @Published var usesCenterTarget: Bool = true
    @Published var targetPointPx: CGPoint = CGPoint(x: 450, y: 300)

    func setCenter(in size: CGSize) {
        targetPointPx = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
    }

    func buildTargetPoint(imageSize: CGSize, calibrationData: CalibrationData?) -> TargetPoint {
        let mmX = calibrationData.map { Double(targetPointPx.x) * $0.mmPerPixelX } ?? Double(targetPointPx.x)
        let mmY = calibrationData.map { Double(targetPointPx.y) * $0.mmPerPixelY } ?? Double(targetPointPx.y)

        return TargetPoint(
            pointPx: CodablePoint(targetPointPx),
            pointMm: CodablePoint(x: mmX, y: mmY),
            usesCenter: usesCenterTarget
        )
    }
}
