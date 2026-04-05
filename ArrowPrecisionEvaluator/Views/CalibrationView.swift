import SwiftUI
import UIKit

struct CalibrationView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = CalibrationViewModel()

    @State private var activeCornerIndex: Int?

    // Keep the true point visible by rendering the draggable handle above it while dragging.
    private let dragHandleLift = CGSize(width: 0, height: -56)
    private let dragHitAreaSize: CGFloat = 56

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
                    guard let correctedOutputSize = viewModel.correctedOutputSize() else { return }
                    guard let calibrationData = viewModel.buildCalibrationData(correctedImageSize: correctedOutputSize) else { return }

                    environment.flowViewModel.draft.calibrationData = calibrationData
                    environment.flowViewModel.draft.correctedImage =
                        environment.flowViewModel.perspectiveCorrectionService.correct(
                            image: image,
                            corners: viewModel.corners,
                            outputSize: correctedOutputSize
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
                    let mapper = AspectFitImageCoordinateMapper(
                        imageSize: image.size,
                        containerSize: proxy.size
                    )

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                    if viewModel.corners.count == 4 {
                        CornerQuadOverlay(viewPoints: viewModel.corners.map { mapper.viewPoint(fromImagePoint: $0) })
                    }

                    ForEach(Array(viewModel.corners.enumerated()), id: \.offset) { index, point in
                        let trueCornerPoint = mapper.viewPoint(fromImagePoint: point)
                        let handleLift = activeCornerIndex == index ? dragHandleLift : .zero
                        let handlePoint = trueCornerPoint.offsetBy(handleLift)

                        ZStack {
                            // True calibrated point that should remain visible while dragging.
                            TrueCornerMarkerView()
                                .position(trueCornerPoint)

                            // Make the active drag offset explicit.
                            if activeCornerIndex == index {
                                Path { path in
                                    path.move(to: trueCornerPoint)
                                    path.addLine(to: handlePoint)
                                }
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .foregroundStyle(Color.orange.opacity(0.7))
                            }

                            DraggableCornerHandleView(isActive: activeCornerIndex == index)
                                .position(handlePoint)

                            Text(cornerLabel(for: index))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.black.opacity(0.65), in: Capsule())
                                .position(CGPoint(x: trueCornerPoint.x, y: trueCornerPoint.y - 18))

                            Circle()
                                .fill(Color.clear)
                                .frame(width: dragHitAreaSize, height: dragHitAreaSize)
                                .contentShape(Circle())
                                .position(handlePoint)
                                .gesture(cornerDragGesture(index: index, mapper: mapper, handleLift: handleLift))
                        }
                    }
                }
            }
            .coordinateSpace(name: "calibrationPreview")
        }
        .frame(height: 320)
        .border(Color.gray.opacity(0.4))
        .onAppear {
            if let image = environment.flowViewModel.draft.originalImage {
                viewModel.initializeCornersIfNeeded(imageSize: image.size)
            }
        }
        .onChange(of: environment.flowViewModel.draft.originalImage?.size) { _, newSize in
            if let newSize {
                viewModel.initializeCornersIfNeeded(imageSize: newSize)
            }
        }
    }

    private func cornerDragGesture(
        index: Int,
        mapper: AspectFitImageCoordinateMapper,
        handleLift: CGSize
    ) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("calibrationPreview"))
            .onChanged { value in
                if activeCornerIndex != index {
                    activeCornerIndex = index
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }

                // Convert finger location at the lifted handle to the true corner point location.
                let truePointInView = CGPoint(
                    x: value.location.x - handleLift.width,
                    y: value.location.y - handleLift.height
                )
                viewModel.moveCorner(at: index, toDisplayedPoint: truePointInView, mapper: mapper)
            }
            .onEnded { _ in
                activeCornerIndex = nil
            }
    }

    private func cornerLabel(for index: Int) -> String {
        switch index {
        case 0: return "TL"
        case 1: return "TR"
        case 2: return "BR"
        case 3: return "BL"
        default: return ""
        }
    }
}

private struct CornerQuadOverlay: View {
    let viewPoints: [CGPoint]

    var body: some View {
        Path { path in
            guard viewPoints.count == 4 else { return }
            path.move(to: viewPoints[0])
            path.addLine(to: viewPoints[1])
            path.addLine(to: viewPoints[2])
            path.addLine(to: viewPoints[3])
            path.closeSubpath()
        }
        .stroke(Color.orange.opacity(0.9), style: StrokeStyle(lineWidth: 2))
    }
}

private struct TrueCornerMarkerView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(Color.white)
                .frame(width: 12, height: 1.5)

            Rectangle()
                .fill(Color.white)
                .frame(width: 1.5, height: 12)
        }
    }
}

private struct DraggableCornerHandleView: View {
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(Color.orange.opacity(isActive ? 0.95 : 0.75))
            .frame(width: isActive ? 24 : 20, height: isActive ? 24 : 20)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.95), lineWidth: 2)
            }
            .shadow(color: .black.opacity(isActive ? 0.35 : 0.15), radius: isActive ? 6 : 2, y: 2)
    }
}

private extension CGPoint {
    func offsetBy(_ size: CGSize) -> CGPoint {
        CGPoint(x: x + size.width, y: y + size.height)
    }
}
