import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    var selectedCategory: Category? = nil
    var searchText: String = ""
    var showGrid: Bool = true

    // Bons filtrés + triés : expiration urgente en premier, puis date d'ajout décroissante
    func filteredCoupons(_ coupons: [Coupon]) -> [Coupon] {
        let base = coupons.filter { coupon in
            guard !coupon.isUsed, !coupon.isExpired else { return false }
            let matchesCategory = selectedCategory == nil || coupon.category == selectedCategory
            let matchesSearch   = searchText.isEmpty
                || coupon.brand.localizedCaseInsensitiveContains(searchText)
                || coupon.value.localizedCaseInsensitiveContains(searchText)
                || coupon.code.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }

        return base.sorted { a, b in
            let aUrgent = a.isExpiringSoon
            let bUrgent = b.isExpiringSoon

            // Les bons urgents passent en tête
            if aUrgent != bUrgent { return aUrgent }

            // Les deux urgents : le plus proche d'expirer en premier
            if aUrgent {
                return (a.expirationDate ?? .distantFuture) < (b.expirationDate ?? .distantFuture)
            }

            // Les deux normaux : le plus récemment ajouté en premier
            return a.createdAt > b.createdAt
        }
    }

    func expiringSoonCoupons(_ coupons: [Coupon]) -> [Coupon] {
        coupons
            .filter { $0.isExpiringSoon && !$0.isUsed }
            .sorted { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
    }

    func canAddCoupon(currentCount: Int, subscription: UserSubscription) -> Bool {
        subscription.isPremium || currentCount < UserSubscription.maxFreeCoupons
    }
}
