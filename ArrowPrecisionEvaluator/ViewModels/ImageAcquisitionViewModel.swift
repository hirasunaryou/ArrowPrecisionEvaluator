import SwiftUI

final class ImageAcquisitionViewModel: ObservableObject {
    @Published var selectedImage: UIImage?

    func loadSampleImage() {
        selectedImage = SampleDataFactory.makePlaceholderImage()
    }
}
