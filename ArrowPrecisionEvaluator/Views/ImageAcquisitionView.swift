import SwiftUI
import PhotosUI

struct ImageAcquisitionView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = ImageAcquisitionViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Image Acquisition")
                .font(.title2)
                .fontWeight(.semibold)

            Group {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .border(Color.gray.opacity(0.4))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 240)
                        .overlay(Text("No image selected"))
                }
            }

            Button("Load Sample Image") {
                viewModel.loadSampleImage()
            }
            .buttonStyle(.borderedProminent)

            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                Label("Import from Photo Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .task(id: viewModel.selectedPhotoItem) {
                await viewModel.loadSelectedPhoto()
            }

            Button {
                viewModel.startCameraCapture()
            } label: {
                Label("Capture with Camera", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

#if targetEnvironment(simulator)
            Text("Camera capture may be unavailable on Simulator. Use sample image or photo library import as fallback.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
#endif

            if viewModel.isLoadingPhoto {
                ProgressView("Loading selected photo...")
            }

            if let photoLoadingError = viewModel.photoLoadingError {
                Text(photoLoadingError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if let cameraErrorMessage = viewModel.cameraErrorMessage {
                Text(cameraErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button("Use This Image") {
                environment.flowViewModel.draft.originalImage = viewModel.selectedImage
                environment.flowViewModel.path.append(.calibration)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.selectedImage == nil)

            Spacer()
        }
        .padding()
        .navigationTitle("Acquire Image")
        .onChange(of: viewModel.selectedImage) { _, image in
            // Keep the flow draft in sync so downstream screens can reuse the latest selected asset.
            environment.flowViewModel.draft.originalImage = image
        }
        .sheet(isPresented: $viewModel.isCameraSheetPresented) {
            // Camera output is fed into the same selected-image state used by sample/library imports.
            CameraImagePicker { image in
                viewModel.applyCapturedImage(image)
            }
            .ignoresSafeArea()
        }
    }
}
