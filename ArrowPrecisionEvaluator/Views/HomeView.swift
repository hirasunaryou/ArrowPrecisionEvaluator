import SwiftUI

struct HomeView: View {
    @ObservedObject var flowViewModel: MeasurementFlowViewModel
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Arrow Precision Evaluator")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(viewModel.welcomeMessage())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button("Start New Measurement") {
                    flowViewModel.startNewMeasurement()
                }
                .buttonStyle(.borderedProminent)

                Button("Settings") {
                    flowViewModel.goToSettings()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Home")
    }
}
