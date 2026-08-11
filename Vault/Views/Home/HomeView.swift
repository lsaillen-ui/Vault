import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Coupon.createdAt, order: .reverse) private var coupons: [Coupon]

    @Binding var selectedTab: Int
    @State private var viewModel = HomeViewModel()

    private var isPremium: Bool { SubscriptionService.shared.subscription.isPremium }

    private var activeCoupons: [Coupon] { coupons.filter { !$0.isUsed && !$0.isExpired } }
    private var expiringSoon: [Coupon]  { viewModel.expiringSoonCoupons(coupons) }
    private var filtered: [Coupon]      { viewModel.filteredCoupons(coupons) }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        alertBanner
                        categoryChips
                        couponList
                    }
                    .padding(.bottom, 88) // espace sous le FAB
                }

                floatingAddButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Rechercher un bon…")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        NavigationLink(destination: SavingsStatsView()) {
                            Image(systemName: "chart.bar.fill").font(.callout)
                        }
                        .accessibilityLabel("Statistiques d'économies")

                        Button {
                            withAnimation(.spring(duration: 0.2)) { viewModel.showGrid.toggle() }
                        } label: {
                            Image(systemName: viewModel.showGrid ? "list.bullet" : "square.grid.2x2")
                        }
                        .accessibilityLabel(viewModel.showGrid ? "Passer en vue liste" : "Passer en vue grille")
                    }
                }
            }
            // Bannière pub en bas, uniquement pour les utilisateurs gratuits
           .safeAreaInset(edge: .bottom, spacing: 0) {
                if !isPremium {
                    AdBannerContainer()
                }
           
        
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Vault")
                    .font(.system(size: 42, weight: .bold, design: .serif))

                let n = activeCoupons.count
                Text(n == 0 ? "Aucun bon actif" : "\(n) bon\(n > 1 ? "s" : "") actif\(n > 1 ? "s" : "")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Avatar — navigue vers Réglages
            Button { selectedTab = 4 } label: {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 46, height: 46)
                    Image(systemName: "person.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.top, 6)
            .accessibilityLabel("Réglages")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Bandeau alerte

    @ViewBuilder
    private var alertBanner: some View {
        if !expiringSoon.isEmpty {
            Button { selectedTab = 3 } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        let n = expiringSoon.count
                        Text("\(n) bon\(n > 1 ? "s expirent" : " expire") bientôt")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("Voir les alertes →")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    // Mini aperçu des 3 premiers
                    HStack(spacing: -8) {
                        ForEach(expiringSoon.prefix(3)) { coupon in
                            Circle()
                                .fill(Color(hex: coupon.cardColor))
                                .frame(width: 22, height: 22)
                                .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.orange.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Chips catégories

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil)
                ForEach(Category.allCases) { cat in
                    categoryChip(cat)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func categoryChip(_ category: Category?) -> some View {
        let isSelected = viewModel.selectedCategory == category
        let label = category?.displayName ?? "Tous"
        let color = category?.color ?? .blue

        return Button {
            withAnimation(.spring(duration: 0.2)) {
                viewModel.selectedCategory = category
            }
        } label: {
            HStack(spacing: 5) {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : color.opacity(0.1))
            .foregroundStyle(isSelected ? .white : color)
            .clipShape(Capsule())
            .animation(.spring(duration: 0.2), value: isSelected)
        }
    }

    // MARK: - Liste des bons

    @ViewBuilder
    private var couponList: some View {
        if filtered.isEmpty {
            emptyState
        } else if viewModel.showGrid {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filtered) { coupon in
                    NavigationLink(destination: CouponDetailView(coupon: coupon)) {
                        CouponCardView(coupon: coupon, isCompact: true)
                    }
                    .buttonStyle(CardPressStyle())
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(duration: 0.35, bounce: 0.15), value: filtered.map(\.id))
        } else {
            LazyVStack(spacing: 12) {
                ForEach(filtered) { coupon in
                    NavigationLink(destination: CouponDetailView(coupon: coupon)) {
                        CouponCardView(coupon: coupon, isCompact: true)
                    }
                    .buttonStyle(CardPressStyle())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(duration: 0.35, bounce: 0.1), value: filtered.map(\.id))
        }
    }

    // MARK: - État vide

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.07))
                    .frame(width: 130, height: 130)
                Circle()
                    .fill(.blue.opacity(0.05))
                    .frame(width: 100, height: 100)
                Image(systemName: "ticket.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue.opacity(0.4))
            }

            VStack(spacing: 8) {
                Text(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil
                     ? "Aucun bon pour l'instant"
                     : "Aucun résultat")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(viewModel.searchText.isEmpty && viewModel.selectedCategory == nil
                     ? "Appuie sur + pour ajouter\nton premier coupon ou bon de réduction."
                     : "Essaie un autre filtre ou une autre recherche.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if viewModel.searchText.isEmpty && viewModel.selectedCategory == nil {
                Button {
                    selectedTab = 2
                } label: {
                    Label("Ajouter un bon", systemImage: "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.horizontal, 32)
    }

    // MARK: - Bouton flottant +

    private var floatingAddButton: some View {
        Button { selectedTab = 2 } label: {
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 58, height: 58)
                    .shadow(color: .blue.opacity(0.4), radius: 14, x: 0, y: 6)
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(FabPressStyle())
        .padding(.trailing, 20)
        .padding(.bottom, 16)
        .accessibilityLabel("Ajouter un bon")
    }
}

// MARK: - Button styles

/// Légère réduction au press — appliquée sur les cartes NavigationLink.
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.1), value: configuration.isPressed)
    }
}

/// Réduction + légère rotation au press — pour le FAB.
private struct FabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .rotationEffect(.degrees(configuration.isPressed ? 45 : 0))
            .animation(.spring(duration: 0.25, bounce: 0.3), value: configuration.isPressed)
    }
}
