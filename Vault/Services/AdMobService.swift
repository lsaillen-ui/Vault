import Foundation

// MARK: - Stub compilable (SDK non installé)
// AdMobService existe pour que VaultApp.swift compile.
// Quand le SDK sera installé, supprimer ce stub et décommenter l'implémentation complète ci-dessous.

enum AdMobConfig {
    #if DEBUG
    static let appID    = "ca-app-pub-3940256099942544~1458002511"
    static let bannerID = "ca-app-pub-3940256099942544/2934735716"
    #else
    static let appID    = "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"  // TODO: console AdMob
    static let bannerID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"  // TODO: console AdMob
    #endif
}

@MainActor
final class AdMobService {
    static let shared = AdMobService()
    private init() {}
    func configure() {
        // No-op tant que le SDK Google Mobile Ads n'est pas installé.
        print("[AdMob] SDK non configuré — ajouter le package SPM pour activer la publicité.")
    }
}

// MARK: - Implémentation complète
// Prérequis : package SPM https://github.com/googleads/swift-package-manager-google-mobile-ads
// Puis supprimer le stub ci-dessus et décommenter ce bloc.

/*
import GoogleMobileAds

@MainActor
final class AdMobService {
    static let shared = AdMobService()
    private init() {}
    func configure() {
        MobileAds.shared.start { status in
            print("[AdMob] SDK initialisé — \(status.adapterStatusesByClassName.count) adapter(s)")
        }
    }
}
*/
