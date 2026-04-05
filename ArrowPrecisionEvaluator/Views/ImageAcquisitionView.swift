import SwiftUI

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
    }
}
