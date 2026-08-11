import StoreKit
import UIKit

// MARK: - Gestionnaire d'avis App Store

/// Déclenche une demande d'avis après que l'utilisateur a utilisé 3 bons.
/// Demande une seule fois — StoreKit limite lui-même à 3 fois par an.
@MainActor
enum ReviewManager {
    private static let usedCountKey = "vault.review.used.count"
    private static let requestedKey = "vault.review.requested"

    /// Appeler chaque fois qu'un bon est marqué "utilisé".
    static func onCouponUsed() {
        let count = UserDefaults.standard.integer(forKey: usedCountKey) + 1
        UserDefaults.standard.set(count, forKey: usedCountKey)

        // Demande après exactement 3 bons utilisés, une seule fois
        guard count == 3,
              !UserDefaults.standard.bool(forKey: requestedKey)
        else { return }

        UserDefaults.standard.set(true, forKey: requestedKey)

        // Délai court : laisse l'animation "utilisé" se terminer avant d'afficher la popup
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            AppStore.requestReview(in: scene)
        }
    }
}
