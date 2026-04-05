import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = CalibrationViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Calibration")
                    .font(.title2)
                    .fontWeight(.semibold)

                calibrationPreview

                HStack {
                    TextField("Width (mm)", text: $viewModel.widthMmText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)

                    TextField("Height (mm)", text: $viewModel.heightMmText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                }

                Button("Apply Calibration") {
                    guard let image = environment.flowViewModel.draft.originalImage else { return }
                    let imageSize = image.size
                    guard let calibrationData = viewModel.buildCalibrationData(imageSize: imageSize) else { return }

                    environment.flowViewModel.draft.calibrationData = calibrationData
                    environment.flowViewModel.draft.correctedImage =
                        environment.flowViewModel.perspectiveCorrectionService.correct(
                            image: image,
                            corners: viewModel.corners,
                            outputSize: image.size
                        )
                    environment.flowViewModel.path.append(.targetPoint)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Calibration")
    }

    private var calibrationPreview: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))

                if let image = environment.flowViewModel.draft.originalImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }

                ForEach(Array(viewModel.corners.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 24, height: 24)
                        .position(point)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    viewModel.moveCorner(at: index, to: value.location)
                                }
                        )
                }
            }
        }
        .frame(height: 320)
        .border(Color.gray.opacity(0.4))
    }
}
