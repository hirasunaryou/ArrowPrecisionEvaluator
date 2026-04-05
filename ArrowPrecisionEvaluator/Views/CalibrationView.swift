import SwiftUI
import UIKit

struct CalibrationView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = CalibrationViewModel()
    @State private var activeCornerIndex: Int?

    private let touchHitSize: CGFloat = 64
    private let markerSize: CGFloat = 10
    private let draggableHandleSize: CGFloat = 24
    private let dragLiftOffset: CGFloat = 44

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
                    let cornerPoints = viewModel.corners.map(mapper.viewPoint(fromImagePoint:))

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                    if cornerPoints.count == 4 {
                        CalibrationQuadrilateral(points: cornerPoints)
                            .stroke(Color.orange.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    }

                    ForEach(Array(viewModel.corners.enumerated()), id: \.offset) { index, _ in
                        calibrationCornerOverlay(
                            index: index,
                            point: cornerPoints[index],
                            mapper: mapper
                        )
                    }
                }
            }
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

    @ViewBuilder
    private func calibrationCornerOverlay(
        index: Int,
        point: CGPoint,
        mapper: AspectFitImageCoordinateMapper
    ) -> some View {
        let isDragging = activeCornerIndex == index
        // During drag, lift the visible handle up so the true corner point remains visible.
        let handleOffsetY = isDragging ? -dragLiftOffset : 0

        ZStack {
            // True calibrated point: always shown at the exact image-space coordinate.
            CalibrationCrosshair()
                .stroke(Color.orange, lineWidth: 2)
                .frame(width: markerSize, height: markerSize)

            Text(viewModel.label(forCornerAt: index))
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.65), in: Capsule())
                .foregroundStyle(.white)
                .offset(x: 20, y: -20)

            if isDragging {
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: 0, y: handleOffsetY))
                }
                .stroke(Color.orange.opacity(0.6), lineWidth: 1)
            }

            Circle()
                .fill(Color.orange.opacity(0.95))
                .overlay {
                    Circle().stroke(Color.white, lineWidth: 2)
                }
                .frame(width: draggableHandleSize, height: draggableHandleSize)
                .offset(y: handleOffsetY)
        }
        .position(point)
        .background {
            Circle()
                .fill(Color.black.opacity(0.001))
                .frame(width: touchHitSize, height: touchHitSize)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if activeCornerIndex != index {
                        activeCornerIndex = index
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }

                    // Keep the calibrated point below the finger while dragging by adding
                    // the same vertical lift used for the visual handle.
                    let adjustedLocation = CGPoint(
                        x: value.location.x,
                        y: value.location.y + dragLiftOffset
                    )
                    viewModel.moveCorner(at: index, toDisplayedPoint: adjustedLocation, mapper: mapper)
                }
                .onEnded { _ in
                    activeCornerIndex = nil
                }
        )
    }
}

private struct CalibrationCrosshair: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

private struct CalibrationQuadrilateral: Shape {
    let points: [CGPoint]

    func path(in _: CGRect) -> Path {
        var path = Path()
        guard points.count == 4 else { return path }
        path.move(to: points[0])
        path.addLine(to: points[1])
        path.addLine(to: points[2])
        path.addLine(to: points[3])
        path.closeSubpath()
        return path
    }
}
