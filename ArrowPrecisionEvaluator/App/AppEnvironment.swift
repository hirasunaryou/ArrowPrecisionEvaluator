import Foundation

final class AppEnvironment: ObservableObject {
    // AppEnvironment owns long-lived view models and injects them into the view tree.
    let flowViewModel: MeasurementFlowViewModel
    let settingsViewModel: SettingsViewModel

    init() {
        let settingsStore = SettingsStore()
        let settings = settingsStore.load()

        self.flowViewModel = MeasurementFlowViewModel(settings: settings)
        self.settingsViewModel = SettingsViewModel(settingsStore: settingsStore, initialSettings: settings)
    }
}
