import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Query private var coupons: [Coupon]

    @State private var showPaywall = false
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined

    private var subscription: UserSubscription { SubscriptionService.shared.subscription }
    private var syncStatus: SyncStatus         { SyncService.shared.status }

    private var activeCoupons: Int  { coupons.filter { !$0.isUsed && !$0.isExpired }.count }
    private var usedCoupons: Int    { coupons.filter(\.isUsed).count }
    private var notifEnabled: Bool  { notifStatus == .authorized || notifStatus == .provisional }

    var body: some View {
        NavigationStack {
            List {
                subscriptionSection
                iCloudSyncSection
                notificationsSection
                dataSection
                aboutSection
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.large)
            .task { await refreshNotifStatus() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Section abonnement

    private var subscriptionSection: some View {
        Section("Abonnement") {
            if subscription.isPremium {
                premiumRow
            } else {
                freeRow
            }
        }
    }

    private var premiumRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "crown.fill")
                    .font(.callout)
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                    )
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Vault Premium")
                    .fontWeight(.semibold)
                if let exp = subscription.expirationDate {
                    Text("Renouvellement le \(exp.formatted(.dateTime.day().month().year()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Bons illimités · Sync iCloud · Zéro pub")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.vertical, 2)
    }

    private var freeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Plan Gratuit")
                    .fontWeight(.semibold)
                Text("\(activeCoupons)/\(UserSubscription.maxFreeCoupons) bons utilisés")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Passer Premium") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showPaywall = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .accessibilityLabel("Passer à Vault Premium — bons illimités, sync iCloud, zéro publicité")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Section sync iCloud

    private var iCloudSyncSection: some View {
        Section {
            syncStatusRow
        } header: {
            Text("Synchronisation iCloud")
        } footer: {
            syncFooterText
        }
    }

    @ViewBuilder
    private var syncStatusRow: some View {
        HStack(spacing: 12) {
            // Indicateur coloré
            Circle()
                .fill(syncIndicatorColor)
                .frame(width: 10, height: 10)
                .padding(.leading, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(syncTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(syncSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Bouton d'action contextuel
            if case .noAccount = syncStatus {
                Button("Réglages iCloud") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private var syncIndicatorColor: Color {
        switch syncStatus {
        case .active:                       return .green
        case .restartRequired:              return .orange
        case .notPremium:                   return Color(.systemGray4)
        case .noAccount, .error:            return .red
        }
    }

    private var syncTitle: String {
        switch syncStatus {
        case .active:                       return "Synchronisation active"
        case .restartRequired(let enabling):
            return enabling ? "Prêt à activer la sync" : "Prêt à désactiver la sync"
        case .notPremium:                   return "Sync iCloud désactivée"
        case .noAccount:                    return "Compte iCloud requis"
        case .error:                        return "Erreur de synchronisation"
        }
    }

    private var syncSubtitle: String {
        switch syncStatus {
        case .active:
            return "Tes bons se synchronisent sur tous tes appareils."
        case .restartRequired(let enabling):
            return enabling
                ? "Ferme et relance l'app pour activer la sync iCloud."
                : "Ferme et relance l'app pour désactiver la sync iCloud."
        case .notPremium:
            return "Disponible avec Vault Premium."
        case .noAccount:
            return "Connecte-toi à iCloud dans les Réglages iOS."
        case .error(let msg):
            return msg
        }
    }

    @ViewBuilder
    private var syncFooterText: some View {
        if case .active = syncStatus {
            Text("Les conflits entre appareils sont résolus automatiquement (dernière modification gagne).")
        }
    }

    // MARK: - Section notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            // On utilise une row custom plutôt qu'un Toggle :
            // iOS ne permet pas de révoquer la permission par code — seul l'utilisateur
            // peut le faire depuis Réglages. Le row affiche l'état + propose l'action adaptée.
            HStack {
                Label("Rappels d'expiration", systemImage: "bell.fill")
                Spacer()
                notifActionView
            }

            if notifEnabled {
                HStack(spacing: 8) {
                    Image(systemName: subscription.isPremium
                          ? "bell.and.waves.left.and.right.fill"
                          : "bell.fill")
                        .font(.caption)
                        .foregroundStyle(subscription.isPremium ? .blue : .orange)
                    Text(subscription.isPremium
                         ? "Rappels J-7, J-3 et J-1 activés."
                         : "Rappel J-1 inclus. Rappels J-7 et J-3 disponibles en Premium.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var notifActionView: some View {
        switch notifStatus {
        case .authorized, .provisional:
            // Activé → indiquer que c'est actif + lien pour désactiver dans Réglages
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Button("Gérer") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
        case .denied:
            // Refusé → lien direct vers Réglages iOS
            Button("Activer dans Réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline).buttonStyle(.bordered).tint(.orange)
        default:
            // Pas encore demandé
            Button("Activer") { Task { await handleNotifTap() } }
                .font(.subheadline).buttonStyle(.borderedProminent).tint(.orange)
        }
    }

    // MARK: - Section données

    private var dataSection: some View {
        Section("Données") {
            LabeledContent("Bons actifs",       value: "\(activeCoupons)")
            LabeledContent("Bons utilisés",     value: "\(usedCoupons)")
            LabeledContent("Total sauvegardés", value: "\(coupons.count)")

            NavigationLink(destination: SavingsStatsView()) {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(subscription.isPremium ? .blue : Color(.systemGray3))
                    Text("Statistiques d'économies")
                    if !subscription.isPremium {
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
    }

    // MARK: - Section à propos

    private var aboutSection: some View {
        Section("À propos") {
            LabeledContent("Version", value: "1.0.0")
            Link("Politique de confidentialité", destination: URL(string: "https://example.com/privacy")!)
            Link("Conditions d'utilisation",     destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        }
    }

    // MARK: - Actions

    private func refreshNotifStatus() async {
        notifStatus = await NotificationService.shared.authorizationStatus()
    }

    private func handleNotifTap() async {
        await NotificationService.shared.requestAuthorization()
        await refreshNotifStatus()
    }
}
