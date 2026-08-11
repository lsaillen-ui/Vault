import Foundation
import StoreKit

// MARK: - Identifiants produits App Store Connect
// TODO : créer ces produits dans App Store Connect avant soumission

enum ProductID: String, CaseIterable {
    case monthly = "com.vault.monthly"
    case annual  = "com.vault.annual"
}

// MARK: - Service abonnement

@MainActor
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    var subscription: UserSubscription = .default
    var products: [Product] = []
    var isPurchasing = false
    var purchaseError: String?

    private var listenerTask: Task<Void, Never>?

    private init() {}

    // MARK: - Démarrage

    /// Démarre le listener de transactions et charge les produits.
    /// Appeler une seule fois depuis AppRootView.task{} au lancement.
    func startListening() {
        listenerTask?.cancel()
        listenerTask = Task { await listenForTransactions() }
        Task { await loadProducts() }
        Task { await refreshStatus() }
    }

    // MARK: - Produits

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            // Tri : mensuel (moins cher) en premier, annuel en second
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            print("[StoreKit] Chargement produits échoué: \(error)")
        }
    }

    // MARK: - Achat

    func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                applyTransaction(tx)
                await tx.finish()
            case .userCancelled, .pending:
                // .pending = en attente de validation parentale, pas d'erreur à afficher
                ()
            @unknown default:
                ()
            }
        } catch {
            purchaseError = "L'achat a échoué. Réessaie plus tard."
            print("[StoreKit] Erreur achat: \(error)")
        }
    }

    // MARK: - Restauration

    /// Lance AppStore.sync() pour récupérer les transactions manquantes.
    /// Throws si la restauration échoue (ex: pas de connexion).
    func restore() async throws {
        try await AppStore.sync()
        await refreshStatus()
    }

    // MARK: - Vérification du statut courant

    func refreshStatus() async {
        var foundActive = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  ProductID(rawValue: tx.productID) != nil,
                  tx.revocationDate == nil else { continue }
            applyTransaction(tx)
            foundActive = true
            break
        }
        if !foundActive { subscription = .default }
    }

    // MARK: - Gate freemium

    /// Retourne true si l'utilisateur peut ajouter un bon supplémentaire.
    func canAddCoupon(currentCount: Int) -> Bool {
        subscription.isPremium || currentCount < UserSubscription.maxFreeCoupons
    }

    // MARK: - Accesseurs produits (pratiques pour les vues)

    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthly.rawValue }
    }

    var annualProduct: Product? {
        products.first { $0.id == ProductID.annual.rawValue }
    }

    // MARK: - Privé

    /// Écoute en continu les nouvelles transactions (achats, renouvellements, révocations).
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let tx = try checkVerified(result)
                if tx.revocationDate != nil {
                    subscription = .default
                } else {
                    applyTransaction(tx)
                }
                await tx.finish()
            } catch {
                print("[StoreKit] Transaction invalide: \(error)")
            }
        }
    }

    private func applyTransaction(_ tx: Transaction) {
        subscription = UserSubscription(tier: .premium, expirationDate: tx.expirationDate)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }
}
