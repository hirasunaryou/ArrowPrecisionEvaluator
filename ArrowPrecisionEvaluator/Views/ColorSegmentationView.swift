import SwiftUI

struct ColorSegmentationView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = ColorSegmentationViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Color", selection: $viewModel.selectedColorPreset) {
                    ForEach(ColorPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text("Sensitivity: \(viewModel.sensitivity, specifier: "%.2f")")
                    Slider(value: $viewModel.sensitivity, in: 0...1)
                }

                VStack(alignment: .leading) {
                    Text("Minimum Area: \(Int(viewModel.minimumArea))")
                    Slider(value: $viewModel.minimumArea, in: 1...200, step: 1)
                }

                Group {
                    if let image = environment.flowViewModel.draft.correctedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 320)
                            .border(Color.gray.opacity(0.4))
                    }
                }

                Button("Detect Marker Candidates") {
                    guard let image = environment.flowViewModel.draft.correctedImage else { return }

                    let parameters = viewModel.currentParameters()
                    let points = environment.flowViewModel.markerDetectionService.detectMarkers(
                        from: image,
                        preset: viewModel.selectedColorPreset,
                        parameters: parameters,
                        calibrationData: environment.flowViewModel.draft.calibrationData
                    )

                    environment.flowViewModel.draft.selectedColorPreset = viewModel.selectedColorPreset
                    environment.flowViewModel.draft.segmentationParameters = parameters
                    environment.flowViewModel.draft.candidateMarkerPoints = points
                    environment.flowViewModel.path.append(.markerReview)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Color Segmentation")
        .onAppear {
            let settings = environment.flowViewModel.settings
            viewModel.selectedColorPreset = settings.defaultColorPreset
            viewModel.sensitivity = settings.defaultSensitivity
            viewModel.minimumArea = settings.defaultMinimumMarkerArea
        }
    }
}
