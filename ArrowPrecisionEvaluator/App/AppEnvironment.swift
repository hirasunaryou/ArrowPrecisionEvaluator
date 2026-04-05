import Foundation

final class AppEnvironment: ObservableObject {
    // AppEnvironment owns long-lived view models and injects them into the view tree.
    let flowViewModel: MeasurementFlowViewModel
    // `var` is intentional: SwiftUI bindings in SettingsView need a writable key path
    // from AppEnvironment -> settingsViewModel -> settings.*
    var settingsViewModel: SettingsViewModel

    init() {
        let settingsStore = SettingsStore()
        let settings = settingsStore.load()

        self.flowViewModel = MeasurementFlowViewModel(settings: settings)
        self.settingsViewModel = SettingsViewModel(settingsStore: settingsStore, initialSettings: settings)
    }
}
