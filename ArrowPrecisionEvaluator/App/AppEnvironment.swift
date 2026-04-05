import Foundation

final class AppEnvironment: ObservableObject {
    // NOTE:
    // These child view models are long-lived shared dependencies.
    // They are intentionally constants so their own @Published state
    // is observed directly by views that bind to them.
    let flowViewModel: MeasurementFlowViewModel
    let settingsViewModel: SettingsViewModel

    init() {
        let settingsStore = SettingsStore()
        let settings = settingsStore.load()

        self.flowViewModel = MeasurementFlowViewModel(settings: settings)
        self.settingsViewModel = SettingsViewModel(settingsStore: settingsStore, initialSettings: settings)
    }
}
