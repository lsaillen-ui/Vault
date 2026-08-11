import Foundation
import SwiftUI

@Observable
final class AddCouponViewModel {
    var brand: String        = ""
    var value: String        = ""
    var code: String         = ""
    var category: Category   = .autres
    var expirationDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    var hasExpiration: Bool  = true
    var notes: String        = ""
    var cardColor: String    = Category.autres.defaultCardHex
    var source: CouponSource = .manual

    var isValid: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty &&
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func buildCoupon() -> Coupon {
        Coupon(
            brand: brand.trimmingCharacters(in: .whitespaces),
            value: value.trimmingCharacters(in: .whitespaces),
            code: code.trimmingCharacters(in: .whitespaces),
            category: category,
            expirationDate: hasExpiration ? expirationDate : nil,
            notes: notes.isEmpty ? nil : notes,
            cardColor: cardColor,
            source: source
        )
    }

    func reset() {
        brand = ""
        value = ""
        code = ""
        category = .autres
        expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
        hasExpiration = true
        notes = ""
        cardColor = Category.autres.defaultCardHex
        source = .manual
    }

    func syncColorWithCategory() {
        cardColor = category.defaultCardHex
    }
}
