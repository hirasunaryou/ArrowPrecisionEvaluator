import SwiftUI

enum ColorPreset: String, CaseIterable, Codable, Identifiable {
    case red
    case blue
    case green
    case yellow
    case black

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .black: return "Black"
        }
    }

    var uiColor: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .yellow: return .yellow
        case .black: return .black
        }
    }
}
