import Foundation

enum SubscriptionTier: String, CaseIterable {
    case free    = "Gratuit"
    case premium = "Premium"
}

struct UserSubscription {
    static let maxFreeCoupons = 5
    static let monthlyPrice   = 1.99
    static let yearlyPrice    = 14.99

    var tier: SubscriptionTier
    var expirationDate: Date?

    static let `default` = UserSubscription(tier: .free, expirationDate: nil)

    var isPremium: Bool {
        guard tier == .premium, let exp = expirationDate else { return false }
        return exp > .now
    }

    var canAddCoupon: Bool {
        // La vérification du count total se fait dans HomeViewModel
        return isPremium
    }
}
