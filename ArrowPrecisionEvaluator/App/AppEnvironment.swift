import Foundation

final class AppEnvironment: ObservableObject {
    @Published var flowViewModel: MeasurementFlowViewModel
    @Published var settingsViewModel: SettingsViewModel

    init() {
        let settingsStore = SettingsStore()
        let settings = settingsStore.load()

        self.flowViewModel = MeasurementFlowViewModel(settings: settings)
        self.settingsViewModel = SettingsViewModel(settingsStore: settingsStore, initialSettings: settings)
    }
}
