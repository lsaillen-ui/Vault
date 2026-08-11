import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var limitReached: Bool = false

    @State private var selectedPlan: ProductID = .annual
    @State private var isRestoring = false
    @State private var showRestoredAlert = false
    @State private var errorMessage: String?

    private let service = SubscriptionService.shared

    private let features: [(icon: String, color: Color, text: String)] = [
        ("infinity.circle.fill",  .blue,   "Bons illimités"),
        ("bell.badge.fill",       .orange, "Rappels avancés : J-7, J-3, J-1"),
        ("icloud.fill",           .blue,   "Sync iCloud multi-appareils"),
        ("chart.bar.fill",        .green,  "Stats d'économies"),
        ("wallet.pass.fill",      .purple, "Export Apple Wallet"),
        ("eye.slash.fill",        .red,    "Zéro publicité"),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color.yellow.opacity(0.10), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .init(x: 0.5, y: 0.35)
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if limitReached { limitBanner }
                        headerSection
                        featuresSection
                        plansSection
                        purchaseButton
                        legalSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, limitReached ? 12 : 8)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .task {
                if service.products.isEmpty {
                    await service.loadProducts()
                }
            }
            .alert("Achats restaurés ✓", isPresented: $showRestoredAlert) {
                Button("Super !") { dismiss() }
            } message: {
                Text("Ton abonnement Premium est maintenant actif.")
            }
            .alert("Erreur", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Bannière limite atteinte

    private var limitBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.callout)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("Limite de \(UserSubscription.maxFreeCoupons) bons atteinte")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Passe à Premium pour en ajouter plus.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel("Limite de \(UserSubscription.maxFreeCoupons) bons atteinte. Passe à Premium pour débloquer les bons illimités.")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow.opacity(0.30), Color.orange.opacity(0.12), .clear],
                            center: .center, startRadius: 0, endRadius: 56
                        )
                    )
                    .frame(width: 112, height: 112)
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.top, 8)
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Vault Premium")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Tout ce qu'il faut pour ne jamais\nperdre un bon de réduction.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Liste des avantages

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.element.text) { index, feature in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(feature.color.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: feature.icon)
                            .font(.callout)
                            .foregroundStyle(feature.color)
                    }
                    .accessibilityHidden(true)

                    Text(feature.text)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .accessibilityElement(children: .combine)

                if index < features.count - 1 {
                    Divider()
                        .padding(.leading, 66)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Sélection du plan

    @ViewBuilder
    private var plansSection: some View {
        if service.products.isEmpty {
            // Chargement des offres en cours
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.1)
                    .tint(.blue)
                Text("Chargement des offres…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityLabel("Chargement des offres en cours")
        } else {
            VStack(spacing: 10) {
                planCard(
                    id: .annual,
                    title: "Annuel",
                    price: service.annualProduct?.displayPrice ?? "CHF 14.99",
                    period: "/an",
                    note: "soit CHF 1.25/mois",
                    badge: "Économise 37%"
                )
                planCard(
                    id: .monthly,
                    title: "Mensuel",
                    price: service.monthlyProduct?.displayPrice ?? "CHF 1.99",
                    period: "/mois",
                    note: "Flexible, sans engagement",
                    badge: nil
                )
            }
        }
    }

    private func planCard(id: ProductID, title: String, price: String, period: String, note: String, badge: String?) -> some View {
        let isSelected = selectedPlan == id

        return Button {
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) { selectedPlan = id }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.35), lineWidth: 2)
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Circle()
                                .fill(.blue)
                                .frame(width: 12, height: 12)
                                .transition(.scale)
                        }
                    }
                    .animation(.spring(duration: 0.25, bounce: 0.2), value: isSelected)
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(price)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Text(period)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(isSelected ? Color.blue.opacity(0.07) : Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(isSelected ? Color.blue.opacity(0.9) : Color.clear, lineWidth: 1.5)
                )

                if let badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .clipShape(Capsule())
                        .offset(x: -10, y: -9)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
        .accessibilityLabel("\(title), \(price)\(period). \(note)\(badge != nil ? ". \(badge!)" : "")\(isSelected ? ". Sélectionné" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Bouton d'achat

    private var purchaseButtonLabel: String {
        switch selectedPlan {
        case .annual:
            let price = service.annualProduct?.displayPrice ?? "CHF 14.99"
            return "Continuer — \(price)/an"
        case .monthly:
            let price = service.monthlyProduct?.displayPrice ?? "CHF 1.99"
            return "Continuer — \(price)/mois"
        }
    }

    private var purchaseButton: some View {
        Button {
            Task { await handlePurchase() }
        } label: {
            Group {
                if service.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(purchaseButtonLabel)
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: service.products.isEmpty
                        ? [Color.gray.opacity(0.4), Color.gray.opacity(0.4)]
                        : [.blue, Color(red: 0.1, green: 0.3, blue: 0.9)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: service.products.isEmpty ? .clear : .blue.opacity(0.25), radius: 10, y: 4)
        }
        .disabled(service.isPurchasing || service.products.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: service.isPurchasing)
        .animation(.easeInOut(duration: 0.3), value: service.products.isEmpty)
        .accessibilityLabel(service.products.isEmpty ? "Chargement en cours" : purchaseButtonLabel)
        .accessibilityHint(service.products.isEmpty ? "" : "Démarre le processus d'achat sécurisé via l'App Store")
    }

    // MARK: - Pied légal (requis Apple)

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("L'abonnement se renouvelle automatiquement au tarif indiqué, sauf résiliation au moins 24h avant la fin de la période en cours depuis les Réglages de l'App Store.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Link("Conditions d'utilisation", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Politique de confidentialité", destination: URL(string: "https://example.com/privacy")!)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Fermer")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await handleRestore() }
            } label: {
                if isRestoring {
                    ProgressView().scaleEffect(0.85)
                } else {
                    Text("Restaurer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(isRestoring || service.isPurchasing)
            .accessibilityLabel(isRestoring ? "Restauration en cours" : "Restaurer mes achats")
        }
    }

    // MARK: - Actions

    private func handlePurchase() async {
        let product: Product?
        switch selectedPlan {
        case .annual:  product = service.annualProduct
        case .monthly: product = service.monthlyProduct
        }

        guard let product else {
            await service.loadProducts()
            return
        }

        await service.purchase(product)

        if service.subscription.isPremium {
            dismiss()
        } else if let err = service.purchaseError {
            errorMessage = err
        }
    }

    private func handleRestore() async {
        isRestoring = true
        do {
            try await service.restore()
            if service.subscription.isPremium {
                showRestoredAlert = true
            } else {
                errorMessage = "Aucun abonnement actif trouvé pour ce compte Apple ID."
            }
        } catch {
            errorMessage = "Restauration impossible. Vérifie ta connexion et réessaie."
        }
        isRestoring = false
    }
}

// MARK: - Preview

#Preview {
    PaywallView(limitReached: true)
}
