import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
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
                    environment.flowViewModel.startNewMeasurement()
                }
                .buttonStyle(.borderedProminent)

                Button("Settings") {
                    environment.flowViewModel.goToSettings()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Home")
    }
}
