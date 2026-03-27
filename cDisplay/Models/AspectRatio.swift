import Foundation

enum AspectRatio: String, CaseIterable, Codable {
    case widescreen   = "16:9"
    case standard     = "4:3"
    case cinemascope  = "2.39:1"
    case square       = "1:1"
    case vertical     = "9:16"

    var ratio: Double {
        switch self {
        case .widescreen:  return 16.0 / 9.0
        case .standard:    return 4.0 / 3.0
        case .cinemascope: return 2.39
        case .square:      return 1.0
        case .vertical:    return 9.0 / 16.0
        }
    }

    var displayName: String {
        switch self {
        case .widescreen:  return "Widescreen (16:9)"
        case .standard:    return "Standard (4:3)"
        case .cinemascope: return "CinemaScope (2.39:1)"
        case .square:      return "Square (1:1)"
        case .vertical:    return "Vertical (9:16)"
        }
    }
}
