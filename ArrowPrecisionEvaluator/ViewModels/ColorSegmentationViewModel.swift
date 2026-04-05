import SwiftUI

@MainActor
final class ColorSegmentationViewModel: ObservableObject {
    @Published var selectedColorPreset: ColorPreset = .red
    @Published var sensitivity: Double = 0.5
    @Published var minimumArea: Double = 30
    @Published var previewImage: UIImage?
    @Published private(set) var isPreviewUpdating = false
    @Published private(set) var isPreviewStale = false
    @Published private(set) var lastPreviewUpdatedAt: Date?
    @Published private(set) var previewComponentCount = 0
    @Published private(set) var previewPassingComponentCount = 0

    private var previewComponentAreas: [Int] = []
    private var previewTask: Task<Void, Never>?

    deinit {
        previewTask?.cancel()
    }

    func currentParameters() -> SegmentationParameters {
        SegmentationParameters(
            sensitivity: sensitivity,
            minimumArea: minimumArea
        )
    }

    func updateColorPreset(_ preset: ColorPreset) {
        guard selectedColorPreset != preset else { return }
        selectedColorPreset = preset
        isPreviewStale = true
    }

    func updateSensitivity(_ value: Double) {
        guard sensitivity != value else { return }
        sensitivity = value
        isPreviewStale = true
    }

    func refreshPreviewImmediately(
        with image: UIImage?,
        service: ColorSegmentationServiceProtocol
    ) {
        schedulePreviewRefresh(with: image, service: service, debounceNanoseconds: 0)
    }

    func schedulePreviewRefresh(
        with image: UIImage?,
        service: ColorSegmentationServiceProtocol,
        debounceNanoseconds: UInt64 = 220_000_000
    ) {
        previewTask?.cancel()

        guard let image else {
            previewImage = nil
            previewComponentAreas = []
            previewComponentCount = 0
            previewPassingComponentCount = 0
            isPreviewUpdating = false
            return
        }

        let preset = selectedColorPreset
        let sensitivity = sensitivity
        let minimumArea = minimumArea
        isPreviewUpdating = true

        previewTask = Task {
            // Debounce slider-driven updates so we do not run HSV segmentation for every tick.
            if debounceNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: debounceNanoseconds)
            }
            guard !Task.isCancelled else { return }

            // Heavy image processing runs off the main actor to keep slider interaction responsive.
            let analysis = await Task.detached(priority: .userInitiated) {
                service.previewAnalysis(
                    image: image,
                    preset: preset,
                    sensitivity: sensitivity,
                    minimumArea: minimumArea
                )
            }.value

            guard !Task.isCancelled else { return }
            applyPreviewAnalysis(analysis)
        }
    }

    func updateMinimumArea(_ area: Double) {
        minimumArea = area
        // Minimum area affects which candidate centroids are highlighted in preview.
        isPreviewStale = true
        updatePreviewComponentCount()
    }

    private func applyPreviewAnalysis(_ analysis: ColorSegmentationPreviewAnalysis?) {
        isPreviewUpdating = false

        guard let analysis else {
            previewImage = nil
            previewComponentAreas = []
            previewComponentCount = 0
            previewPassingComponentCount = 0
            lastPreviewUpdatedAt = nil
            isPreviewStale = false
            return
        }

        previewImage = analysis.previewImage
        previewComponentAreas = analysis.componentAreas
        previewComponentCount = previewComponentAreas.count
        lastPreviewUpdatedAt = Date()
        isPreviewStale = false
        updatePreviewComponentCount()
    }

    private func updatePreviewComponentCount() {
        let minimumAreaValue = max(1, Int(minimumArea.rounded()))
        previewPassingComponentCount = previewComponentAreas.reduce(into: 0) { count, area in
            if area >= minimumAreaValue {
                count += 1
            }
        }
    }
}
