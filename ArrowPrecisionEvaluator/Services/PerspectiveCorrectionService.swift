import SwiftUI

protocol PerspectiveCorrectionServiceProtocol {
    func correct(image: UIImage, corners: [CGPoint], outputSize: CGSize) -> UIImage
}

final class PerspectiveCorrectionService: PerspectiveCorrectionServiceProtocol {
    func correct(image: UIImage, corners: [CGPoint], outputSize: CGSize) -> UIImage {
        // MVP skeleton:
        // 後で Core Image / OpenCV の射影変換に置き換える
        return image
    }
}
