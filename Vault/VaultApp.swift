import SwiftUI
import SwiftData

// MARK: - Point d'entrée

@main
struct VaultApp: App {

    init() {
       // AdMobService.shared.configure()
        // Efface le flag de redémarrage de la session précédente :
        // si on démarre, c'est que l'utilisateur a redémarré → la nouvelle config est active.
        SyncService.shared.clearRestartFlag()
    }

    var sharedModelContainer: ModelContainer = {
        let groupID = "group.Koveo.Vault"

        // Essai 1 : App Group (partagé avec la Share Extension)
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            let storeURL = groupURL.appendingPathComponent("vault.sqlite")

            let cloudKitEnabled = UserDefaults.standard.bool(forKey: SyncService.cloudKitEnabledKey)

            if cloudKitEnabled,
               let ck = try? ModelContainer(
                   for: Coupon.self,
                   configurations: ModelConfiguration(
                       url: storeURL,
                       cloudKitDatabase: .private(SyncService.cloudKitContainerID)
                   )
               ) {
                return ck
            }

            if let local = try? ModelContainer(
                for: Coupon.self,
                configurations: ModelConfiguration(url: storeURL)
            ) {
                return local
            }
        }

        // Essai 2 : stockage local standard (simulateur sans App Group configuré)
        if let standard = try? ModelContainer(for: Coupon.self) {
            return standard
        }

        // Dernier recours : en mémoire — ne devrait jamais échouer
        return try! ModelContainer(
            for: Coupon.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Racine de l'app

/// Couche fine au-dessus de MainTabView qui gère :
/// - La demande de permission notifications au premier lancement
/// - La replanification des notifications au retour en premier plan
/// - Le démarrage de StoreKit et la mise à jour du SyncService
struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var coupons: [Coupon]

    // Onboarding : montré uniquement au premier lancement
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "vault.onboarding.completed")

    // Permission notifications : uniquement après l'onboarding
    @State private var showNotifPermission: Bool = {
        let onboardingDone = UserDefaults.standard.bool(forKey: "vault.onboarding.completed")
        let notifNotPrompted = !UserDefaults.standard.bool(forKey: NotificationService.promptedKey)
        return onboardingDone && notifNotPrompted
    }()

    var body: some View {
        MainTabView()
            .task {
                SubscriptionService.shared.startListening()
                await SyncService.shared.refreshStatus(
                    isPremium: SubscriptionService.shared.subscription.isPremium
                )
            }
            .onChange(of: SubscriptionService.shared.subscription.isPremium) { _, isPremium in
                Task { await SyncService.shared.updateSyncState(isPremium: isPremium) }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await rescheduleNotifications() }
                }
            }
            // Onboarding en premier plan, avant tout le reste
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    showOnboarding = false
                    // Propose la permission notifications juste après l'onboarding
                    if !UserDefaults.standard.bool(forKey: NotificationService.promptedKey) {
                        Task {
                            try? await Task.sleep(for: .milliseconds(400))
                            showNotifPermission = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotifPermission) {
                NotificationPermissionSheet {
                    showNotifPermission = false
                }
            }
    }

    @MainActor
    private func rescheduleNotifications() async {
        let status = await NotificationService.shared.authorizationStatus()
        guard status == .authorized || status == .provisional else { return }
        let isPremium = SubscriptionService.shared.subscription.isPremium
        NotificationService.shared.rescheduleAll(coupons: coupons, isPremium: isPremium)
    }
}

// MARK: - Sheet d'onboarding notifications

struct NotificationPermissionSheet: View {
    let onDismiss: () -> Void
    @State private var isRequesting = false

    private let features: [(icon: String, text: String, color: Color)] = [
        ("clock.badge.exclamationmark.fill", "Rappel la veille de l'expiration",      .orange),
        ("bell.and.waves.left.and.right.fill", "Alertes J-7, J-3, J-1 en Premium",   .blue),
        ("hand.raised.fill",                   "Désactivables à tout moment dans iOS", .green),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle().fill(.orange.opacity(0.12)).frame(width: 140, height: 140)
                    Circle().fill(.orange.opacity(0.07)).frame(width: 110, height: 110)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(.orange)
                }
                .padding(.bottom, 32)

                VStack(spacing: 10) {
                    Text("Ne rate plus un bon !")
                        .font(.title2).fontWeight(.bold)
                    Text("Vault peut te prévenir avant que tes bons expirent, pour ne jamais en perdre un.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 28)
                }
                .padding(.bottom, 36)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(features, id: \.text) { feature in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(feature.color.opacity(0.12))
                                    .frame(width: 38, height: 38)
                                Image(systemName: feature.icon)
                                    .font(.callout).foregroundStyle(feature.color)
                            }
                            Text(feature.text).font(.subheadline).fontWeight(.medium)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        Task { await requestPermission() }
                    } label: {
                        Group {
                            if isRequesting {
                                ProgressView().tint(.white)
                            } else {
                                Label("Activer les notifications", systemImage: "bell.fill")
                                    .font(.body).fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isRequesting)

                    Button("Peut-être plus tard") {
                        UserDefaults.standard.set(true, forKey: NotificationService.promptedKey)
                        onDismiss()
                    }
                    .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24).padding(.bottom, 36)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        UserDefaults.standard.set(true, forKey: NotificationService.promptedKey)
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
    }

    @MainActor
    private func requestPermission() async {
        isRequesting = true
        await NotificationService.shared.requestAuthorization()
        UserDefaults.standard.set(true, forKey: NotificationService.promptedKey)
        isRequesting = false
        onDismiss()
    }
}
