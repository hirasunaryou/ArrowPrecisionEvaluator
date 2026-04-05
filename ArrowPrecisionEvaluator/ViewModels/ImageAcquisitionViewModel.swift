import SwiftUI
import PhotosUI
import AVFoundation

@MainActor
final class ImageAcquisitionViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var photoLoadingError: String?
    @Published var isLoadingPhoto = false
    @Published var isShowingCamera = false
    @Published var cameraAlertMessage: String?

    func loadSampleImage() {
        selectedImage = SampleDataFactory.makePlaceholderImage()
        photoLoadingError = nil
        cameraAlertMessage = nil
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
            cameraAlertMessage = nil
            isLoadingPhoto = false
        } catch is CancellationError {
            // `task(id:)` cancels previous work when users pick another image quickly.
            isLoadingPhoto = false
        } catch {
            photoLoadingError = error.localizedDescription
            isLoadingPhoto = false
        }
    }

    func beginCameraCapture() {
        photoLoadingError = nil

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAlertMessage = "Camera is not available on this device. Please use Photo Library import or a sample image."
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isShowingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.isShowingCamera = true
                    } else {
                        self.cameraAlertMessage = "Camera access was denied. Enable camera permission in Settings to capture photos in-app."
                    }
                }
            }
        case .denied, .restricted:
            cameraAlertMessage = "Camera access is unavailable. Enable camera permission in Settings to capture photos in-app."
        @unknown default:
            cameraAlertMessage = "Camera permission state is unknown. Please try again or use Photo Library import."
        }
    }

    func applyCapturedImage(_ image: UIImage) {
        selectedImage = image
        photoLoadingError = nil
        cameraAlertMessage = nil
    }
}
