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

            GeometryReader { _ in
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))

                    if let image = environment.flowViewModel.draft.correctedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }

                    Circle()
                        .stroke(Color.red, lineWidth: 3)
                        .frame(width: 24, height: 24)
                        .position(viewModel.targetPointPx)
                }
                .contentShape(Rectangle())
                .gesture(
                    TapGesture()
                        .onEnded {
                            // placeholder
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !viewModel.usesCenterTarget {
                                viewModel.targetPointPx = value.location
                            }
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
            if let image = environment.flowViewModel.draft.correctedImage {
                viewModel.setCenter(in: image.size)
                viewModel.usesCenterTarget = environment.flowViewModel.settings.defaultUseCenterTarget
            }
        }
    }
}
