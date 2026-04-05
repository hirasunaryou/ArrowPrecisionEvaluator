import SwiftUI

struct RootView: View {
    @EnvironmentObject private var flowViewModel: MeasurementFlowViewModel

    var body: some View {
        NavigationStack(path: $flowViewModel.path) {
            HomeView()
                .navigationDestination(for: AppScreen.self) { screen in
                    switch screen {
                    case .home:
                        HomeView()
                    case .acquisition:
                        ImageAcquisitionView()
                    case .calibration:
                        CalibrationView()
                    case .targetPoint:
                        TargetPointView()
                    case .segmentation:
                        ColorSegmentationView()
                    case .markerReview:
                        MarkerReviewView()
                    case .analysis:
                        AnalysisResultView()
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}
