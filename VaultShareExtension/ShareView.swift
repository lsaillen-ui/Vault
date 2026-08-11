import SwiftUI
import SwiftData

// MARK: - Modèle de contenu partagé

struct ShareContent {
    var sourceURL: URL?
    var sourceText: String?

    // Texte affiché dans l'aperçu
    var displayText: String {
        sourceURL?.absoluteString ?? sourceText ?? ""
    }

    // Marque suggérée depuis le hostname de l'URL
    var suggestedBrand: String {
        guard let host = sourceURL?.host else { return "" }
        let parts = host.split(separator: ".").map(String.init)
        guard parts.count >= 2 else { return host }
        let domain = parts[parts.count - 2]
        return domain.prefix(1).uppercased() + domain.dropFirst()
    }

    // Code suggéré depuis les query params de l'URL
    var suggestedCode: String {
        guard let url = sourceURL,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return "" }
        let codeKeys = ["code", "promo", "coupon", "voucher", "ref", "discount"]
        return components.queryItems?
            .first { codeKeys.contains($0.name.lowercased()) }?
            .value?
            .uppercased() ?? ""
    }
}

// MARK: - Vue principale

struct ShareView: View {
    let content: ShareContent
    let onSave: () -> Void
    let onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var brand: String
    @State private var value: String = ""
    @State private var code: String
    @State private var category: Category = .autres
    @State private var phase: Phase = .form

    private enum Phase { case form, saving, saved }

    init(content: ShareContent, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.content = content
        self.onSave  = onSave
        self.onCancel = onCancel
        _brand = State(initialValue: content.suggestedBrand)
        _code  = State(initialValue: content.suggestedCode)
    }

    private var isValid: Bool {
        !brand.trimmingCharacters(in: .whitespaces).isEmpty &&
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .form:   formView
                case .saving: savingView
                case .saved:  savedView
                }
            }
            .navigationTitle("Sauver dans Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { onCancel() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sauver") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || phase != .form)
                }
            }
        }
    }

    // MARK: - Formulaire

    private var formView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Aperçu de ce qui est partagé
                if !content.displayText.isEmpty {
                    previewCard
                }

                // Champs
                VStack(spacing: 16) {
                    formCard("Marque / Magasin") {
                        TextField("ex : McDonald's, Zalando…", text: $brand)
                            .font(.body)
                            .submitLabel(.next)
                    }

                    formCard("Valeur du bon") {
                        TextField("ex : −20%, CHF 25, Livraison offerte…", text: $value)
                            .font(.body)
                            .submitLabel(.next)
                    }

                    formCard("Code promo") {
                        TextField("Code ou numéro (optionnel)", text: $code)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }

                    categoryPicker
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Aperçu du contenu partagé

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Contenu partagé", systemImage: "square.and.arrow.up")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                // Icône type (URL vs texte)
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: content.sourceURL != nil ? "safari.fill" : "text.quote")
                        .font(.callout)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let host = content.sourceURL?.host {
                        Text(host)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                    Text(content.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 16)
    }

    // MARK: Picker catégorie

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Catégorie")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Category.allCases) { cat in
                        Button {
                            withAnimation(.spring(duration: 0.2)) { category = cat }
                        } label: {
                            VStack(spacing: 5) {
                                ZStack {
                                    Circle()
                                        .fill(category == cat ? cat.color : cat.color.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: cat.icon)
                                        .font(.callout)
                                        .foregroundStyle(category == cat ? .white : cat.color)
                                }
                                Text(cat.displayName)
                                    .font(.caption2)
                                    .fontWeight(category == cat ? .semibold : .regular)
                                    .foregroundStyle(category == cat ? cat.color : .secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 52)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: Helper card

    @ViewBuilder
    private func formCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, 4)

            content()
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Sauvegarde en cours

    private var savingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.blue)
            Text("Sauvegarde en cours…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Confirmation succès

    private var savedView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.green.opacity(0.12))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(.green.opacity(0.07))
                    .frame(width: 108, height: 108)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }

            VStack(spacing: 8) {
                Text("Bon sauvegardé !")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(brand) — \(value)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action

    private func save() {
        phase = .saving

        let coupon = Coupon(
            brand: brand.trimmingCharacters(in: .whitespaces),
            value: value.trimmingCharacters(in: .whitespaces),
            code: code.trimmingCharacters(in: .whitespaces),
            category: category,
            notes: content.sourceURL.map { "Source : \($0.absoluteString)" },
            source: .shareExtension
        )
        modelContext.insert(coupon)

        withAnimation(.spring(duration: 0.4)) { phase = .saved }

        // Ferme l'extension après un court délai pour laisser voir l'animation
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            onSave()
        }
    }
}
