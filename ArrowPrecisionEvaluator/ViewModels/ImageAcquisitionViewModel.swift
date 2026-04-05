import SwiftUI
import PhotosUI

final class ImageAcquisitionViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var photoLoadingError: String?
    @Published var isLoadingPhoto = false

    func loadSampleImage() {
        selectedImage = SampleDataFactory.makePlaceholderImage()
        photoLoadingError = nil
    }

    func loadSelectedPhoto() {
        guard let selectedPhotoItem else { return }

        isLoadingPhoto = true
        photoLoadingError = nil

        Task {
            do {
                guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        self.photoLoadingError = "Unable to read image data."
                        self.isLoadingPhoto = false
                    }
                    return
                }

                guard let image = UIImage(data: data) else {
                    await MainActor.run {
                        self.photoLoadingError = "Selected asset is not a supported image."
                        self.isLoadingPhoto = false
                    }
                    return
                }

                await MainActor.run {
                    self.selectedImage = image
                    self.isLoadingPhoto = false
                }
            } catch {
                await MainActor.run {
                    self.photoLoadingError = error.localizedDescription
                    self.isLoadingPhoto = false
                }
            }
        }
    }
}
