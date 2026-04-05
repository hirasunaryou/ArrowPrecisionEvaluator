import SwiftUI

struct ColorSegmentationView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = ColorSegmentationViewModel()
    private static let previewDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker(
                    "Color",
                    selection: Binding(
                        get: { viewModel.selectedColorPreset },
                        set: { viewModel.updateColorPreset($0) }
                    )
                ) {
                    ForEach(ColorPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text("Sensitivity: \(viewModel.sensitivity, specifier: "%.2f")")
                    Slider(
                        value: Binding(
                            get: { viewModel.sensitivity },
                            set: { viewModel.updateSensitivity($0) }
                        ),
                        in: 0...1
                    )
                    Text("Higher sensitivity widens HSV thresholds (more candidates, more noise).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if viewModel.isPreviewUpdating {
                        Text("Updating preview…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Minimum Area: \(Int(viewModel.minimumArea)) px²")
                    Slider(
                        value: Binding(
                            get: { viewModel.minimumArea },
                            set: { viewModel.updateMinimumArea($0) }
                        ),
                        in: 1...5000,
                        step: 1
                    )
                    Text("Applies to detected components (not the grayscale mask preview).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(
                        "Preview components ≥ minimum area: \(viewModel.previewPassingComponentCount) / \(viewModel.previewComponentCount)"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Button("Update Preview") {
                        updatePreview()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        !viewModel.isPreviewStale
                            || viewModel.isPreviewUpdating
                            || environment.flowViewModel.draft.correctedImage == nil
                    )

                    if viewModel.isPreviewStale {
                        Text("Parameters changed — tap Update Preview.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if let updatedAt = viewModel.lastPreviewUpdatedAt {
                        Text("Preview updated at \(Self.previewDateFormatter.string(from: updatedAt)).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Group {
                    if let image = environment.flowViewModel.draft.correctedImage {
                        Image(uiImage: viewModel.previewImage ?? image)
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

                Text("If detection is not ready, skip and place markers manually in the next screen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Skip Auto Detection (Manual Review)") {
                    let parameters = viewModel.currentParameters()
                    environment.flowViewModel.draft.selectedColorPreset = viewModel.selectedColorPreset
                    environment.flowViewModel.draft.segmentationParameters = parameters
                    environment.flowViewModel.draft.candidateMarkerPoints = []
                    environment.flowViewModel.path.append(.markerReview)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Color Segmentation")
        .onAppear {
            let settings = environment.flowViewModel.settings
            viewModel.updateColorPreset(settings.defaultColorPreset)
            viewModel.updateSensitivity(settings.defaultSensitivity)
            viewModel.updateMinimumArea(settings.defaultMinimumMarkerArea)
            viewModel.refreshPreviewImmediately(
                with: environment.flowViewModel.draft.correctedImage,
                service: environment.flowViewModel.colorSegmentationService
            )
        }
    }

    private func updatePreview() {
        viewModel.schedulePreviewRefresh(
            with: environment.flowViewModel.draft.correctedImage,
            service: environment.flowViewModel.colorSegmentationService
        )
    }
}
