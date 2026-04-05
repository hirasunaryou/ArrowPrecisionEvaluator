import SwiftUI
import PhotosUI

@MainActor
final class ImageAcquisitionViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var photoLoadingError: String?
    @Published var isLoadingPhoto = false

    func loadSampleImage() {
        selectedImage = SampleDataFactory.makePlaceholderImage()
        photoLoadingError = nil
    }

    func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }

        isLoadingPhoto = true
        photoLoadingError = nil

        do {
            guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                photoLoadingError = "Unable to read image data."
                isLoadingPhoto = false
                return
            }

            try Task.checkCancellation()

            guard let image = UIImage(data: data) else {
                photoLoadingError = "Selected asset is not a supported image."
                isLoadingPhoto = false
                return
            }

            selectedImage = image
            isLoadingPhoto = false
        } catch is CancellationError {
            // `task(id:)` cancels previous work when users pick another image quickly.
            isLoadingPhoto = false
        } catch {
            photoLoadingError = error.localizedDescription
            isLoadingPhoto = false
        }
    }
}
