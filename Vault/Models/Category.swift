import SwiftUI

enum Category: String, CaseIterable, Codable, Identifiable {
    case mode          = "Mode"
    case restauFood    = "Restau & Food"
    case cartessCadeaux = "Cartes cadeaux"
    case loisirs       = "Loisirs"
    case voyage        = "Voyage"
    case beauteSante   = "Beauté & Santé"
    case maison        = "Maison"
    case techJeux      = "Tech & Jeux"
    case autres        = "Autres"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .mode:           return "tshirt.fill"
        case .restauFood:     return "fork.knife"
        case .cartessCadeaux: return "gift.fill"
        case .loisirs:        return "figure.play"
        case .voyage:         return "airplane"
        case .beauteSante:    return "sparkles"
        case .maison:         return "house.fill"
        case .techJeux:       return "gamecontroller.fill"
        case .autres:         return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .mode:           return Color(hex: "FF6B9D")
        case .restauFood:     return Color(hex: "FF9500")
        case .cartessCadeaux: return Color(hex: "AF52DE")
        case .loisirs:        return Color(hex: "30D158")
        case .voyage:         return Color(hex: "32ADE6")
        case .beauteSante:    return Color(hex: "FF2D55")
        case .maison:         return Color(hex: "5856D6")
        case .techJeux:       return Color(hex: "007AFF")
        case .autres:         return Color(hex: "8E8E93")
        }
    }

    var defaultCardHex: String {
        switch self {
        case .mode:           return "FF6B9D"
        case .restauFood:     return "FF9500"
        case .cartessCadeaux: return "AF52DE"
        case .loisirs:        return "30D158"
        case .voyage:         return "32ADE6"
        case .beauteSante:    return "FF2D55"
        case .maison:         return "5856D6"
        case .techJeux:       return "007AFF"
        case .autres:         return "8E8E93"
        }
    }
}
