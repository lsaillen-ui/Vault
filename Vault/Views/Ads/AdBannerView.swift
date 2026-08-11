import SwiftUI

// MARK: - Stub compilable (SDK non installé)
// AdBannerContainer est visible par HomeView même sans le package GoogleMobileAds.
// Quand le SDK sera installé, supprimer ce bloc et décommenter l'implémentation complète ci-dessous.

struct AdBannerContainer: View {
    var body: some View {
        // Espace réservé : montre rien tant que le SDK n'est pas configuré.
        // Hauteur 0 → pas d'impact sur la mise en page.
        Color.clear.frame(height: 0)
    }
}

// MARK: - Implémentation complète
// Prérequis : ajouter le package SPM https://github.com/googleads/swift-package-manager-google-mobile-ads
// Puis supprimer le stub ci-dessus et décommenter tout ce bloc.

/*
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = AdMobConfig.bannerID
        banner.rootViewController = context.coordinator.rootViewController
        banner.delegate = context.coordinator
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    final class Coordinator: NSObject, GADBannerViewDelegate {
        var rootViewController: UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController
        }
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("[AdMob] Échec: \(error.localizedDescription)")
        }
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("[AdMob] Bannière chargée")
        }
    }
}

struct AdBannerContainer: View {
    var body: some View {
        AdBannerView()
            .frame(width: UIScreen.main.bounds.width, height: 50)
            .background(Color(.systemBackground))
    }
}
*/
