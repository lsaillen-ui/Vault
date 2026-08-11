import SwiftUI

// MARK: - Modèle de page

private struct OnboardingPage {
    let title: String
    let subtitle: String?
    let accent: Color
    let features: [(icon: String, color: Color, text: String)]

    init(title: String, subtitle: String? = nil, accent: Color, features: [(String, Color, String)] = []) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.features = features
    }
}

// MARK: - Onboarding principal

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Bienvenue dans Vault",
            subtitle: "Tous tes bons de réduction, coupons et cartes cadeaux au même endroit.\nPlus jamais perdus, plus jamais oubliés.",
            accent: .blue
        ),
        OnboardingPage(
            title: "Ajoute tes bons\nen 3 clics",
            accent: .green,
            features: [
                ("pencil.circle.fill",         .blue,   "Saisie manuelle — marque, valeur, code, date"),
                ("qrcode.viewfinder",           .green,  "Scan QR code ou code-barres en une seconde"),
                ("square.and.arrow.up.fill",    .orange, "Share Extension — depuis Safari ou toute autre app"),
            ]
        ),
        OnboardingPage(
            title: "Ne rate plus jamais\nune offre",
            accent: .orange,
            features: [
                ("bell.badge.fill",             .orange, "Rappels automatiques avant expiration"),
                ("square.grid.2x2.fill",        .blue,   "Organisés par catégorie, filtrables"),
                ("chart.bar.fill",              .purple, "Statistiques d'économies avec Premium"),
            ]
        ),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fond adaptatif à la page courante
            pages[currentPage].accent.opacity(0.06)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Bouton Skip (haut-droite)
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Passer") { complete() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 20)
                            .padding(.top, 56)
                            .transition(.opacity)
                    }
                }
                .frame(height: 72)
                .animation(.easeInOut(duration: 0.2), value: currentPage)

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                        pageContent(page, index: i)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(duration: 0.45), value: currentPage)

                // Bas : indicateurs + bouton
                VStack(spacing: 20) {
                    pageIndicators

                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(duration: 0.4)) { currentPage += 1 }
                        } else {
                            complete()
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Commencer" : "Suivant")
                            .font(.body)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(pages[currentPage].accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: pages[currentPage].accent.opacity(0.3), radius: 8, y: 3)
                    }
                    .animation(.spring(duration: 0.3), value: currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Page content

    private func pageContent(_ page: OnboardingPage, index: Int) -> some View {
        VStack(spacing: 0) {
            // Illustration
            pageIllustration(for: index, accent: page.accent)
                .frame(height: 220)
                .padding(.top, 8)

            // Titre
            VStack(spacing: 10) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if let sub = page.subtitle {
                    Text(sub)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            // Liste de fonctionnalités
            if !page.features.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(page.features, id: \.text) { icon, color, text in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(color.opacity(0.12))
                                    .frame(width: 42, height: 42)
                                Image(systemName: icon)
                                    .font(.callout)
                                    .foregroundStyle(color)
                            }
                            Text(text)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 20)
            }

            Spacer()
        }
    }

    // MARK: - Illustrations par page

    @ViewBuilder
    private func pageIllustration(for index: Int, accent: Color) -> some View {
        switch index {
        case 0:  WelcomeIllustration(accent: accent)
        case 1:  AddMethodsIllustration(accent: accent)
        default: AlertsIllustration(accent: accent)
        }
    }

    // MARK: - Indicateurs de page

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? pages[currentPage].accent : Color(.systemGray4))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: currentPage)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Action

    private func complete() {
        UserDefaults.standard.set(true, forKey: "vault.onboarding.completed")
        withAnimation(.spring(duration: 0.5)) { onComplete() }
    }
}

// MARK: - Illustrations

private struct WelcomeIllustration: View {
    let accent: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            // Pile de cartes colorées
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [cardColors[i], cardColors[i].opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 140)
                    .overlay(
                        // Mini contenu de carte
                        VStack(alignment: .leading, spacing: 6) {
                            Text(["ZALANDO", "McDONALD'S", "FNAC"][i].uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1.2)
                                .foregroundStyle(.white.opacity(0.65))
                            Text(["-20%", "CHF 25", "-10%"][i])
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(14),
                        alignment: .topLeading
                    )
                    .rotationEffect(.degrees(Double(i - 1) * (animate ? 10 : 0)))
                    .offset(y: Double(i - 1) * (animate ? -10 : 0))
                    .scaleEffect(animate ? (i == 1 ? 1.0 : 0.92) : 0.85)
                    .animation(
                        .spring(duration: 0.7, bounce: 0.35).delay(Double(i) * 0.08),
                        value: animate
                    )
                    .zIndex(Double(i == 1 ? 3 : 2 - i))
                    .shadow(color: cardColors[i].opacity(0.35), radius: 10, y: 6)
            }
        }
        .onAppear { withAnimation { animate = true } }
    }

    private let cardColors: [Color] = [
        Color(red: 0.5, green: 0.35, blue: 0.85),
        Color(red: 0.2, green: 0.55, blue: 1.0),
        Color(red: 1.0, green: 0.45, blue: 0.3),
    ]
}

private struct AddMethodsIllustration: View {
    let accent: Color
    @State private var animate = false

    private let methods: [(icon: String, color: Color, label: String)] = [
        ("pencil.circle.fill",        .blue,   "Manuel"),
        ("qrcode.viewfinder",         .green,  "Scanner"),
        ("square.and.arrow.up.fill",  .orange, "Partager"),
    ]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(Array(methods.enumerated()), id: \.offset) { i, method in
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(method.color.opacity(0.12))
                            .frame(width: 68, height: 68)
                        Image(systemName: method.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(method.color)
                    }
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.4).delay(Double(i) * 0.12), value: animate)

                    Text(method.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(Double(i) * 0.12 + 0.2), value: animate)
                }
            }
        }
        .onAppear { withAnimation { animate = true } }
    }
}

private struct AlertsIllustration: View {
    let accent: Color
    @State private var animate = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Cercles pulsants
            Circle()
                .stroke(accent.opacity(pulse ? 0.0 : 0.15), lineWidth: 1.5)
                .frame(width: pulse ? 160 : 80, height: pulse ? 160 : 80)
                .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse)

            Circle()
                .stroke(accent.opacity(pulse ? 0.0 : 0.1), lineWidth: 1)
                .frame(width: pulse ? 200 : 100, height: pulse ? 200 : 100)
                .animation(.easeOut(duration: 1.2).delay(0.3).repeatForever(autoreverses: false), value: pulse)

            // Icône centrale
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(accent)
                    .scaleEffect(animate ? 1 : 0.4)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.4), value: animate)
            }

            // Badges de jours
            ForEach([("-7j", CGSize(width: -75, height: -25)),
                     ("-3j", CGSize(width: 72, height: 10)),
                     ("-1j", CGSize(width: -55, height: 45))], id: \.0) { label, offset in
                Text(label)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent)
                    .clipShape(Capsule())
                    .offset(x: offset.width, y: offset.height)
                    .opacity(animate ? 1 : 0)
                    .scaleEffect(animate ? 1 : 0.5)
                    .animation(.spring(duration: 0.4, bounce: 0.3).delay(0.3), value: animate)
            }
        }
        .onAppear {
            withAnimation { animate = true }
            withAnimation(.linear(duration: 0.1).delay(0.2)) { pulse = true }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView { }
}
