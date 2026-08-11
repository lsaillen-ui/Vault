import UIKit
import SwiftUI
import SwiftData

/// Point d'entrée de la Share Extension.
/// Extrait le contenu partagé (URL, texte, image), crée le container
/// SwiftData sur le container App Group partagé, puis présente ShareView.
@objc(ShareViewController)
final class ShareViewController: UIViewController {

    private static let appGroupID = "group.Koveo.Vault"
    private static let storeFilename = "vault.sqlite"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground

        Task { @MainActor in
            let content = await extractContent()
            mount(content: content)
        }
    }

    // MARK: - Extraction du contenu partagé

    private func extractContent() async -> ShareContent {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else {
            return ShareContent()
        }
        var result = ShareContent()

        for provider in item.attachments ?? [] {
            // URL
            if provider.hasItemConformingToTypeIdentifier("public.url"), result.sourceURL == nil {
                let raw = try? await provider.loadItem(forTypeIdentifier: "public.url", options: nil)
                result.sourceURL = raw as? URL
            }
            // Texte brut
            if provider.hasItemConformingToTypeIdentifier("public.plain-text"), result.sourceText == nil {
                let raw = try? await provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil)
                result.sourceText = raw as? String
            }
        }
        return result
    }

    // MARK: - Montage de l'UI SwiftUI

    private func mount(content: ShareContent) {
        // Container SwiftData pointant sur le même store partagé que l'app principale
        let container = makeSharedContainer()

        let shareView = ShareView(
            content: content,
            onSave: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: ExtensionError.userCancelled)
            }
        )
        .modelContainer(container)

        let host = UIHostingController(rootView: shareView)
        host.view.backgroundColor = .clear

        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    // MARK: - Container SwiftData partagé

    private func makeSharedContainer() -> ModelContainer {
        let schema = Schema([Coupon.self])

        // URL du store dans l'App Group (partagé avec l'app principale)
        if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) {
            let storeURL = groupURL.appendingPathComponent(Self.storeFilename)
            if let container = try? ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, url: storeURL)
            ) {
                return container
            }
        }

        // Fallback en mémoire si App Group indisponible (simulateur sans entitlements)
        return try! ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }

    enum ExtensionError: Error {
        case userCancelled
    }
}
