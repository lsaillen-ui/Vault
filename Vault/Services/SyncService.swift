import Foundation
import CloudKit

// MARK: - État de la synchronisation

enum SyncStatus: Equatable {
    case notPremium                   // Utilisateur gratuit — sync désactivée
    case noAccount                    // Premium mais pas connecté à iCloud
    case active                       // Premium + iCloud disponible + sync en cours
    case restartRequired(enabling: Bool) // Statut premium a changé, redémarrage requis
    case error(String)                // Erreur CloudKit
}

// MARK: - Service de synchronisation iCloud

/// Responsabilités :
/// 1. Mettre en cache le statut premium dans UserDefaults pour la décision de container au prochain démarrage
/// 2. Surveiller le compte iCloud via CKContainer
/// 3. Exposer SyncStatus pour l'indicateur dans SettingsView
@MainActor
@Observable
final class SyncService {
    static let shared = SyncService()

    // MARK: - Clés UserDefaults

    /// Statut premium mis en cache — lu par VaultApp.sharedModelContainer au démarrage
    static let cloudKitEnabledKey = "vault.sync.cloudkit.enabled"
    /// Vrai si le statut a changé lors de cette session (redémarrage requis)
    static let restartNeededKey   = "vault.sync.restart.needed"

    /// Identifiant du container CloudKit — doit correspondre à l'entitlement et au portail Developer
    static let cloudKitContainerID = "iCloud.Koveo.Vault"

    // MARK: - État observable

    private(set) var status: SyncStatus = .notPremium

    private init() {}

    // MARK: - Mise à jour depuis SubscriptionService

    /// Appelé chaque fois que le statut premium change.
    /// Met à jour le cache UserDefaults et détermine si un redémarrage est nécessaire.
    func updateSyncState(isPremium: Bool) async {
        let wasEnabled = UserDefaults.standard.bool(forKey: Self.cloudKitEnabledKey)

        if isPremium != wasEnabled {
            // Le statut a changé → mise à jour du cache + flag de redémarrage
            UserDefaults.standard.set(isPremium, forKey: Self.cloudKitEnabledKey)
            UserDefaults.standard.set(true, forKey: Self.restartNeededKey)
            status = .restartRequired(enabling: isPremium)
            return
        }

        await refreshStatus(isPremium: isPremium)
    }

    /// Rafraîchit le statut sans modifier le cache.
    func refreshStatus(isPremium: Bool) async {
        if UserDefaults.standard.bool(forKey: Self.restartNeededKey) {
            // Déterminer le sens du changement depuis le cache
            let enabling = UserDefaults.standard.bool(forKey: Self.cloudKitEnabledKey)
            status = .restartRequired(enabling: enabling)
            return
        }

        guard isPremium else {
            status = .notPremium
            return
        }

        await checkiCloudAccount()
    }

    /// Efface le flag de redémarrage — appelé au prochain démarrage de l'app (dans VaultApp).
    func clearRestartFlag() {
        UserDefaults.standard.set(false, forKey: Self.restartNeededKey)
    }

    // MARK: - Vérification du compte iCloud

    private func checkiCloudAccount() async {
        let container = CKContainer(identifier: Self.cloudKitContainerID)
        do {
            let accountStatus = try await container.accountStatus()
            switch accountStatus {
            case .available:
                status = .active
            case .noAccount:
                status = .noAccount
            case .temporarilyUnavailable, .couldNotDetermine:
                status = .noAccount
            case .restricted:
                status = .error("Accès iCloud restreint par un profil de gestion.")
            @unknown default:
                status = .noAccount
            }
        } catch {
            status = .error("Impossible de vérifier le compte iCloud.")
            print("[CloudKit] Erreur vérification compte: \(error)")
        }
    }
}
