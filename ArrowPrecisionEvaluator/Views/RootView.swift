import SwiftUI

struct RootView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @ObservedObject var flowViewModel: MeasurementFlowViewModel

    var body: some View {
        NavigationStack(path: $flowViewModel.path) {
            HomeView(flowViewModel: flowViewModel)
                .navigationDestination(for: AppScreen.self) { screen in
                    switch screen {
                    case .home:
                        HomeView(flowViewModel: flowViewModel)
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
