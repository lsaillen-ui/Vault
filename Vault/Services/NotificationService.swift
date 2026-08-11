import Foundation
import UserNotifications

// MARK: - Service de notifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // Préfixe commun à tous les identifiants Vault — permet de les isoler proprement
    private let idPrefix = "vault-"

    // Clé UserDefaults pour éviter de re-demander la permission
    static let promptedKey = "vault.notif.prompted"

    // MARK: - Autorisation

    /// Vérifie le statut actuel sans rien afficher.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Demande la permission si elle n'a pas encore été déterminée.
    /// Appelé depuis NotificationPermissionSheet après que l'utilisateur a vu l'explication.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Planification pour un bon

    /// Planifie les rappels d'un bon. Annule d'abord les éventuels anciens.
    /// - Parameters:
    ///   - coupon: Le bon à rappeler.
    ///   - isPremium: Si true → J-7, J-3, J-1. Si false → J-1 uniquement.
    func schedule(for coupon: Coupon, isPremium: Bool) {
        guard let expiration = coupon.expirationDate,
              !coupon.isUsed,
              !coupon.isExpired
        else {
            cancel(for: coupon)
            return
        }

        // Annuler les anciennes notifications avant de replanifier
        cancel(for: coupon)

        let daysBefore = isPremium ? [7, 3, 1] : [1]

        for days in daysBefore {
            guard
                let triggerDate = Calendar.current.date(byAdding: .day, value: -days, to: expiration),
                triggerDate > .now
            else { continue }

            // Tir à 09:00 le jour J (pas à minuit)
            var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
            components.hour   = 9
            components.minute = 0

            let content      = makeContent(for: coupon, daysBefore: days)
            let trigger      = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request      = UNNotificationRequest(
                identifier: notifID(coupon: coupon, days: days),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    // MARK: - Annulation pour un bon

    func cancel(for coupon: Coupon) {
        let ids = [7, 3, 1].map { notifID(coupon: coupon, days: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Replanification globale (foreground app)

    /// Supprime toutes les notifications Vault en attente, puis replanifie
    /// pour chaque bon actif. À appeler au premier plan de l'app.
    func rescheduleAll(coupons: [Coupon], isPremium: Bool) {
        Task {
            // Récupère uniquement les notifs Vault existantes
            let pending = await center.pendingNotificationRequests()
            let vaultIDs = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: vaultIDs)

            // Replanifie pour les bons actifs non expirés
            for coupon in coupons where !coupon.isUsed && !coupon.isExpired {
                schedule(for: coupon, isPremium: isPremium)
            }
        }
    }

    // MARK: - Helpers privés

    private func notifID(coupon: Coupon, days: Int) -> String {
        "\(idPrefix)\(coupon.id.uuidString)-\(days)j"
    }

    private func makeContent(for coupon: Coupon, daysBefore days: Int) -> UNMutableNotificationContent {
        let content   = UNMutableNotificationContent()
        content.sound = .default
        content.badge = 1

        switch days {
        case 7:
            content.title = "🗓 \(coupon.brand) expire dans 7 jours"
            content.body  = "\(coupon.value) — Pense à l'utiliser bientôt."

        case 3:
            content.title = "⚠️ \(coupon.brand) expire dans 3 jours"
            content.body  = "\(coupon.value) — Plus que 3 jours pour en profiter !"

        default: // J-1
            content.title = "⏰ \(coupon.brand) expire demain !"
            content.body  = "\(coupon.value) — Dernière chance, utilise-le aujourd'hui !"
        }

        return content
    }
}
