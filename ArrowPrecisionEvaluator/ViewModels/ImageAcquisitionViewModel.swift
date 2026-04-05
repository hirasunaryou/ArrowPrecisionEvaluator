import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

@MainActor
final class ImageAcquisitionViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var photoLoadingError: String?
    @Published var cameraErrorMessage: String?
    @Published var isLoadingPhoto = false
    @Published var isCameraSheetPresented = false

    func loadSampleImage() {
        selectedImage = SampleDataFactory.makePlaceholderImage()
        photoLoadingError = nil
        cameraErrorMessage = nil
    }

    func loadSelectedPhoto() async {
        guard let selectedPhotoItem else { return }

        isLoadingPhoto = true
        photoLoadingError = nil
        cameraErrorMessage = nil

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

    func startCameraCapture() {
        photoLoadingError = nil

        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraErrorMessage = "Camera is unavailable on this device. Please import from Photo Library instead."
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraSheetPresented = true
        case .notDetermined:
            Task {
                let granted = await requestCameraAccess()
                if granted {
                    isCameraSheetPresented = true
                } else {
                    cameraErrorMessage = "Camera permission was denied. You can enable it in Settings."
                }
            }
        case .denied, .restricted:
            cameraErrorMessage = "Camera access is disabled. Enable camera access in Settings to capture photos in-app."
        @unknown default:
            cameraErrorMessage = "Camera permission status is unavailable. Please import from Photo Library instead."
        }
    }

    func applyCapturedImage(_ image: UIImage?) {
        guard let image else { return }
        selectedImage = image
        photoLoadingError = nil
        cameraErrorMessage = nil
    }

    private func requestCameraAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
