import Foundation
import SwiftData

enum CouponSource: String, Codable {
    case manual         = "manual"
    case scan           = "scan"
    case shareExtension = "shareExtension"
}

@Model
final class Coupon {
    var id: UUID
    var brand: String
    var value: String
    var code: String
    var category: Category
    var expirationDate: Date?
    var notes: String?
    var cardColor: String
    var createdAt: Date
    var isUsed: Bool
    /// Date à laquelle le bon a été marqué "utilisé" — nil pour les bons ajoutés avant cette fonctionnalité.
    var usedAt: Date?
    var source: CouponSource

    init(
        id: UUID = UUID(),
        brand: String,
        value: String,
        code: String,
        category: Category,
        expirationDate: Date? = nil,
        notes: String? = nil,
        cardColor: String? = nil,
        createdAt: Date = .now,
        isUsed: Bool = false,
        usedAt: Date? = nil,
        source: CouponSource = .manual
    ) {
        self.id = id
        self.brand = brand
        self.value = value
        self.code = code
        self.category = category
        self.expirationDate = expirationDate
        self.notes = notes
        self.cardColor = cardColor ?? category.defaultCardHex
        self.createdAt = createdAt
        self.isUsed = isUsed
        self.usedAt = usedAt
        self.source = source
    }

    var isExpired: Bool {
        guard let date = expirationDate else { return false }
        return date < .now
    }

    var isExpiringSoon: Bool {
        guard let date = expirationDate, !isExpired else { return false }
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        return days <= 7
    }

    var daysUntilExpiration: Int? {
        guard let date = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: date).day
    }
}
