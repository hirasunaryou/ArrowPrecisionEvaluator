import SwiftUI

struct MarkerReviewView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel = MarkerReviewViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Detected Markers: \(viewModel.markerPoints.count)")
                .font(.headline)

            Picker("Edit Mode", selection: $viewModel.editMode) {
                ForEach(MarkerReviewViewModel.EditMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if let image = environment.flowViewModel.draft.correctedImage {
                GeometryReader { proxy in
                    let mapper = AspectFitImageCoordinateMapper(
                        imageSize: image.size,
                        containerSize: proxy.size
                    )

                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                        ForEach(viewModel.markerPoints) { marker in
                            Circle()
                                .fill(marker.isManuallyAdded ? Color.orange : Color.blue)
                                .frame(width: 14, height: 14)
                                .overlay {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                }
                                // Marker points are stored in corrected image coordinates (pixel space),
                                // so each render maps image-space coordinates into view-space.
                                .position(
                                    mapper.viewPoint(
                                        fromImagePoint: CGPoint(x: marker.xPx, y: marker.yPx)
                                    )
                                )
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                switch viewModel.editMode {
                                case .add:
                                    // Convert tap location from the displayed image back into corrected
                                    // image coordinates so persisted points stay in image space.
                                    let imagePoint = mapper.imagePoint(fromViewPoint: value.location)
                                    viewModel.addMarker(
                                        at: imagePoint,
                                        calibrationData: environment.flowViewModel.draft.calibrationData
                                    )
                                case .remove:
                                    viewModel.removeMarker(near: value.location, mapper: mapper, radius: 20)
                                }
                            }
                    )
                }
                .frame(height: 320)
                .border(Color.gray.opacity(0.4))
            }

            List {
                ForEach(viewModel.markerPoints) { point in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("x: \(point.xMm, specifier: "%.1f") mm")
                            Text("y: \(point.yMm, specifier: "%.1f") mm")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if point.isManuallyAdded {
                            Text("Manual")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Button("Delete") {
                            viewModel.removeMarker(id: point.id)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(minHeight: 220)

            Button("Confirm Final Markers") {
                environment.flowViewModel.draft.finalMarkerPoints = viewModel.markerPoints
                environment.flowViewModel.path.append(.analysis)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .navigationTitle("Marker Review")
        .onAppear {
            viewModel.markerPoints = environment.flowViewModel.draft.candidateMarkerPoints
        }
    }
}
