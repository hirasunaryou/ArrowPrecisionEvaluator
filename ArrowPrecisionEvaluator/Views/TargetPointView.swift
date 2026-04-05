import SwiftUI

struct TargetPointView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = TargetPointViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Toggle("Use Center as Target", isOn: $viewModel.usesCenterTarget)
                .onChange(of: viewModel.usesCenterTarget) { _, newValue in
                    guard newValue, let image = environment.flowViewModel.draft.correctedImage else { return }
                    viewModel.setCenter(in: image.size)
                }

            GeometryReader { proxy in
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))

                    if let image = environment.flowViewModel.draft.correctedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                        Circle()
                            .stroke(Color.red, lineWidth: 3)
                            .frame(width: 24, height: 24)
                            .position(
                                viewModel.displayedTargetPoint(
                                    imageSize: image.size,
                                    containerSize: proxy.size
                                )
                            )
                    }
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard
                                !viewModel.usesCenterTarget,
                                let image = environment.flowViewModel.draft.correctedImage
                            else { return }

                            viewModel.updateTargetPoint(
                                fromDisplayedPoint: value.location,
                                imageSize: image.size,
                                containerSize: proxy.size
                            )
                        }
                )
            }
            .frame(height: 320)
            .border(Color.gray.opacity(0.4))

            Button("Confirm Target Point") {
                guard let image = environment.flowViewModel.draft.correctedImage else { return }
                let target = viewModel.buildTargetPoint(
                    imageSize: image.size,
                    calibrationData: environment.flowViewModel.draft.calibrationData
                )
                environment.flowViewModel.draft.targetPoint = target
                environment.flowViewModel.path.append(.segmentation)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Target Point")
        .onAppear {
            guard let image = environment.flowViewModel.draft.correctedImage else { return }
            viewModel.initializeTargetPoint(
                existingTarget: environment.flowViewModel.draft.targetPoint,
                imageSize: image.size,
                defaultUsesCenterTarget: environment.flowViewModel.settings.defaultUseCenterTarget
            )
        }
        .onChange(of: environment.flowViewModel.draft.correctedImage?.size) { _, newSize in
            guard let newSize else { return }
            viewModel.initializeTargetPoint(
                existingTarget: environment.flowViewModel.draft.targetPoint,
                imageSize: newSize,
                defaultUsesCenterTarget: environment.flowViewModel.settings.defaultUseCenterTarget
            )
        }
    }
}
