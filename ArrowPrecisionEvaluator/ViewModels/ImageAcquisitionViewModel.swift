import SwiftUI
import PhotosUI

@MainActor
final class ImageAcquisitionViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var photoLoadingError: String?
    @Published var isLoadingPhoto = false
    private var photoLoadTask: Task<Void, Never>?

    deinit {
        photoLoadTask?.cancel()
    }

    func loadSampleImage() {
        selectedImage = SampleDataFactory.makePlaceholderImage()
        photoLoadingError = nil
    }

    func loadSelectedPhoto() {
        guard let selectedPhotoItem else { return }

        // A newer selection should always win; cancel in-flight transfers to avoid stale image races.
        photoLoadTask?.cancel()
        isLoadingPhoto = true
        photoLoadingError = nil

        photoLoadTask = Task { [weak self] in
            guard let self else { return }
            do {
                guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                    guard !Task.isCancelled else { return }
                    self.photoLoadingError = "Unable to read image data."
                    self.isLoadingPhoto = false
                    return
                }

                guard let image = UIImage(data: data) else {
                    guard !Task.isCancelled else { return }
                    self.photoLoadingError = "Selected asset is not a supported image."
                    self.isLoadingPhoto = false
                    return
                }

                guard !Task.isCancelled else { return }
                self.selectedImage = image
                self.isLoadingPhoto = false
                self.photoLoadingError = nil
            } catch {
                guard !Task.isCancelled else { return }
                self.photoLoadingError = error.localizedDescription
                self.isLoadingPhoto = false
            }
        }
    }
}
