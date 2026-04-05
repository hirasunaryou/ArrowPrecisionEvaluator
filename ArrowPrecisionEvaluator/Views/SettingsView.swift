import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        Form {
            Toggle("Use Center Target by Default", isOn: $environment.settingsViewModel.settings.defaultUseCenterTarget)

            Picker("Default Color", selection: $environment.settingsViewModel.settings.defaultColorPreset) {
                ForEach(ColorPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }

            VStack(alignment: .leading) {
                Text("Default Sensitivity: \(environment.settingsViewModel.settings.defaultSensitivity, specifier: "%.2f")")
                Slider(value: $environment.settingsViewModel.settings.defaultSensitivity, in: 0...1)
            }

            VStack(alignment: .leading) {
                Text("Default Minimum Area: \(Int(environment.settingsViewModel.settings.defaultMinimumMarkerArea))")
                Slider(value: $environment.settingsViewModel.settings.defaultMinimumMarkerArea, in: 1...200, step: 1)
            }

            Button("Save Settings") {
                environment.settingsViewModel.save()
                environment.flowViewModel.settings = environment.settingsViewModel.settings
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Settings")
    }
}
