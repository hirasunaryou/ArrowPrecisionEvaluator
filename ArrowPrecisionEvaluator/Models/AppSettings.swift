import Foundation

struct AppSettings: Codable, Hashable {
    var defaultUseCenterTarget: Bool
    var defaultColorPreset: ColorPreset
    var defaultSensitivity: Double
    var defaultMinimumMarkerArea: Double

    static let `default` = AppSettings(
        defaultUseCenterTarget: true,
        defaultColorPreset: .red,
        defaultSensitivity: 0.5,
        defaultMinimumMarkerArea: 30
    )
}
