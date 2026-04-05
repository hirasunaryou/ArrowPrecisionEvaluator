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

    func refreshPreviewImmediately(
        with image: UIImage?,
        service: ColorSegmentationServiceProtocol
    ) {
        schedulePreviewRefresh(with: image, service: service, debounceNanoseconds: 0)
    }

    func markPreviewStale() {
        isPreviewStale = true
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
            isPreviewStale = false
            lastPreviewUpdatedAt = nil
            return
        }

        let preset = selectedColorPreset
        let sensitivity = sensitivity
        isPreviewUpdating = true

        previewTask = Task {
            // Optional debounce is kept for callers that may choose non-immediate refresh behavior.
            if debounceNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: debounceNanoseconds)
            }
            guard !Task.isCancelled else { return }

            // Heavy image processing runs off the main actor to keep slider interaction responsive.
            let analysis = await Task.detached(priority: .userInitiated) {
                service.previewAnalysis(
                    image: image,
                    preset: preset,
                    sensitivity: sensitivity
                )
            }.value

            guard !Task.isCancelled else { return }
            applyPreviewAnalysis(analysis)
        }
    }

    func updateMinimumArea(_ area: Double) {
        minimumArea = area
        // Minimum area affects the detection result even though the mask image may look unchanged.
        // Keep it immediate in UI and mark preview state as stale until user refreshes explicitly.
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
            isPreviewStale = true
            return
        }

        previewImage = analysis.previewImage
        previewComponentAreas = analysis.componentAreas
        previewComponentCount = previewComponentAreas.count
        isPreviewStale = false
        lastPreviewUpdatedAt = Date()
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
