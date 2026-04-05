import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings

    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore, initialSettings: AppSettings) {
        self.settingsStore = settingsStore
        self.settings = initialSettings
    }

    func save() {
        settingsStore.save(settings)
    }
}
